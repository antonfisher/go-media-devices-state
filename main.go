package mediadevicesstate

import (
	"github.com/antonfisher/go-media-devices-state/pkg/camera"
	"github.com/antonfisher/go-media-devices-state/pkg/debug"
	"github.com/antonfisher/go-media-devices-state/pkg/microphone"
)

// EnableLogging enables or disables debug logging for all devices
func EnableLogging(enabled bool) {
	camera.EnableLogging(enabled)
	microphone.EnableLogging(enabled)
}

// IsCameraOn returns true is any camera in the system is ON
func IsCameraOn() (bool, error) {
	return camera.IsCameraOn()
}

// IsMicrophoneOn returns true is any camera in the system is ON
func IsMicrophoneOn() (bool, error) {
	return microphone.IsMicrophoneOn()
}

// Debug calls all available device functions and prints the results
func Debug() {
	debug.Debug()
}
