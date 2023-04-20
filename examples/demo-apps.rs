fn main() {
    loop {
        println!(
            "Apps using mic: {:?}\nApps using cam: {:?}\n",
            media_state::apps_using_mic(),
            media_state::apps_using_cam()
        );
        std::thread::sleep(std::time::Duration::from_secs(1));
    }
}
