use std::collections::HashMap;
use std::io::{BufRead, BufReader, Read, Write};
use std::net::TcpStream;
use std::time::Duration;

const MAX_BODY: usize = 4 * 1024 * 1024;

pub struct Request {
    pub method: String,
    pub path: String,
    pub body: Vec<u8>,
}

pub fn read_request(stream: &TcpStream) -> Option<Request> {
    let mut reader = BufReader::new(stream.try_clone().ok()?);

    let mut line = String::new();
    reader.read_line(&mut line).ok()?;
    let mut parts = line.split_whitespace();
    let method = parts.next()?.to_string();
    let path = parts.next()?.to_string();

    let mut headers = HashMap::new();
    loop {
        let mut header = String::new();
        if reader.read_line(&mut header).ok()? == 0 {
            return None;
        }
        let header = header.trim_end();
        if header.is_empty() {
            break;
        }
        if let Some((name, value)) = header.split_once(':') {
            headers.insert(name.trim().to_ascii_lowercase(), value.trim().to_string());
        }
    }

    let length: usize = headers.get("content-length").and_then(|v| v.parse().ok()).unwrap_or(0);
    if length > MAX_BODY {
        return None;
    }
    let mut body = vec![0u8; length];
    reader.read_exact(&mut body).ok()?;

    Some(Request { method, path, body })
}

pub fn respond(stream: &mut TcpStream, status: u16, content_type: &str, body: &[u8]) {
    let head = format!(
        "HTTP/1.1 {status} {}\r\nContent-Type: {content_type}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
        reason(status),
        body.len()
    );
    let _ = stream.write_all(head.as_bytes());
    let _ = stream.write_all(body);
    let _ = stream.flush();
}

pub fn respond_json(stream: &mut TcpStream, status: u16, body: &[u8]) {
    respond(stream, status, "application/json", body);
}

pub fn respond_text(stream: &mut TcpStream, status: u16, message: &str) {
    respond(stream, status, "text/plain; charset=utf-8", message.as_bytes());
}

/// Opens an event stream. `no-cache` and the explicit unbuffered hint keep any
/// reverse proxy from holding events back until the connection closes.
pub fn begin_event_stream(stream: &mut TcpStream) -> bool {
    let head = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\nX-Accel-Buffering: no\r\nConnection: keep-alive\r\n\r\n";
    stream.write_all(head.as_bytes()).and_then(|_| stream.flush()).is_ok()
}

pub fn send_event(stream: &mut TcpStream, data: &str) -> bool {
    let frame = format!("data: {data}\n\n");
    stream.write_all(frame.as_bytes()).and_then(|_| stream.flush()).is_ok()
}

pub fn send_comment(stream: &mut TcpStream, note: &str) -> bool {
    let frame = format!(": {note}\n\n");
    stream.write_all(frame.as_bytes()).and_then(|_| stream.flush()).is_ok()
}

/// Blocking plain-HTTP client. Peers are reached over the tailnet, which is
/// already encrypted, so this speaks no TLS and pulls in no TLS stack.
pub fn fetch(host: &str, port: u16, method: &str, path: &str, body: Option<&[u8]>, timeout: Duration) -> Option<Vec<u8>> {
    let address = format!("{host}:{port}");
    let addresses: Vec<_> = std::net::ToSocketAddrs::to_socket_addrs(&address).ok()?.collect();
    let mut stream = addresses
        .iter()
        .find_map(|candidate| TcpStream::connect_timeout(candidate, timeout).ok())?;
    stream.set_read_timeout(Some(timeout)).ok()?;
    stream.set_write_timeout(Some(timeout)).ok()?;

    let payload = body.unwrap_or(&[]);
    let head = format!(
        "{method} {path} HTTP/1.1\r\nHost: {host}\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
        payload.len()
    );
    stream.write_all(head.as_bytes()).ok()?;
    stream.write_all(payload).ok()?;
    stream.flush().ok()?;

    let mut response = Vec::new();
    stream.read_to_end(&mut response).ok()?;
    let split = response.windows(4).position(|w| w == b"\r\n\r\n")?;
    let status_ok = response.starts_with(b"HTTP/1.1 200") || response.starts_with(b"HTTP/1.0 200");
    status_ok.then(|| response[split + 4..].to_vec())
}

fn reason(status: u16) -> &'static str {
    match status {
        200 => "OK",
        400 => "Bad Request",
        403 => "Forbidden",
        404 => "Not Found",
        _ => "Error",
    }
}
