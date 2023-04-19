mod cam;
mod fuser;
mod mic;

pub(crate) mod internal {
    use super::{cam, fuser::fusers_is_open, mic};
    use crate::State;

    pub struct MediaState;
    impl MediaState {
        pub fn new() -> Self {
            Self
        }

        pub fn mic_status(&self) -> Option<State> {
            for mic in mic::get_mic_devices() {
                if fusers_is_open(mic.as_str()) {
                    return Some(State::On);
                }
            }
            Some(State::Off)
        }

        pub fn cam_state(&self) -> Option<State> {
            for cam in cam::get_cam_devices() {
                if fusers_is_open(cam.as_str()) {
                    return Some(State::On);
                }
            }
            Some(State::Off)
        }
    }
}
