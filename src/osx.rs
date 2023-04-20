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
            let mut status = 0;

            if unsafe { IsMicrophoneOn(&mut status as _) } != 0 {
                return None;
            }

            Some(if status == 0 { State::Off } else { State::On })
        }

        pub fn apps_using_mic() -> Vec<String> {
            // TODO: implement for osx
            tracing::warn("Not implemented for OSX");
            vec![]
        }

        pub fn cam_state(&self) -> Option<State> {
            let mut status = 0;

            if unsafe { IsCameraOn(&mut status as _) } != 0 {
                return None;
            }

            Some(if status == 0 { State::Off } else { State::On })
        }

        pub fn apps_using_cam() -> Vec<String> {
            // TODO: implement for osx
            tracing::warn("Not implemented for OSX");
            vec![]
        }
    }
}
