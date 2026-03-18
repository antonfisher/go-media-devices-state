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

	"github.com/antonfisher/go-media-devices-state/pkg/common"
)

// EnableLogging enables or disables debug logging in the C implementation
func EnableLogging(enabled bool) {
	if enabled {
		C.CameraSetDebug(C.int(1))
	} else {
		C.CameraSetDebug(C.int(0))
	}
}

// IsCameraOn returns true is any camera in the system is ON
func IsCameraOn() (bool, error) {
	isCameraOn := C.int(0)
	errCode := C.IsCameraOn(&isCameraOn)

	if errCode != common.ErrNoErr {
		var msg string
		switch errCode {
		case common.ErrOutOfMemory:
			msg = "IsCameraOn(): failed to allocate memory"
		case common.ErrAllDevicesFailed:
			msg = "IsCameraOn(): all devices failed to provide status"
		default:
			msg = fmt.Sprintf("IsCameraOn(): failed with error code: %d", errCode)
		}
		return false, fmt.Errorf("IsCameraOn(): %s", msg)
	}

	return isCameraOn == 1, nil
}
