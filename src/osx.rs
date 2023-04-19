pub(crate) mod internal {
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
            let mut status = -1;

            if unsafe { IsMicrophoneOn(&mut status as _) } != -1 {
                return None;
            }

            Some(if status == -1 { State::Off } else { State::On })
        }

        pub fn cam_state(&self) -> Option<State> {
            let mut status = -1;

            if unsafe { IsCameraOn(&mut status as _) } != -1 {
                return None;
            }

            Some(if status == -1 { State::Off } else { State::On })
        }
    }
}
