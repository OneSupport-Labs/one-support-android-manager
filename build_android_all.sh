#!/bin/bash
set -e
GREEN='\033[0;32m'
NC='\033[0m'
echo -e "${GREEN}RustDesk Android Build Start (Full Optimization + Libc++ Fix)...${NC}"
if [ -z "$ANDROID_NDK_HOME" ] || [ -z "$VCPKG_ROOT" ]; then
    echo "Error: Check ANDROID_NDK_HOME and VCPKG_ROOT"
    exit 1
fi
echo -e "${GREEN}0. Checking Code Generator...${NC}"
if ! cargo install --list | grep -q "flutter_rust_bridge_codegen v1.80.1"; then
    echo "Installing flutter_rust_bridge_codegen v1.80.1..."
    cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid
fi
echo -e "${GREEN}0.5. Fetching Flutter Dependencies...${NC}"
cd flutter
flutter pub get
cd ..
echo -e "${GREEN}1. Generating Bridge Code...${NC}"
flutter_rust_bridge_codegen --rust-input src/flutter_ffi.rs --dart-output flutter/lib/generated_bridge.dart
echo -e "${GREEN}2. Installing Dependencies...${NC}"
if [ ! -f "flutter/build_android_deps.sh" ]; then
    echo "Error: build_android_deps.sh not found!"
    exit 1
fi
cd flutter
chmod +x build_android_deps.sh
./build_android_deps.sh arm64-v8a
cd ..
echo -e "${GREEN}3. Building Rust Library...${NC}"
export RUSTFLAGS="-C link-arg=-Wl,-z,max-page-size=16384"
cargo ndk --platform 21 --target aarch64-linux-android build --release --lib --features flutter,hwcodec
echo -e "${GREEN}4. Copying & Stripping Libraries...${NC}"
mkdir -p flutter/android/app/src/main/jniLibs/arm64-v8a
# 4.1. librustdesk.so 복사
echo -e "${GREEN}[CC] Copying librustdesk.so...${NC}"
if [ -f "target/aarch64-linux-android/release/liblibrustdesk.so" ]; then
    cp target/aarch64-linux-android/release/liblibrustdesk.so flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so
elif [ -f "target/aarch64-linux-android/release/librustdesk.so" ]; then
    cp target/aarch64-linux-android/release/librustdesk.so flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so
else
    echo -e "\033[0;31mError: Rust library not found.\033[0m"
    exit 1
fi
# 4.2. libc++_shared.so 찾아서 복사
echo -e "${GREEN}[CC] Searching for libc++_shared.so...${NC}"
LIBCPP_PATH=$(find "$ANDROID_NDK_HOME" -name "libc++_shared.so" | grep "aarch64" | head -n 1)
if [ -f "$LIBCPP_PATH" ]; then
    echo "  -> Found at: $LIBCPP_PATH"
    cp "$LIBCPP_PATH" flutter/android/app/src/main/jniLibs/arm64-v8a/
else
    echo -e "\033[0;31mError: libc++_shared.so not found.\033[0m"
    exit 1
fi
# 4.3. STRIP 적용 (용량 줄이기 핵심!)
echo -e "${GREEN}[CC] Stripping libraries...${NC}"
STRIP="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"
if [ -f "$STRIP" ]; then
    "$STRIP" flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so
    "$STRIP" flutter/android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so
    echo "  -> Strip Complete!"
fi
echo -e "${GREEN}5. Building Flutter APK (Full Optimization)...${NC}"
cd flutter
flutter clean
flutter pub get
# --no-shrink 제거 (build.gradle의 minifyEnabled 사용)
# --obfuscate 옵션 추가 (심볼 난독화로 추가 용량 감소)
# --no-tree-shake-icons 추가 (아이콘 폰트 에러 방지)
flutter build apk --release --target-platform android-arm64 --obfuscate --split-debug-info=./debug-info --no-tree-shake-icons
echo -e "${GREEN}Build Done!${NC}"
