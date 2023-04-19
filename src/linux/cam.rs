use crate::linux::fuser::{fusers, pid_name};

/// List out all camera sources that can provide outside view
/// This may be a web cam, or HDMI port that support video input even though it doesn't have any
/// camera
pub fn get_cam_devices() -> Vec<String> {
    let paths = std::fs::read_dir("/dev");
    if paths.is_err() {
        eprintln!(
            "Devices are not found on this machine, Maybe you're running in chroot environment"
        );
        return vec![];
    }
    let mut cam_devices = Vec::new();
    let paths = paths.unwrap();
    for path in paths.flatten() {
        let path_str = path.path().display().to_string();
        if path_str.contains("video") {
            cam_devices.push(path_str);
        }
    }
    cam_devices
}

/// Accumulates all PIDs that are using all camera available on the system
pub fn pid_using_camera() -> Vec<i32> {
    let mut pids = Vec::new();
    for cam in get_cam_devices() {
        let pid = fusers(cam.as_str());
        pids.extend(pid.iter());
    }
    pids
}

/// Accumulates names of all processes using the camera
pub fn proc_using_camera() -> Vec<String> {
    let pids = pid_using_camera();
    let mut processes = Vec::with_capacity(pids.len());
    for pid in pids {
        processes.push(pid_name(pid).unwrap_or(format!("Unknow PID {}", pid)));
    }
    processes
}

#[test]
fn test_cam_usage() {
    let procs = proc_using_camera();
    println!("{procs:#?}");
}
