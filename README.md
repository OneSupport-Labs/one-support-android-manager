<p align="center">
  <img src="res/logo-header.png" alt="One Support Android Manager"><br>
  <a href="#build">Build</a> •
  <a href="#file-structure">Structure</a><br>
</p>

# One Support Android Manager

**One Support Android Manager** is a customized remote desktop manager for Android, based on [RustDesk](https://github.com/rustdesk/rustdesk).
This project is open-source and licensed under the **GNU Affero General Public License v3 (AGPL-3.0)**.

> [!IMPORTANT]
> **Attribution**: This software is a fork of RustDesk. We respect the original work and the open-source community.
> The full source code and modifications are available in this repository in compliance with the AGPL-3.0 license.

---

### 🇰🇷 한국어 소개 (Korean Introduction)

**One Support Android Manager**은 [RustDesk](https://github.com/rustdesk/rustdesk)를 기반으로 한 안드로이드용 맞춤형 원격 데스크톱 매니저입니다.
이 프로젝트는 오픈 소스이며 **GNU Affero General Public License v3 (AGPL-3.0)** 라이선스를 따릅니다.

> [!IMPORTANT]
> **저작권 고지**: 이 소프트웨어는 RustDesk의 포크(Fork) 버전입니다. 우리는 원작자의 작업과 오픈 소스 커뮤니티를 존중합니다.
> 전체 소스 코드와 수정 사항은 AGPL-3.0 라이선스에 따라 이 저장소에 공개되어 있습니다.

## License / 라이선스
This project is licensed under the **AGPL-3.0** license. See the [LICENCE](LICENCE) file for details.
If you use this software to provide a service over a network, you are obligated to make the source code available to your users.

이 프로젝트는 **AGPL-3.0** 라이선스를 따릅니다. 자세한 내용은 [LICENCE](LICENCE) 파일을 참고하세요.
네트워크를 통해 이 소프트웨어를 서비스 형태로 제공하는 경우, 사용자에게 반드시 소스 코드를 공개할 의무가 있습니다.

## Dependencies & Build / 빌드 방법

One Support Android Manager is built using **Flutter** and **Rust**.

1. **Install Dependencies**:
   - Flutter SDK
   - Rust (Cargo)
   - Android NDK & SDK

2. **Build for Android**:
   ```bash
   # Build the Rust libraries for Android
   ./build_android_all.sh

   # Build the Flutter APK
   cd flutter
   flutter build apk --release
   ```

## File Structure

- **[libs/hbb_common](libs/hbb_common)**: Core utilities, codec, config.
- **[flutter](flutter)**: Flutter UI code for the Android application.
- **[build_android_all.sh](build_android_all.sh)**: Script to compile Rust code for Android targets.

---
*This project is not affiliated with the official RustDesk team but is developed using their open-source code under AGPL-3.0.*
