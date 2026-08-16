//! Peer-to-peer sync daemon for one shared text buffer across a tailnet.
//! Each device runs one; the Noctalia plugin talks to it over localhost.

mod doc;
mod http;
mod peers;

use doc::{Doc, Merge, Store};
use peers::Peer;
use serde::{Deserialize, Serialize};
use std::net::{IpAddr, Ipv4Addr, SocketAddr, TcpListener, TcpStream};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::mpsc::{self, Receiver, Sender};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

const DEFAULT_PORT: u16 = 8471;
const PEER_REFRESH: Duration = Duration::from_secs(30);
const PEER_TIMEOUT: Duration = Duration::from_secs(4);
const HEARTBEAT: Duration = Duration::from_secs(20);

struct Shared {
    store: Mutex<Store>,
    subscribers: Mutex<Vec<(u64, Sender<String>)>>,
    next_subscriber: AtomicU64,
    peers: Mutex<Vec<Peer>>,
    tailscale_bin: String,
    port: u16,
}

#[derive(Serialize)]
struct Health<'a> {
    origin: &'a str,
    lamport: u64,
    port: u16,
    peers: Vec<PeerView>,
}

#[derive(Serialize)]
struct PeerView {
    host: String,
    address: String,
    online: bool,
}

#[derive(Deserialize)]
struct EditRequest {
    text: String,
}

#[derive(Deserialize)]
struct RestoreRequest {
    index: usize,
}

fn main() {
    let port: u16 = std::env::var("TAILDROP_SYNCD_PORT")
        .ok()
        .and_then(|value| value.parse().ok())
        .unwrap_or(DEFAULT_PORT);
    let origin = std::env::var("TAILDROP_SYNCD_ORIGIN").unwrap_or_else(|_| peers::hostname());
    let tailscale_bin = std::env::var("TAILDROP_SYNCD_TAILSCALE").unwrap_or_else(|_| "tailscale".to_string());
    let dir = state_dir(&origin, port);

    let store = match Store::load(dir.clone(), origin.clone()) {
        Ok(store) => store,
        Err(err) => {
            eprintln!("taildrop-syncd: cannot open {}: {err}", dir.display());
            std::process::exit(1);
        }
    };

    let shared = Arc::new(Shared {
        store: Mutex::new(store),
        subscribers: Mutex::new(Vec::new()),
        next_subscriber: AtomicU64::new(0),
        peers: Mutex::new(Vec::new()),
        tailscale_bin,
        port,
    });

    // Binding every interface would be wrong anywhere but here: the host
    // firewall trusts tailscale0 alone and default-denies the rest, so the
    // tailnet and loopback are the only ways in.
    let bind = SocketAddr::new(IpAddr::V4(Ipv4Addr::UNSPECIFIED), port);
    let listener = match TcpListener::bind(bind) {
        Ok(listener) => listener,
        Err(err) => {
            eprintln!("taildrop-syncd: cannot bind {bind}: {err}");
            std::process::exit(1);
        }
    };
    eprintln!("taildrop-syncd: origin {origin} listening on {bind}, state in {}", dir.display());

    {
        let shared = Arc::clone(&shared);
        thread::spawn(move || peer_loop(shared));
    }

    for incoming in listener.incoming() {
        let Ok(stream) = incoming else { continue };
        let shared = Arc::clone(&shared);
        thread::spawn(move || handle(shared, stream));
    }
}

fn state_dir(origin: &str, port: u16) -> std::path::PathBuf {
    if let Ok(explicit) = std::env::var("TAILDROP_SYNCD_STATE") {
        return std::path::PathBuf::from(explicit);
    }
    let base = std::env::var("XDG_STATE_HOME")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|_| {
            std::path::PathBuf::from(std::env::var("HOME").unwrap_or_else(|_| "/tmp".into())).join(".local/state")
        });
    base.join("taildrop-syncd").join(format!("{origin}-{port}"))
}

fn handle(shared: Arc<Shared>, mut stream: TcpStream) {
    let _ = stream.set_read_timeout(Some(Duration::from_secs(30)));
    let local = stream.peer_addr().map(|addr| addr.ip().is_loopback()).unwrap_or(false);

    let Some(request) = http::read_request(&stream) else {
        http::respond_text(&mut stream, 400, "malformed request");
        return;
    };
    let path = request.path.split('?').next().unwrap_or("/");

    match (request.method.as_str(), path) {
        ("GET", "/doc") => {
            let body = serde_json::to_vec(shared.store.lock().unwrap().doc()).unwrap_or_default();
            http::respond_json(&mut stream, 200, &body);
        }

        ("POST", "/sync") => match serde_json::from_slice::<Doc>(&request.body) {
            Ok(incoming) => {
                let (accepted, current) = {
                    let mut store = shared.store.lock().unwrap();
                    (store.merge(incoming) == Merge::Accepted, store.doc().clone())
                };
                if accepted {
                    broadcast(&shared, &current);
                }
                let body = serde_json::to_vec(&current).unwrap_or_default();
                http::respond_json(&mut stream, 200, &body);
            }
            Err(err) => http::respond_text(&mut stream, 400, &format!("bad revision: {err}")),
        },

        ("GET", "/health") => {
            let store = shared.store.lock().unwrap();
            let peers = shared.peers.lock().unwrap();
            let health = Health {
                origin: store.origin(),
                lamport: store.doc().lamport,
                port: shared.port,
                peers: peers
                    .iter()
                    .map(|p| PeerView { host: p.host.clone(), address: p.address.clone(), online: p.online })
                    .collect(),
            };
            let body = serde_json::to_vec(&health).unwrap_or_default();
            http::respond_json(&mut stream, 200, &body);
        }

        // Everything below mutates or exposes local state, so it stays on loopback.
        _ if !local => http::respond_text(&mut stream, 403, "loopback only"),

        ("POST", "/doc") => match serde_json::from_slice::<EditRequest>(&request.body) {
            Ok(edit) => {
                let current = shared.store.lock().unwrap().edit(edit.text);
                broadcast(&shared, &current);
                fan_out(Arc::clone(&shared), current.clone());
                let body = serde_json::to_vec(&current).unwrap_or_default();
                http::respond_json(&mut stream, 200, &body);
            }
            Err(err) => http::respond_text(&mut stream, 400, &format!("bad edit: {err}")),
        },

        ("GET", "/history") => {
            let body = serde_json::to_vec(shared.store.lock().unwrap().history()).unwrap_or_default();
            http::respond_json(&mut stream, 200, &body);
        }

        ("POST", "/restore") => match serde_json::from_slice::<RestoreRequest>(&request.body) {
            Ok(restore) => {
                let restored = {
                    let mut store = shared.store.lock().unwrap();
                    match store.history().get(restore.index).map(|entry| entry.text.clone()) {
                        Some(text) => Some(store.edit(text)),
                        None => None,
                    }
                };
                match restored {
                    Some(current) => {
                        broadcast(&shared, &current);
                        fan_out(Arc::clone(&shared), current.clone());
                        let body = serde_json::to_vec(&current).unwrap_or_default();
                        http::respond_json(&mut stream, 200, &body);
                    }
                    None => http::respond_text(&mut stream, 404, "no such revision"),
                }
            }
            Err(err) => http::respond_text(&mut stream, 400, &format!("bad restore: {err}")),
        },

        ("GET", "/events") => serve_events(shared, stream),

        _ => http::respond_text(&mut stream, 404, "no such endpoint"),
    }
}

/// Holds the connection open and writes a frame per accepted revision. The
/// heartbeat comment is what makes a dead peer detectable without polling.
fn serve_events(shared: Arc<Shared>, mut stream: TcpStream) {
    let _ = stream.set_read_timeout(None);
    if !http::begin_event_stream(&mut stream) {
        return;
    }

    let (sender, receiver): (Sender<String>, Receiver<String>) = mpsc::channel();
    let id = shared.next_subscriber.fetch_add(1, Ordering::Relaxed);
    shared.subscribers.lock().unwrap().push((id, sender));

    let current = serde_json::to_string(shared.store.lock().unwrap().doc()).unwrap_or_default();
    if !http::send_event(&mut stream, &current) {
        drop_subscriber(&shared, id);
        return;
    }

    loop {
        match receiver.recv_timeout(HEARTBEAT) {
            Ok(payload) => {
                if !http::send_event(&mut stream, &payload) {
                    break;
                }
            }
            Err(mpsc::RecvTimeoutError::Timeout) => {
                if !http::send_comment(&mut stream, "keepalive") {
                    break;
                }
            }
            Err(mpsc::RecvTimeoutError::Disconnected) => break,
        }
    }
    drop_subscriber(&shared, id);
}

fn drop_subscriber(shared: &Arc<Shared>, id: u64) {
    shared.subscribers.lock().unwrap().retain(|(existing, _)| *existing != id);
}

fn broadcast(shared: &Arc<Shared>, current: &Doc) {
    let Ok(payload) = serde_json::to_string(current) else { return };
    shared.subscribers.lock().unwrap().retain(|(_, sender)| sender.send(payload.clone()).is_ok());
}

/// Pushes a revision to every peer believed online. Failures are silent by
/// design: an unreachable peer catches up through the pull in peer_loop.
fn fan_out(shared: Arc<Shared>, current: Doc) {
    thread::spawn(move || {
        let targets: Vec<Peer> = shared.peers.lock().unwrap().iter().filter(|p| p.online).cloned().collect();
        let Ok(body) = serde_json::to_vec(&current) else { return };
        for peer in targets {
            let shared = Arc::clone(&shared);
            let body = body.clone();
            thread::spawn(move || {
                if let Some(response) = http::fetch(&peer.address, peer.port, "POST", "/sync", Some(&body), PEER_TIMEOUT) {
                    absorb(&shared, &response);
                }
            });
        }
    });
}

/// Merges whatever a peer answered with, so a device that pushed a losing
/// revision learns the winner in the same round trip.
fn absorb(shared: &Arc<Shared>, response: &[u8]) {
    let Ok(theirs) = serde_json::from_slice::<Doc>(response) else { return };
    let (accepted, current) = {
        let mut store = shared.store.lock().unwrap();
        (store.merge(theirs) == Merge::Accepted, store.doc().clone())
    };
    if accepted {
        broadcast(shared, &current);
    }
}

/// Refreshes the peer list and pulls from any peer that just came back, which
/// is what closes the gap after this device or that one was offline.
fn peer_loop(shared: Arc<Shared>) {
    let mut known: Vec<Peer> = Vec::new();
    let pinned = std::env::var("TAILDROP_SYNCD_PEERS").ok();
    loop {
        let found = match &pinned {
            Some(spec) => Some((String::new(), peers::from_override(spec, shared.port))),
            None => peers::discover(&shared.tailscale_bin, shared.port),
        };
        if let Some((_, discovered)) = found {
            let reappeared: Vec<Peer> = discovered
                .iter()
                .filter(|peer| peer.online)
                .filter(|peer| !known.iter().any(|old| old.host == peer.host && old.online))
                .cloned()
                .collect();

            *shared.peers.lock().unwrap() = discovered.clone();
            known = discovered;

            for peer in reappeared {
                let shared = Arc::clone(&shared);
                thread::spawn(move || {
                    if let Some(response) = http::fetch(&peer.address, peer.port, "GET", "/doc", None, PEER_TIMEOUT) {
                        absorb(&shared, &response);
                        let current = shared.store.lock().unwrap().doc().clone();
                        let Ok(body) = serde_json::to_vec(&current) else { return };
                        if let Some(reply) = http::fetch(&peer.address, peer.port, "POST", "/sync", Some(&body), PEER_TIMEOUT) {
                            absorb(&shared, &reply);
                        }
                    }
                });
            }
        }
        thread::sleep(PEER_REFRESH);
    }
}
