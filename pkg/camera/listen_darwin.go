package camera

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation
#cgo LDFLAGS: -framework AVFoundation
#cgo LDFLAGS: -framework CoreMediaIO

#include <CoreMediaIO/CMIOHardware.h>
#include <CoreFoundation/CoreFoundation.h>
int StartCameraListener(void);
*/
import "C"

import (
	"fmt"
	"runtime"
	"sync"
)

var (
	listenerMu   sync.Mutex
	listenerFunc func(isOn bool)
)

//export goCameraStateChanged
func goCameraStateChanged(isOn C.int) {
	listenerMu.Lock()
	f := listenerFunc
	listenerMu.Unlock()
	if f != nil {
		f(isOn == 1)
	}
}

// StartCameraListener registers OS-level CoreMediaIO property listeners and
// invokes onChange every time the aggregated camera state ("is any camera
// running somewhere") changes. The callback is invoked immediately with the
// current state, then on every subsequent change.
//
// CoreMediaIO delivers listener callbacks through the calling thread's run
// loop, so StartCameraListener must be called from a thread that runs a
// CFRunLoop — see RunMainRunLoop. No polling is involved. Only one listener
// can be active at a time; calling StartCameraListener again replaces the
// callback.
func StartCameraListener(onChange func(isOn bool)) error {
	listenerMu.Lock()
	listenerFunc = onChange
	listenerMu.Unlock()

	if errCode := C.StartCameraListener(); errCode != 0 {
		return fmt.Errorf("StartCameraListener(): failed with error code: %d", int(errCode))
	}
	return nil
}

// RunMainRunLoop locks the calling goroutine to its OS thread and runs the
// CoreFoundation run loop forever. CoreMediaIO (and some CoreAudio) listener
// callbacks are delivered through this run loop, so programs using the
// listener APIs should call this from main() before registering listeners:
//
//	func main() {
//		runtime.LockOSThread() // not strictly needed, RunMainRunLoop does it
//		... register listeners ...
//		mediaDevices.RunMainRunLoop()
//	}
func RunMainRunLoop() {
	runtime.LockOSThread()
	C.CFRunLoopRun()
}
