ndk-build NDK_DEBUG=1
ant debug
adb install -r bin/${application_name}-debug-unaligned.apk
