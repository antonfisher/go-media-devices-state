fn main() {
    loop {
        let mic = media_state::microphone_state();
        let cam = media_state::camera_state();
        println!("Microphone is: {:?}", mic);
        println!("Camera is: {:?}", cam);

        std::thread::sleep(std::time::Duration::from_secs(1));
    }
}
