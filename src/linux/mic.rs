/// List out all microphone sources that can provide sound input
/// This can be integrated mic, or HDMI input etc.
pub fn get_mic_devices() -> Vec<String> {
    let paths = std::fs::read_dir("/dev/snd");
    if paths.is_err() {
        eprintln!(
            "Devices are not found on this machine, Maybe you're running in chroot environment"
        );
        return vec![];
    }
    let mut mic_devices = Vec::new();
    let paths = paths.unwrap();
    for path in paths.flatten() {
        let path_str = path.path().display().to_string();
        if path_str.contains("pcm") || path_str.contains("hw") {
            mic_devices.push(path_str);
        }
    }
    mic_devices
}
