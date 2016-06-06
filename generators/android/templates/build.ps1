ndk-build NDK_DEBUG=1
if($?) {
ant debug
adb install -r bin/spacegame_android-debug-unaligned.apk
}