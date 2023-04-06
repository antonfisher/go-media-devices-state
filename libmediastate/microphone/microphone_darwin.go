package microphone

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation
#cgo LDFLAGS: -framework AVFoundation
#cgo LDFLAGS: -framework CoreAudio
#include "microphone_darwin.mm"
*/
import "C"
import (
	"fmt"

	"github.com/antonfisher/go-media-devices-state/pkg/common"
)

// IsMicrophoneOn returns true is any microphone in the system is ON
func IsMicrophoneOn() (bool, error) {
	isMicrophoneOn := C.int(0)
	errCode := C.IsMicrophoneOn(&isMicrophoneOn)

	if errCode != common.ErrNoErr {
		var msg string
		switch errCode {
		case common.ErrOutOfMemory:
			msg = "IsMicrophoneOn(): failed to allocate memory"
		case common.ErrAllDevicesFailed:
			msg = "IsMicrophoneOn(): all devices failed to provide status"
		default:
			msg = fmt.Sprintf("IsMicrophoneOn(): failed with error code: %d", errCode)
		}
		return false, fmt.Errorf("IsMicrophoneOn(): %s", msg)
	}

	return isMicrophoneOn == 1, nil
}
