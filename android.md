    Start-Process cmake -ArgumentList "cmake -G ""MinGW Makefiles"" -DCMAKE_MAKE_PROGRAM=E:\dev\crystax-ndk-10.3.1\prebuilt\windows\bin\make.exe -DCMAKE_TOOLCHAIN_FILE=E:\dev\crystax-ndk-10.3.1\cmake\toolchain.cmake -DANDROID_NDK=E:\dev\crystax-ndk-10.3.1 -DCMAKE_BUILD_TYPE=Debug -DANDROID_ABI=armeabi-v7a ../.." -NoNewWindow

    cmake.exe --build . 2> errors.txt

    E:\dev\crystax-ndk-10.3.1\prebuilt\windows\bin\make.exe install