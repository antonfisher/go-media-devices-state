package main

import (
	"github.com/antonfisher/go-media-devices-state/pkg/camera"
	"github.com/antonfisher/go-media-devices-state/pkg/debug"
)

// IsCameraOn return true is any camera in the system is ON
func IsCameraOn() (bool, error) {
	return camera.IsCameraOn()
}

// Debug calls all available device functions and prints the results
func Debug() {
	debug.Debug()
}
