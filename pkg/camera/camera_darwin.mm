#import <AVFoundation/AVFoundation.h>
#import <CoreMediaIO/CMIOHardware.h>
#import <Foundation/Foundation.h>

// TODO how to use single `common/errno.mm` file for both packages?
const int VD_ERR_NO_ERR = 0;
const int VD_ERR_OUT_OF_MEMORY = 1;
const int VD_ERR_ALL_DEVICES_FAILED = 2;

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
    NSLog(@"getVideoDevicesCount(): error: %d", err);
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
    NSLog(@"getVideoDevices(): get data size error: %d", err);
    return err;
  }

  err = CMIOObjectGetPropertyData(kCMIOObjectSystemObject, &prop, 0, nil,
                                  dataSize, &dataUsed, devices);
  if (err != kCMIOHardwareNoError) {
    NSLog(@"getVideoDevices(): get data error: %d", err);
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
    NSLog(@"getVideoDeviceUID(): get data size error: %d", err);
    return err;
  }

  CFStringRef uidStringRef = NULL;
  err = CMIOObjectGetPropertyData(device, &prop, 0, nil, dataSize, &dataUsed,
                                  &uidStringRef);
  if (err != kCMIOHardwareNoError) {
    NSLog(@"getVideoDeviceUID(): get data error: %d", err);
    return err;
  }

  *uid = (NSString *)uidStringRef;

  return err;
}

void getVideoDeviceDescription(NSString *uid, NSString **description) {
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

OSStatus getVideoDeviceIsUsed(CMIOObjectID device, int *isUsed) {
  OSStatus err;
  UInt32 dataSize = 0;
  UInt32 dataUsed = 0;

  CMIOObjectPropertyAddress prop = {kCMIODevicePropertyDeviceIsRunningSomewhere,
                                    kCMIOObjectPropertyScopeWildcard,
                                    kCMIOObjectPropertyElementWildcard};

  err = CMIOObjectGetPropertyDataSize(device, &prop, 0, nil, &dataSize);
  if (err != kCMIOHardwareNoError) {
    NSLog(@"getVideoDeviceIsUsed(): get data size error: %d", err);
    return err;
  }

  err = CMIOObjectGetPropertyData(device, &prop, 0, nil, dataSize, &dataUsed,
                                  isUsed);
  if (err != kCMIOHardwareNoError) {
    NSLog(@"getVideoDeviceIsUsed(): get data error: %d", err);
    return err;
  }

  return err;
}

OSStatus IsCameraOn(int *on) {
  NSLog(@"C.IsCameraOn()");

  OSStatus err;

  int count;
  err = getVideoDevicesCount(&count);
  if (err) {
    NSLog(@"C.IsCameraOn(): failed to get devices count, error: %d", err);
    return err;
  }

  CMIODeviceID *devices = (CMIODeviceID *)malloc(count * sizeof(*devices));
  if (devices == NULL) {
    NSLog(@"C.IsCameraOn(): failed to allocate memory, device count: %d",
          count);
    return VD_ERR_OUT_OF_MEMORY;
  }

  err = getVideoDevices(count, devices);
  if (err) {
    NSLog(@"C.IsCameraOn(): failed to get devices, error: %d", err);
    free(devices);
    devices = NULL;
    return err;
  }

  NSLog(@"C.IsCameraOn(): found devices: %d", count);
  if (count > 0) {
    NSLog(@"C.IsCameraOn(): # | is used | description");
  }

  int failedDeviceCount = 0;
  int ignoredDeviceCount = 0;

  for (int i = 0; i < count; i++) {
    CMIOObjectID device = devices[i];

    NSString *uid;
    err = getVideoDeviceUID(device, &uid);
    if (err) {
      failedDeviceCount++;
      NSLog(@"C.IsCameraOn(): %d | -       | failed to get device UID: %d", i,
            err);
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
      NSLog(@"C.IsCameraOn(): %d | -       | failed to get device status: %d",
            i, err);
      continue;
    }

    NSString *description;
    getVideoDeviceDescription(uid, &description);

    NSLog(@"C.IsCameraOn(): %d | %s     | %@", i,
          isDeviceUsed == 0 ? "NO " : "YES", description);

    if (isDeviceUsed != 0) {
      *on = 1;
    }
  }

  free(devices);
  devices = NULL;

  NSLog(@"C.IsCameraOn(): failed devices: %d", failedDeviceCount);
  NSLog(@"C.IsCameraOn(): ignored devices (always on): %d", ignoredDeviceCount);
  NSLog(@"C.IsCameraOn(): is any camera on: %s", *on == 0 ? "NO" : "YES");

  if (failedDeviceCount == count) {
    return VD_ERR_ALL_DEVICES_FAILED;
  }

  return VD_ERR_NO_ERR;
}
