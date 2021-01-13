#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/AudioHardware.h>
#import <Foundation/Foundation.h>

// TODO how to use single `common/errno.mm` file for both packages?
const int AD_ERR_NO_ERR = 0;
const int AD_ERR_OUT_OF_MEMORY = 1;
const int AD_ERR_ALL_DEVICES_FAILED = 2;

OSStatus getAudioDevicesCount(int *count) {
  OSStatus err;
  UInt32 dataSize = 0;

  AudioObjectPropertyAddress prop = {kAudioHardwarePropertyDevices,
                                     kAudioObjectPropertyScopeGlobal,
                                     kAudioObjectPropertyElementMaster};

  err = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &prop, 0, nil,
                                       &dataSize);
  if (err != kAudioHardwareNoError) {
    NSLog(@"getAudioDevicesCount(): error: %d", err);
    return err;
  }

  *count = dataSize / sizeof(AudioDeviceID);

  return err;
}

OSStatus getAudioDevices(int count, AudioDeviceID *devices) {
  OSStatus err;
  UInt32 dataSize = 0;

  AudioObjectPropertyAddress prop = {kAudioHardwarePropertyDevices,
                                     kAudioObjectPropertyScopeGlobal,
                                     kAudioObjectPropertyElementMaster};

  err = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &prop, 0, nil,
                                       &dataSize);
  if (err != kAudioHardwareNoError) {
    NSLog(@"getAudioDevices(): get data size error: %d", err);
    return err;
  }

  err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &prop, 0, nil,
                                   &dataSize, devices);
  if (err != kAudioHardwareNoError) {
    NSLog(@"getAudioDevices(): get data error: %d", err);
    return err;
  }

  return err;
}

OSStatus getAudioDeviceUID(AudioDeviceID device, NSString **uid) {
  OSStatus err;
  UInt32 dataSize = 0;

  AudioObjectPropertyAddress prop = {kAudioDevicePropertyDeviceUID,
                                     kAudioObjectPropertyScopeGlobal,
                                     kAudioObjectPropertyElementMaster};

  err = AudioObjectGetPropertyDataSize(device, &prop, 0, nil, &dataSize);
  if (err != kAudioHardwareNoError) {
    NSLog(@"getAudioDeviceUID(): get data size error: %d", err);
    return err;
  }

  CFStringRef uidStringRef = NULL;
  err = AudioObjectGetPropertyData(device, &prop, 0, nil, &dataSize,
                                   &uidStringRef);
  if (err != kAudioHardwareNoError) {
    NSLog(@"getAudioDeviceUID(): get data error: %d", err);
    return err;
  }

  *uid = (NSString *)uidStringRef;

  return err;
}

bool isAudioCaptureDevice(NSString *uid) {
  AVCaptureDevice *avDevice = [AVCaptureDevice deviceWithUniqueID:uid];
  return avDevice != nil;
}

void getAudioDeviceDescription(NSString *uid, NSString **description) {
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

OSStatus getAudioDeviceIsUsed(AudioDeviceID device, int *isUsed) {
  OSStatus err;
  UInt32 dataSize = 0;

  AudioObjectPropertyAddress prop = {
      kAudioDevicePropertyDeviceIsRunningSomewhere,
      kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster};

  err = AudioObjectGetPropertyDataSize(device, &prop, 0, nil, &dataSize);
  if (err != kAudioHardwareNoError) {
    NSLog(@"getAudioDeviceIsUsed(): get data size error: %d", err);
    return err;
  }

  err = AudioObjectGetPropertyData(device, &prop, 0, nil, &dataSize, isUsed);
  if (err != kAudioHardwareNoError) {
    NSLog(@"getAudioDeviceIsUsed(): get data error: %d", err);
    return err;
  }

  return err;
}

OSStatus IsMicrophoneOn(int *on) {
  NSLog(@"C.IsMicrophoneOn()");

  OSStatus err;

  int count;
  err = getAudioDevicesCount(&count);
  if (err) {
    NSLog(@"C.IsMicrophoneOn(): failed to get devices count, error: %d", err);
    return err;
  }

  AudioDeviceID *devices = (AudioDeviceID *)malloc(count * sizeof(*devices));
  if (devices == NULL) {
    NSLog(@"C.IsMicrophoneOn(): failed to allocate memory, device count: %d",
          count);
    return AD_ERR_OUT_OF_MEMORY;
  }

  err = getAudioDevices(count, devices);
  if (err) {
    NSLog(@"C.IsMicrophoneOn(): failed to get devices, error: %d", err);
    free(devices);
    devices = NULL;
    return err;
  }

  NSLog(@"C.IsMicrophoneOn(): found devices: %d", count);
  if (count > 0) {
    NSLog(@"C.IsMicrophoneOn(): # | is used | description");
  }

  int failedDeviceCount = 0;
  int ignoredDeviceCount = 0;

  for (int i = 0; i < count; i++) {
    AudioDeviceID device = devices[i];

    NSString *uid;
    err = getAudioDeviceUID(device, &uid);
    if (err) {
      failedDeviceCount++;
      NSLog(@"C.IsMicrophoneOn(): %d | -       | failed to get device UID: %d",
            i, err);
      continue;
    }

    if (!isAudioCaptureDevice(uid)) {
      ignoredDeviceCount++;
      continue;
    }

    int isDeviceUsed;
    err = getAudioDeviceIsUsed(device, &isDeviceUsed);
    if (err) {
      failedDeviceCount++;
      NSLog(
          @"C.IsMicrophoneOn(): %d | -       | failed to get device state: %d",
          i, err);
      continue;
    }

    NSString *description;
    getAudioDeviceDescription(uid, &description);

    NSLog(@"C.IsMicrophoneOn(): %d | %s     | %@", i,
          isDeviceUsed == 0 ? "NO " : "YES", description);

    if (isDeviceUsed != 0) {
      *on = 1;
    }
  }

  free(devices);
  devices = NULL;

  NSLog(@"C.IsMicrophoneOn(): failed devices: %d", failedDeviceCount);
  NSLog(@"C.IsMicrophoneOn(): ignored devices (speakers): %d",
        ignoredDeviceCount);
  NSLog(@"C.IsMicrophoneOn(): is any microphone on: %s",
        *on == 0 ? "NO" : "YES");

  if (failedDeviceCount == count) {
    return AD_ERR_ALL_DEVICES_FAILED;
  }

  return AD_ERR_NO_ERR;
}
