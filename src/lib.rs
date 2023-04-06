pub fn microphone_state() -> Option<State> {
    internal::MediaState::new().mic_status()
}

/// NOTE: might run into [this issue](https://github.com/antonfisher/go-media-devices-state/issues/2)
pub fn camera_state() -> Option<State> {
    internal::MediaState::new().cam_state()
}

#[derive(Debug)]
pub enum State {
    On,
    Off,
}

mod internal {
    extern "C" {
        pub fn IsMicrophoneOn(status: *mut std::ffi::c_int) -> std::ffi::c_int;
        pub fn IsCameraOn(status: *mut std::ffi::c_int) -> std::ffi::c_int;
    }

    use crate::State;

    pub struct MediaState;

    impl MediaState {
        pub fn new() -> Self {
            Self
        }

        pub fn mic_status(&self) -> Option<State> {
            let mut status = 0;

            if unsafe { IsMicrophoneOn(&mut status as _) } != 0 {
                return None;
            }

            Some(if status == 0 { State::Off } else { State::On })
        }

        pub fn cam_state(&self) -> Option<State> {
            let mut status = 0;

            if unsafe { IsCameraOn(&mut status as _) } != 0 {
                return None;
            }

            Some(if status == 0 { State::Off } else { State::On })
        }
    }
}
