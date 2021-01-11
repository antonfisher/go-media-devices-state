package camera

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation
#cgo LDFLAGS: -framework AVFoundation
#cgo LDFLAGS: -framework CoreMediaIO
#include "camera_darwin.mm"
*/
import "C"
import (
	"fmt"
)

//TODO add known codes for CoreMediaIO (?)
const (
	errNoErr = iota
	errOutOfMemory
	errAllDevicesFailed
)

// IsCameraOn return true is any camera in the system is ON
func IsCameraOn() (bool, error) {
	isCameraOn := C.int(0)
	errCode := C.IsCameraOn(&isCameraOn)

	if errCode != 0 {
		var msg string
		switch errCode {
		case errOutOfMemory:
			msg = "IsCameraOn(): failed to allocate memory"
		case errAllDevicesFailed:
			msg = "IsCameraOn(): all devices failed to provide status"
		default:
			msg = fmt.Sprintf("IsCameraOn(): failed with error code: %d", errCode)
		}
		return false, fmt.Errorf("IsCameraOn(): %s", msg)
	}

	return isCameraOn != 0, nil
}
