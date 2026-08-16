use serde::{Deserialize, Serialize};
use std::fs;
use std::io;
use std::path::{Path, PathBuf};

pub const HISTORY_LIMIT: usize = 10;

/// `lamport` paired with `origin` is a total order every device computes
/// identically, so merges need no coordinator and no agreed wall clock.
#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct Doc {
    pub text: String,
    pub lamport: u64,
    pub origin: String,
}

impl Doc {
    pub fn empty(origin: &str) -> Self {
        Doc { text: String::new(), lamport: 0, origin: origin.to_string() }
    }

    fn rank(&self) -> (u64, &str) {
        (self.lamport, self.origin.as_str())
    }

    pub fn supersedes(&self, other: &Doc) -> bool {
        self.rank() > other.rank()
    }
}

#[derive(Debug, PartialEq, Eq)]
pub enum Merge {
    Accepted,
    Ignored,
}

pub struct Store {
    origin: String,
    doc: Doc,
    history: Vec<Doc>,
    dir: PathBuf,
}

impl Store {
    pub fn load(dir: PathBuf, origin: String) -> io::Result<Self> {
        fs::create_dir_all(&dir)?;
        let doc = read_json(&dir.join("doc.json")).unwrap_or_else(|| Doc::empty(&origin));
        let history = read_json(&dir.join("history.json")).unwrap_or_default();
        Ok(Store { origin, doc, history, dir })
    }

    pub fn origin(&self) -> &str {
        &self.origin
    }

    pub fn doc(&self) -> &Doc {
        &self.doc
    }

    pub fn history(&self) -> &[Doc] {
        &self.history
    }

    /// A local edit always wins against everything seen so far.
    pub fn edit(&mut self, text: String) -> Doc {
        let next = Doc { text, lamport: self.doc.lamport + 1, origin: self.origin.clone() };
        self.replace(next);
        self.doc.clone()
    }

    pub fn merge(&mut self, incoming: Doc) -> Merge {
        if !incoming.supersedes(&self.doc) {
            return Merge::Ignored;
        }
        self.replace(incoming);
        Merge::Accepted
    }

    fn replace(&mut self, next: Doc) {
        let previous = std::mem::replace(&mut self.doc, next);
        if !previous.text.is_empty() && previous.text != self.doc.text {
            self.history.insert(0, previous);
            self.history.truncate(HISTORY_LIMIT);
        }
        self.persist();
    }

    fn persist(&self) {
        write_json(&self.dir.join("doc.json"), &self.doc);
        write_json(&self.dir.join("history.json"), &self.history);
    }
}

fn read_json<T: for<'de> Deserialize<'de>>(path: &Path) -> Option<T> {
    serde_json::from_slice(&fs::read(path).ok()?).ok()
}

/// Writes through a temp file so a crash mid-write cannot leave a truncated
/// document behind.
fn write_json<T: Serialize>(path: &Path, value: &T) {
    let Ok(bytes) = serde_json::to_vec(value) else { return };
    let temp = path.with_extension("tmp");
    if fs::write(&temp, &bytes).is_ok() {
        let _ = fs::rename(&temp, path);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn doc(text: &str, lamport: u64, origin: &str) -> Doc {
        Doc { text: text.to_string(), lamport, origin: origin.to_string() }
    }

    fn store(origin: &str) -> Store {
        let dir = std::env::temp_dir().join(format!("taildrop-syncd-test-{origin}-{:?}", std::time::SystemTime::now()));
        Store::load(dir, origin.to_string()).unwrap()
    }

    #[test]
    fn local_edit_outranks_everything_seen() {
        let mut s = store("karsa");
        s.merge(doc("from samar", 7, "samar"));
        assert_eq!(s.edit("mine".into()).lamport, 8);
    }

    #[test]
    fn higher_lamport_wins() {
        let mut s = store("karsa");
        s.edit("first".into());
        assert_eq!(s.merge(doc("newer", 9, "samar")), Merge::Accepted);
        assert_eq!(s.doc().text, "newer");
    }

    #[test]
    fn a_stale_revision_is_ignored() {
        let mut s = store("karsa");
        s.edit("a".into());
        s.edit("b".into());
        assert_eq!(s.merge(doc("stale", 1, "samar")), Merge::Ignored);
        assert_eq!(s.doc().text, "b");
        assert_eq!(s.doc().lamport, 2);
    }

    #[test]
    fn losing_a_tie_still_leaves_the_next_local_edit_on_top() {
        let mut s = store("aaa");
        s.edit("mine".into());
        s.merge(doc("theirs", 1, "zzz"));
        let next = s.edit("mine again".into());
        assert!(next.supersedes(&doc("theirs", 1, "zzz")));
    }

    #[test]
    fn concurrent_edits_converge_on_both_sides() {
        let (mut a, mut b) = (store("aaa"), store("zzz"));
        let from_a = a.edit("written on aaa".into());
        let from_b = b.edit("written on zzz".into());
        a.merge(from_b.clone());
        b.merge(from_a.clone());
        assert_eq!(a.doc().text, b.doc().text);
        assert_eq!(a.doc().text, "written on zzz");
    }

    #[test]
    fn a_losing_revision_stays_recoverable() {
        let mut s = store("karsa");
        s.edit("worth keeping".into());
        s.merge(doc("clobber", 5, "samar"));
        assert_eq!(s.history()[0].text, "worth keeping");
    }

    #[test]
    fn history_is_bounded() {
        let mut s = store("karsa");
        for i in 0..HISTORY_LIMIT + 5 {
            s.edit(format!("revision {i}"));
        }
        assert_eq!(s.history().len(), HISTORY_LIMIT);
    }

    #[test]
    fn merging_the_same_revision_twice_is_a_no_op() {
        let mut s = store("karsa");
        let incoming = doc("once", 3, "samar");
        assert_eq!(s.merge(incoming.clone()), Merge::Accepted);
        assert_eq!(s.merge(incoming), Merge::Ignored);
        assert_eq!(s.history().len(), 0);
    }
}
