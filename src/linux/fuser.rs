//! A basic functionality replacing the use of `fuser` command on linux
use std::fs;

/// Simply returns true is a file is accessed any process.
pub(crate) fn fusers_is_open(file_path: &str) -> bool {
    if let Ok(entries) = fs::read_dir("/proc") {
        for entry in entries.flatten() {
            let meta = entry.metadata();
            if meta.is_ok() && meta.unwrap().is_dir() {
                if let Ok(ref pid) = entry.file_name().into_string().unwrap().parse::<i32>() {
                    if let Ok(fds) = fs::read_dir(format!("/proc/{}/fd", pid)) {
                        for fd in fds.flatten() {
                            if let Ok(ref opened_file) = fs::read_link(fd.path()) {
                                if let Some(open_file_name) = opened_file.to_str() {
                                    if open_file_name == file_path {
                                        // Instant return if we find file is open be it any process
                                        return true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    false
}
