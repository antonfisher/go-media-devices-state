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

/// Get the PIDs of all the process that have openend the file.
pub(crate) fn fusers(file_path: &str) -> Vec<i32> {
    let mut pids = Vec::new();
    if let Ok(entries) = fs::read_dir("/proc") {
        for entry in entries.flatten() {
            let meta = entry.metadata();
            if meta.is_ok() && meta.unwrap().is_dir() {
                if let Ok(ref pid) = entry.file_name().into_string().unwrap().parse::<i32>() {
                    if let Ok(fds) = fs::read_dir(format!("/proc/{}/fd", pid)) {
                        // Using named for loop so that it can be breaked at once if we find fd
                        // realted to file_path.
                        // This loop lists out all the fds opened by a PID
                        'fids_per_pid: for fd in fds.flatten() {
                            if let Ok(ref opened_file) = fs::read_link(fd.path()) {
                                if let Some(open_file_name) = opened_file.to_str() {
                                    if open_file_name == file_path {
                                        pids.push(*pid);
                                        break 'fids_per_pid;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    pids
}

/// Get name of the process from it's pid
pub(crate) fn pid_name(pid: i32) -> Option<String> {
    let proc_path = format!("/proc/{}", pid);
    let status_path = std::path::Path::new(&proc_path).join("status");

    if let Ok(file) = std::fs::File::open(status_path) {
        let reader = std::io::BufReader::new(file);
        use std::io::BufRead;
        for line in reader.lines().flatten() {
            if line.starts_with("Name:") {
                let mut parts = line.split_whitespace();
                if let Some(name) = parts.nth(1) {
                    return Some(name.to_string());
                }
            }
        }
    }
    None
}

// Get names of all the process that have camera device opened
#[test]
fn process_name_using_camera() {
    let pnames: Vec<String> = fusers("/dev/video0")
        .iter()
        .map(|&pid| pid_name(pid).unwrap())
        .collect();
    println!("{:#?}", pnames);
}
