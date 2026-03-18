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

  *uid = (NSString *)uidStringRef;

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

      NSString *uid;
      err = getVideoDeviceUID(device, &uid);
      if (err) {
        failedDeviceCount++;
        DEBUG_LOG(@"C.IsCameraOn(): %d | -       | failed to get device UID: %d", i,
              (int)err);
        continue;
      }

      if (isIgnoredDeviceUID(uid)) {
        ignoredDeviceCount++;
        continue;
      }

      int isDeviceUsed;
      err = getVideoDeviceIsUsed(device, &isDeviceUsed);
      if (err) {
        failedDeviceCount++;
        DEBUG_LOG(@"C.IsCameraOn(): %d | -       | failed to get device status: %d",
              i, (int)err);
        continue;
      }

      NSString *description;
      getDeviceDescription(uid, &description);

      DEBUG_LOG(@"C.IsCameraOn(): %d | %s     | %@", i,
            isDeviceUsed == 0 ? "NO " : "YES", description);

      if (isDeviceUsed != 0) {
        *on = 1;
      }
    }
  }

  free(devices);
  devices = NULL;

  DEBUG_LOG(@"C.IsCameraOn(): failed devices: %d", failedDeviceCount);
  DEBUG_LOG(@"C.IsCameraOn(): ignored devices (always on): %d", ignoredDeviceCount);
  DEBUG_LOG(@"C.IsCameraOn(): is any camera on: %s", *on == 0 ? "NO" : "YES");

  if (failedDeviceCount == count) {
    return ERR_ALL_DEVICES_FAILED;
  }

  return ERR_NO_ERR;
}
