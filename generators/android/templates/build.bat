ndk-build NDK_DEBUG=1
ant debug
adb install -r bin/NativeActivity-debug-unaligned.apk
