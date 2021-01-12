# go-media-devices-state

[![Go Report Card](https://goreportcard.com/badge/github.com/antonfisher/go-media-devices-state)](https://goreportcard.com/report/github.com/antonfisher/go-media-devices-state)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)

Go module to get camera/microphone state, checks if camera/microphone is ON.

Module uses `cgo` to call native specific API on different platforms (currently only darwin is implemented.)

## Installation

```shell
go get github.com/antonfisher/go-media-devices-state
```

## Demo

Demo prints out all system video devices and their states (ON/OFF):

```shell
git clone https://github.com/antonfisher/go-media-devices-state.git
cd go-media-devices-state
go run -a cmd/demo.go
```

## Usage

```go
package main

import (
	"fmt"

	mediaDevices "github.com/antonfisher/go-media-devices-state"
)

func main() {
	isCameraOn, err := mediaDevices.IsCameraOn()
	if err != nil {
		fmt.Println("Error:", err)
	} else {
		fmt.Println("Is camera on:", isCameraOn)
	}
}
```

## Implemented APIs

| Platform | `IsCameraOn()` | `IsMicOn()` | `Debug()` | Details                                |
|----------|:--------------:|:-----------:|-----------|----------------------------------------|
| darwin   |       ☑        |      ☐      | ☑         | Using `CoreMediaIO/CMIOHardware.h` API |
| linux    |       ☐        |      ☐      | ☐         |                                        |
| windows  |       ☐        |      ☐      | ☐         |                                        |

```go
// IsCameraOn return true is any camera in the system is ON
func IsCameraOn() (bool, error)

// Debug calls all available device functions and prints the results
func Debug()
```

## Troubleshooting

Get list of registered cameras:
```shell
// macOS
system_profiler SPCameraDataType
```

## License

MIT License.
