#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

// Shared error codes
#define ERR_NO_ERR 0
#define ERR_OUT_OF_MEMORY 1
#define ERR_ALL_DEVICES_FAILED 2

// Debug logging toggle
static int is_debug_enabled = 0;

static void set_debug_enabled(int enabled) {
  is_debug_enabled = enabled;
}

#define DEBUG_LOG(fmt, ...) \
    do { if (is_debug_enabled) NSLog((fmt), ##__VA_ARGS__); } while (0)

// Shared helper to get device description
static void getDeviceDescription(NSString *uid, NSString **description) {
  AVCaptureDevice *avDevice = [AVCaptureDevice deviceWithUniqueID:uid];
  if (avDevice == nil) {
    *description = [NSString
        stringWithFormat:@"%@ (failed to get AVCaptureDevice with device UID)",
                         uid];
  } else {
    *description =
        [NSString stringWithFormat:
                      @"%@ (name: '%@', model: '%@', is exclusively used: %d)",
                      uid, [avDevice localizedName], [avDevice modelID],
                      [avDevice isInUseByAnotherApplication]];
  }
}
