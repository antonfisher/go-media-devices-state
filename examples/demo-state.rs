fn main() {
    loop {
        println!(
            "Mic status: {:?}\nCam status: {:?}\n",
            media_state::microphone_state(),
            media_state::camera_state()
        );
        std::thread::sleep(std::time::Duration::from_secs(1));
    }
}
