use serde::Deserialize;
use std::process::Command;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Peer {
    pub host: String,
    pub address: String,
    pub port: u16,
    pub online: bool,
}

/// Replaces tailnet discovery, which gives every peer the same port and so
/// cannot address two daemons on one machine.
pub fn from_override(spec: &str, fallback_port: u16) -> Vec<Peer> {
    spec.split(',')
        .filter_map(|entry| {
            let entry = entry.trim();
            if entry.is_empty() {
                return None;
            }
            let (host, endpoint) = entry.split_once('=')?;
            let (address, port) = match endpoint.rsplit_once(':') {
                Some((address, port)) => (address, port.parse().ok()?),
                None => (endpoint, fallback_port),
            };
            Some(Peer {
                host: host.trim().to_string(),
                address: address.trim().to_string(),
                port,
                online: true,
            })
        })
        .collect()
}

#[derive(Deserialize)]
struct Status {
    #[serde(rename = "Self")]
    self_node: Option<Node>,
    #[serde(rename = "Peer")]
    peer: Option<std::collections::HashMap<String, Node>>,
}

#[derive(Deserialize)]
struct Node {
    #[serde(rename = "HostName")]
    host_name: String,
    #[serde(rename = "TailscaleIPs")]
    tailscale_ips: Option<Vec<String>>,
    #[serde(rename = "Online")]
    online: Option<bool>,
    #[serde(rename = "OS")]
    os: Option<String>,
}

/// Reads the in-memory netmap over a unix socket, making no network request.
pub fn discover(tailscale_bin: &str, port: u16) -> Option<(String, Vec<Peer>)> {
    let output = Command::new(tailscale_bin).args(["status", "--json"]).output().ok()?;
    if !output.status.success() {
        return None;
    }
    let status: Status = serde_json::from_slice(&output.stdout).ok()?;

    let self_address = status
        .self_node
        .as_ref()
        .and_then(|node| node.tailscale_ips.as_ref())
        .and_then(|ips| ips.iter().find(|ip| !ip.contains(':')))
        .cloned()
        .unwrap_or_default();

    let mut peers: Vec<Peer> = status
        .peer
        .unwrap_or_default()
        .into_values()
        // Phones and tablets run no daemon, so they never answer a sync request.
        .filter(|node| node.os.as_deref() != Some("android") && node.os.as_deref() != Some("iOS"))
        .filter_map(|node| {
            let address = node.tailscale_ips?.into_iter().find(|ip| !ip.contains(':'))?;
            Some(Peer { host: node.host_name, address, port, online: node.online.unwrap_or(false) })
        })
        .collect();
    peers.sort_by(|a, b| a.host.cmp(&b.host));

    Some((self_address, peers))
}

pub fn hostname() -> String {
    std::fs::read_to_string("/proc/sys/kernel/hostname")
        .ok()
        .map(|name| name.trim().to_string())
        .filter(|name| !name.is_empty())
        .unwrap_or_else(|| "unknown".to_string())
}
