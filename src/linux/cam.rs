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
