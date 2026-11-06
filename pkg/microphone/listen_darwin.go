package microphone

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation
#cgo LDFLAGS: -framework AVFoundation
#cgo LDFLAGS: -framework CoreAudio

#include <CoreAudio/AudioHardware.h>
int StartMicrophoneListener(void);
*/
import "C"

import (
	"fmt"
	"sync"
)

var (
	listenerMu   sync.Mutex
	listenerFunc func(isOn bool)
)

//export goMicrophoneStateChanged
func goMicrophoneStateChanged(isOn C.int) {
	listenerMu.Lock()
	f := listenerFunc
	listenerMu.Unlock()
	if f != nil {
		f(isOn == 1)
	}
}

// StartMicrophoneListener registers OS-level CoreAudio property listeners
// and invokes onChange every time the aggregated microphone state ("is any
// capture device running somewhere") changes. The callback is invoked
// immediately with the current state, then on every subsequent change.
//
// The listeners are driven by the OS through Grand Central Dispatch: no
// polling is involved. Only one listener can be active at a time; calling
// StartMicrophoneListener again replaces the callback.
func StartMicrophoneListener(onChange func(isOn bool)) error {
	listenerMu.Lock()
	listenerFunc = onChange
	listenerMu.Unlock()

	if errCode := C.StartMicrophoneListener(); errCode != 0 {
		return fmt.Errorf("StartMicrophoneListener(): failed with error code: %d", int(errCode))
	}
	return nil
}
