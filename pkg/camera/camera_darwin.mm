#import <CoreMediaIO/CMIOHardware.h>
#import "../common/common_darwin.h"

void CameraSetDebug(int enabled) {
  set_debug_enabled(enabled);
}

bool isIgnoredDeviceUID(NSString *uid) {
  // OBS virtual device always returns "is used" even when OBS is not running
  if ([uid isEqual:@"obs-virtual-cam-device"]) {
    return true;
  }
  return false;
}

OSStatus getVideoDevicesCount(int *count) {
  OSStatus err;
  UInt32 dataSize = 0;

  CMIOObjectPropertyAddress prop = {kCMIOHardwarePropertyDevices,
                                    kCMIOObjectPropertyScopeGlobal,
                                    kCMIOObjectPropertyElementMain};

  err = CMIOObjectGetPropertyDataSize(kCMIOObjectSystemObject, &prop, 0, nil,
                                      &dataSize);
  if (err != kCMIOHardwareNoError) {
    DEBUG_LOG(@"getVideoDevicesCount(): error: %d", (int)err);
    return err;
  }

  *count = dataSize / sizeof(CMIODeviceID);

  return err;
}

OSStatus getVideoDevices(int count, CMIODeviceID *devices) {
  OSStatus err;
  UInt32 dataSize = 0;
  UInt32 dataUsed = 0;

  CMIOObjectPropertyAddress prop = {kCMIOHardwarePropertyDevices,
                                    kCMIOObjectPropertyScopeGlobal,
                                    kCMIOObjectPropertyElementMain};

  err = CMIOObjectGetPropertyDataSize(kCMIOObjectSystemObject, &prop, 0, nil,
                                      &dataSize);
  if (err != kCMIOHardwareNoError) {
    DEBUG_LOG(@"getVideoDevices(): get data size error: %d", (int)err);
    return err;
  }

  err = CMIOObjectGetPropertyData(kCMIOObjectSystemObject, &prop, 0, nil,
                                  dataSize, &dataUsed, devices);
  if (err != kCMIOHardwareNoError) {
    DEBUG_LOG(@"getVideoDevices(): get data error: %d", (int)err);
    return err;
  }

  return err;
}

OSStatus getVideoDeviceUID(CMIOObjectID device, NSString **uid) {
  OSStatus err;
  UInt32 dataSize = 0;
  UInt32 dataUsed = 0;

  CMIOObjectPropertyAddress prop = {kCMIODevicePropertyDeviceUID,
                                    kCMIOObjectPropertyScopeWildcard,
                                    kCMIOObjectPropertyElementWildcard};

  err = CMIOObjectGetPropertyDataSize(device, &prop, 0, nil, &dataSize);
  if (err != kCMIOHardwareNoError) {
    DEBUG_LOG(@"getVideoDeviceUID(): get data size error: %d", (int)err);
    return err;
  }

  CFStringRef uidStringRef = NULL;
  err = CMIOObjectGetPropertyData(device, &prop, 0, nil, dataSize, &dataUsed,
                                  &uidStringRef);
  if (err != kCMIOHardwareNoError) {
    DEBUG_LOG(@"getVideoDeviceUID(): get data error: %d", (int)err);
    return err;
  }

  if (uidStringRef != NULL) {
    *uid = [((NSString *)uidStringRef) copy];
    CFRelease(uidStringRef);
  } else {
    *uid = nil;
  }

  return err;
}

OSStatus getVideoDeviceIsUsed(CMIOObjectID device, int *isUsed) {
  OSStatus err;
  UInt32 dataSize = 0;
  UInt32 dataUsed = 0;

  CMIOObjectPropertyAddress prop = {kCMIODevicePropertyDeviceIsRunningSomewhere,
                                    kCMIOObjectPropertyScopeWildcard,
                                    kCMIOObjectPropertyElementWildcard};

  err = CMIOObjectGetPropertyDataSize(device, &prop, 0, nil, &dataSize);
  if (err != kCMIOHardwareNoError) {
    DEBUG_LOG(@"getVideoDeviceIsUsed(): get data size error: %d", (int)err);
    return err;
  }

  err = CMIOObjectGetPropertyData(device, &prop, 0, nil, dataSize, &dataUsed,
                                  isUsed);
  if (err != kCMIOHardwareNoError) {
    DEBUG_LOG(@"getVideoDeviceIsUsed(): get data error: %d", (int)err);
    return err;
  }

  return err;
}

OSStatus IsCameraOn(int *on) {
  DEBUG_LOG(@"C.IsCameraOn()");

  OSStatus err;

  int count;
  err = getVideoDevicesCount(&count);
  if (err) {
    DEBUG_LOG(@"C.IsCameraOn(): failed to get devices count, error: %d", (int)err);
    return err;
  }

  CMIODeviceID *devices = (CMIODeviceID *)malloc(count * sizeof(*devices));
  if (devices == NULL) {
    DEBUG_LOG(@"C.IsCameraOn(): failed to allocate memory, device count: %d",
          count);
    return ERR_OUT_OF_MEMORY;
  }

  err = getVideoDevices(count, devices);
  if (err) {
    DEBUG_LOG(@"C.IsCameraOn(): failed to get devices, error: %d", (int)err);
    free(devices);
    devices = NULL;
    return err;
  }

  DEBUG_LOG(@"C.IsCameraOn(): found devices: %d", count);
  if (count > 0) {
    DEBUG_LOG(@"C.IsCameraOn(): # | is used | description");
  }

  int failedDeviceCount = 0;
  int ignoredDeviceCount = 0;

  for (int i = 0; i < count; i++) {
    @autoreleasepool {
      CMIOObjectID device = devices[i];

      NSString *uid = nil;
      err = getVideoDeviceUID(device, &uid);
      if (err) {
        failedDeviceCount++;
        DEBUG_LOG(@"C.IsCameraOn(): %d | -       | failed to get device UID: %d", i,
              (int)err);
        continue;
      }

      if (uid == nil || isIgnoredDeviceUID(uid)) {
        ignoredDeviceCount++;
        [uid release];
        continue;
      }

      int isDeviceUsed;
      err = getVideoDeviceIsUsed(device, &isDeviceUsed);
      if (err) {
        failedDeviceCount++;
        DEBUG_LOG(@"C.IsCameraOn(): %d | -       | failed to get device status: %d",
              i, (int)err);
        [uid release];
        continue;
      }

      NSString *description;
      getDeviceDescription(uid, &description);

      DEBUG_LOG(@"C.IsCameraOn(): %d | %s     | %@", i,
            isDeviceUsed == 0 ? "NO " : "YES", description);

      if (isDeviceUsed != 0) {
        *on = 1;
      }
      [uid release];
    }
  }

  free(devices);
  devices = NULL;

  DEBUG_LOG(@"C.IsCameraOn(): failed devices: %d", failedDeviceCount);
  DEBUG_LOG(@"C.IsCameraOn(): ignored devices (always on): %d", ignoredDeviceCount);
  DEBUG_LOG(@"C.IsCameraOn(): is any camera on: %s", *on == 0 ? "NO" : "YES");

  if (failedDeviceCount == count && count > 0) {
    return ERR_ALL_DEVICES_FAILED;
  }

  return ERR_NO_ERR;
}

// ---------------------------------------------------------------------------
// Event-driven API: OS-level property listeners (no polling).
// ---------------------------------------------------------------------------

// Go-side callback, exported from listen_darwin.go.
extern void goCameraStateChanged(int isOn);

// Whether the aggregated state was ON at last notification, used to only
// invoke the Go callback on actual changes.
static int cameraLastNotifiedState = -1;

// Recompute "is any camera running somewhere" and notify Go on change.
static void cameraNotifyIfChanged() {
  int on = 0;
  if (IsCameraOn(&on) != ERR_NO_ERR) {
    return;
  }
  if (on != cameraLastNotifiedState) {
    cameraLastNotifiedState = on;
    goCameraStateChanged(on);
  }
}

// Block-based property listeners: dispatched on a dedicated serial GCD
// queue, so no run loop is required on the calling thread (a Go program
// never runs the main run loop, which the main queue depends on).
static dispatch_queue_t mediaDevicesListenerQueue(void) {
  static dispatch_queue_t queue = NULL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    queue = dispatch_queue_create("media-devices-state.camera.listener",
                                  DISPATCH_QUEUE_SERIAL);
  });
  return queue;
}

static void cameraRegisterDeviceListeners(void);

static CMIOObjectPropertyListenerBlock cameraDeviceListenerBlock =
    ^(UInt32 numberAddresses, const CMIOObjectPropertyAddress addresses[]) {
      cameraNotifyIfChanged();
    };

static CMIOObjectPropertyListenerBlock cameraDevicesChangedBlock =
    ^(UInt32 numberAddresses, const CMIOObjectPropertyAddress addresses[]) {
      // Device list changed (camera plugged/unplugged): re-register
      // per-device listeners and re-evaluate the state.
      cameraRegisterDeviceListeners();
      cameraNotifyIfChanged();
    };

static void cameraRegisterDeviceListeners(void) {
  int count = 0;
  if (getVideoDevicesCount(&count) != kCMIOHardwareNoError || count == 0) {
    return;
  }

  CMIODeviceID *devices = (CMIODeviceID *)malloc(count * sizeof(*devices));
  if (devices == NULL) {
    return;
  }
  if (getVideoDevices(count, devices) != kCMIOHardwareNoError) {
    free(devices);
    return;
  }

  CMIOObjectPropertyAddress runningProp = {kCMIODevicePropertyDeviceIsRunningSomewhere,
                                           kCMIOObjectPropertyScopeWildcard,
                                           kCMIOObjectPropertyElementWildcard};
  for (int i = 0; i < count; i++) {
    CMIOObjectAddPropertyListenerBlock(devices[i], &runningProp,
                                       mediaDevicesListenerQueue(),
                                       cameraDeviceListenerBlock);
  }

  free(devices);
}

int StartCameraListener(void) {
  cameraLastNotifiedState = -1;

  // Listen for device list changes on the system object.
  CMIOObjectPropertyAddress devicesProp = {kCMIOHardwarePropertyDevices,
                                           kCMIOObjectPropertyScopeGlobal,
                                           kCMIOObjectPropertyElementMain};
  OSStatus err = CMIOObjectAddPropertyListenerBlock(kCMIOObjectSystemObject, &devicesProp,
                                                    mediaDevicesListenerQueue(),
                                                    cameraDevicesChangedBlock);
  if (err != kCMIOHardwareNoError) {
    DEBUG_LOG(@"StartCameraListener(): failed to add devices listener: %d", (int)err);
    return (int)err;
  }

  cameraRegisterDeviceListeners();

  // Emit the initial state.
  cameraNotifyIfChanged();
  return 0;
}
