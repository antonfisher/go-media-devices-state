#import <CoreAudio/AudioHardware.h>
#import "../common/common_darwin.h"

void MicrophoneSetDebug(int enabled) {
  set_debug_enabled(enabled);
}

OSStatus getAudioDevicesCount(int *count) {
  OSStatus err;
  UInt32 dataSize = 0;

  AudioObjectPropertyAddress prop = {kAudioHardwarePropertyDevices,
                                     kAudioObjectPropertyScopeGlobal,
                                     kAudioObjectPropertyElementMain};

  err = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &prop, 0, nil,
                                       &dataSize);
  if (err != kAudioHardwareNoError) {
    DEBUG_LOG(@"getAudioDevicesCount(): error: %d", (int)err);
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
                                     kAudioObjectPropertyElementMain};

  err = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &prop, 0, nil,
                                       &dataSize);
  if (err != kAudioHardwareNoError) {
    DEBUG_LOG(@"getAudioDevices(): get data size error: %d", (int)err);
    return err;
  }

  err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &prop, 0, nil,
                                   &dataSize, devices);
  if (err != kAudioHardwareNoError) {
    DEBUG_LOG(@"getAudioDevices(): get data error: %d", (int)err);
    return err;
  }

  return err;
}

OSStatus getAudioDeviceUID(AudioDeviceID device, NSString **uid) {
  OSStatus err;
  UInt32 dataSize = 0;

  AudioObjectPropertyAddress prop = {kAudioDevicePropertyDeviceUID,
                                     kAudioObjectPropertyScopeGlobal,
                                     kAudioObjectPropertyElementMain};

  err = AudioObjectGetPropertyDataSize(device, &prop, 0, nil, &dataSize);
  if (err != kAudioHardwareNoError) {
    DEBUG_LOG(@"getAudioDeviceUID(): get data size error: %d", (int)err);
    return err;
  }

  CFStringRef uidStringRef = NULL;
  err = AudioObjectGetPropertyData(device, &prop, 0, nil, &dataSize,
                                   &uidStringRef);
  if (err != kAudioHardwareNoError) {
    DEBUG_LOG(@"getAudioDeviceUID(): get data error: %d", (int)err);
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

bool isAudioCaptureDevice(NSString *uid) {
  AVCaptureDevice *avDevice = [AVCaptureDevice deviceWithUniqueID:uid];
  return avDevice != nil;
}

OSStatus getAudioDeviceIsUsed(AudioDeviceID device, int *isUsed) {
  OSStatus err;
  UInt32 dataSize = 0;

  AudioObjectPropertyAddress prop = {
      kAudioDevicePropertyDeviceIsRunningSomewhere,
      kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};

  err = AudioObjectGetPropertyDataSize(device, &prop, 0, nil, &dataSize);
  if (err != kAudioHardwareNoError) {
    DEBUG_LOG(@"getAudioDeviceIsUsed(): get data size error: %d", (int)err);
    return err;
  }

  err = AudioObjectGetPropertyData(device, &prop, 0, nil, &dataSize, isUsed);
  if (err != kAudioHardwareNoError) {
    DEBUG_LOG(@"getAudioDeviceIsUsed(): get data error: %d", (int)err);
    return err;
  }

  return err;
}

OSStatus IsMicrophoneOn(int *on) {
  DEBUG_LOG(@"C.IsMicrophoneOn()");

  OSStatus err;

  int count;
  err = getAudioDevicesCount(&count);
  if (err) {
    DEBUG_LOG(@"C.IsMicrophoneOn(): failed to get devices count, error: %d", (int)err);
    return err;
  }

  AudioDeviceID *devices = (AudioDeviceID *)malloc(count * sizeof(*devices));
  if (devices == NULL) {
    DEBUG_LOG(@"C.IsMicrophoneOn(): failed to allocate memory, device count: %d",
          count);
    return ERR_OUT_OF_MEMORY;
  }

  err = getAudioDevices(count, devices);
  if (err) {
    DEBUG_LOG(@"C.IsMicrophoneOn(): failed to get devices, error: %d", (int)err);
    free(devices);
    devices = NULL;
    return err;
  }

  DEBUG_LOG(@"C.IsMicrophoneOn(): found devices: %d", count);
  if (count > 0) {
    DEBUG_LOG(@"C.IsMicrophoneOn(): # | is used | description");
  }

  int failedDeviceCount = 0;
  int ignoredDeviceCount = 0;

  for (int i = 0; i < count; i++) {
    @autoreleasepool {
      AudioDeviceID device = devices[i];

      NSString *uid = nil;
      err = getAudioDeviceUID(device, &uid);
      if (err) {
        failedDeviceCount++;
        DEBUG_LOG(@"C.IsMicrophoneOn(): %d | -       | failed to get device UID: %d",
              i, (int)err);
        continue;
      }

      if (uid == nil || !isAudioCaptureDevice(uid)) {
        ignoredDeviceCount++;
        [uid release];
        continue;
      }

      int isDeviceUsed;
      err = getAudioDeviceIsUsed(device, &isDeviceUsed);
      if (err) {
        failedDeviceCount++;
        DEBUG_LOG(
            @"C.IsMicrophoneOn(): %d | -       | failed to get device state: %d",
            i, (int)err);
        [uid release];
        continue;
      }

      NSString *description;
      getDeviceDescription(uid, &description);

      DEBUG_LOG(@"C.IsMicrophoneOn(): %d | %s     | %@", i,
            isDeviceUsed == 0 ? "NO " : "YES", description);

      if (isDeviceUsed != 0) {
        *on = 1;
      }
      [uid release];
    }
  }

  free(devices);
  devices = NULL;

  DEBUG_LOG(@"C.IsMicrophoneOn(): failed devices: %d", failedDeviceCount);
  DEBUG_LOG(@"C.IsMicrophoneOn(): ignored devices (speakers): %d",
        ignoredDeviceCount);
  DEBUG_LOG(@"C.IsMicrophoneOn(): is any microphone on: %s",
        *on == 0 ? "NO" : "YES");

  if (failedDeviceCount == count && count > 0) {
    return ERR_ALL_DEVICES_FAILED;
  }

  return ERR_NO_ERR;
}
