# 🚀 AICADataKeeper

[![KR](https://img.shields.io/badge/lang-한국어-red.svg)](README.md)
[![EN](https://img.shields.io/badge/lang-English-blue.svg)](README_eng.md)

> Author: Eungbean Lee  
> Email: eungbean@homilabs.ai  
> Organization: HOMI AI

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/eungbean/aica-nhn-environment-manager)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-brightgreen.svg)](https://github.com/eungbean/aica-nhn-environment-manager)

## 🤔 왜 이런 환경이 필요한가요?

NHN Cloud AI 서버는 두 가지 중요한 특성이 있습니다:

1. **SSD는 작고 휘발성**: 기본 디스크(SSD)는 200GB로 용량이 작고, 서버 재시작 시 **모든 데이터가 초기화**됩니다.
2. **대용량 데이터는 영구 저장소에**: 대신 서버에는 70TB(50TB + 20TB)의 대용량 HDD가 `/data`와 `/backup` 경로에 마운트되어 있어 영구적으로 데이터를 저장할 수 있습니다.

이런 환경에서는 사용자의 모든 작업 데이터를 영구 저장소에 보관하고, 공통으로 사용되는 패키지나 모델은 중앙에서 관리하는 것이 효율적입니다.

## ⚙️ 어떻게 작동하나요?

이 프로젝트는 다음과 같은 핵심 기능을 제공합니다:

- 🔗 **홈 디렉토리 연결**: 사용자의 홈 디렉토리(`/home/사용자명`)가 자동으로 영구 저장소(`/data/users/사용자명`)로 연결됩니다.
- 📦 **통합 패키지 관리**: Conda, Pip 등의 패키지가 중앙에서 관리되어 디스크 공간을 절약합니다.
- 🧠 **모델 캐시 공유**: AI 모델 파일을 공유하여 중복 다운로드를 방지합니다.
- 🤖 **자동화된 설정**: 사용자 추가와 환경 설정이 스크립트로 자동화되어 있습니다.

## 📂 디렉토리 구조

```
/data/
  ├── dataset/                  # 공유 데이터셋 저장소
  ├── code/                     # 공용 코드 저장소
  ├── models/                   # AI 모델 및 캐시 저장소
  │   ├── huggingface/          # HuggingFace 모델/캐시
  │   ├── torch/                # PyTorch 모델/캐시
  │   └── ...
  ├── users/                    # 사용자 홈 디렉토리
  │   ├── username/             # 개별 사용자 홈 디렉토리
  │   └── ...
  ├── cache/                    # 패키지 캐시 통합 관리
  │   ├── conda/                # conda 패키지 캐시
  │   ├── pip/                  # pip 패키지 캐시
  │   └── ...
  └── system/                   # 시스템 관리
      ├── scripts/              # 관리 스크립트
      ├── config/               # 환경 설정 파일
      └── apps/                 # 공유 애플리케이션
```

## 🚀 시작하기

### 📥 환경 관리자 설치하기

```bash
# 1. 시스템 디렉토리로 이동
cd /data

# 2. 저장소 클론
git clone https://github.com/eungbean/aica-nhn-environment-manager system

# 3. 스크립트 권한 설정
chmod +x /data/system/scripts/*.sh
```

## 📚 상황별 가이드

### 🔄 서버 재시작 후 환경 복구하기

서버가 재부팅된 후에는 SSD가 초기화되므로 기본 환경을 다시 설정해야 합니다:

```bash
# 1. root 계정으로 전환
sudo -i

# 2. 글로벌 환경 복구 (Miniconda 설치 + 환경변수 설정)
/data/system/scripts/setup_global_after_startup.sh

# 3. 로그아웃 후 다시 로그인하여 환경변수 적용
exit
```

이 과정은 다음 작업을 수행합니다:
- 공유 Miniconda가 없으면 설치
- 시스템 환경변수 설정 (`/etc/profile.d/global_envs.sh`)
- 캐시 디렉토리 권한 설정

### 👤 새 사용자 추가하기

신규 사용자를 추가하는 전체 과정입니다:

```bash
# 1. 리눅스 사용자 생성
sudo adduser <사용자명>

# 2. 그룹 추가 (필요한 경우)
sudo usermod -aG <그룹명> <사용자명>

# 3. 사용자 환경 설정 (홈 디렉토리 연결, Conda 설정, 권한 설정)
sudo /data/system/scripts/setup_new_user.sh <사용자명> <그룹명>

# 4. 테스트: 해당 사용자로 로그인
su - <사용자명>
# 또는 SSH로 접속
```

이 작업은 다음을 수행합니다:
- `/data/users/사용자명` 디렉토리 생성
- 홈 디렉토리를 `/data/users/사용자명`로 연결
- 사용자 Conda 환경 설정 (.condarc, 초기화 등)
- 올바른 파일 권한 설정

### 🔧 기존 사용자 환경 복구하기

서버 재시작 후 사용자 복구할 때:
사용자 환경에 문제가 생겼을 때 (심볼릭 링크 깨짐, 권한 문제 등):

```bash
# 1. 사용자 환경 전체 복구 (모든 설정 한번에)
sudo /data/system/scripts/setup_new_user.sh <사용자명> <그룹명>

# 또는 개별 작업 수행:

# 2a. 홈 디렉토리 링크만 복구
sudo /data/system/scripts/3_create_user_data_dir.sh <사용자명> <그룹명>

# 2b. Conda 환경만 복구
sudo /data/system/scripts/4_setup_user_conda.sh <사용자명> <그룹명>

# 2c. 파일 권한만 수정
sudo /data/system/scripts/5_fix_user_permission.sh <사용자명> <그룹명>
```

> **참고**: `setup_new_user.sh`는 새로운 사용자 설정뿐만 아니라 기존 사용자의 환경 복구에도 안전하게 사용할 수 있습니다. 기존 데이터는 보존됩니다.

### 🧹 시스템 유지보수 작업

정기적인 유지보수 작업을 위한 명령어들:

```bash
# 캐시 정리 (디스크 공간 확보)
sudo /data/system/scripts/clean_cache.sh --all

# 특정 캐시만 정리
sudo /data/system/scripts/clean_cache.sh --conda  # Conda 캐시
sudo /data/system/scripts/clean_cache.sh --pip    # Pip 패키지 캐시
sudo /data/system/scripts/clean_cache.sh --torch  # PyTorch 모델 캐시
sudo /data/system/scripts/clean_cache.sh --hf     # HuggingFace 캐시
```

## 🚶 사용자 가이드

### 🏁 처음 시작하기

서버에 로그인하면 홈 디렉토리는 자동으로 `/data/users/사용자명`을 가리키는 심볼릭 링크입니다. 즉, **모든 파일은 자동으로 영구 저장소에 저장**됩니다.

```bash
# 홈 디렉토리 확인
ls -la ~
# 결과: lrwxrwxrwx 1 사용자명 그룹명 xx xx xx xx /home/사용자명 -> /data/users/사용자명
```

### 🐍 Conda 환경 사용하기

시스템에는 공유 Miniconda가 설치되어 있으며, 다음과 같이 사용할 수 있습니다:

```bash
# 새 환경 생성
conda create -n myenv python=3.10

# 환경 활성화
conda activate myenv

# 환경 목록 확인
conda env list
```

사용자 환경은 자동으로 `/data/users/사용자명/.conda/envs`에 저장됩니다.

### 💾 캐시 파일 공유

패키지와 모델은 중앙 캐시에 저장되어 공유됩니다:

- Conda 패키지: `/data/cache/conda/pkgs`
- Pip 패키지: `/data/cache/pip`
- PyTorch 모델: `/data/models/torch`
- HuggingFace 모델: `/data/models/huggingface`

## 🔧 문제 해결

### ❓ 일반적인 문제

| 문제 | 해결 방법 |
|------|----------|
| 🔗 홈 디렉토리 심볼릭 링크 깨짐 | `sudo /data/system/scripts/3_create_user_data_dir.sh <사용자명> <그룹명>` |
| 🐍 Conda 환경 문제 | `sudo /data/system/scripts/4_setup_user_conda.sh <사용자명> <그룹명>` |
| 🔒 파일 권한 문제 | `sudo /data/system/scripts/5_fix_user_permission.sh <사용자명> <그룹명>` |
| 🌐 환경 변수 로드 안 됨 | `source /etc/profile.d/global_envs.sh` |

### 🔒 권한 문제

공유 디렉토리 권한 문제가 발생할 경우:

```bash
# 캐시 디렉토리 권한 수정
sudo chmod 777 /data/cache/conda/pkgs
sudo chmod 777 /data/cache/pip
```

## ⚠️ 주의사항

- 🚫 **SSD에 데이터 저장 금지**: 모든 중요 파일은 반드시 `/data/` 경로에 저장하세요. 기본 디스크(/)는 재시작 시 초기화됩니다.
- 🔍 **공유 리소스 존중**: 공유 캐시와 모델 디렉토리는 모든 사용자가 접근할 수 있으므로 중요한 정보를 저장하지 마세요.
- ⚙️ **사용자 환경 수정**: 개인 환경 설정은 홈 디렉토리 내의 `.bashrc`, `.zshrc` 등의 파일을 수정하세요.

## 📝 기술적 세부사항

이 프로젝트는 다음 스크립트들로 구성되어 있습니다:

1. `1_install_miniconda3_global.sh`: 글로벌 Miniconda 설치
2. `2_install_global_env.sh`: 시스템 글로벌 환경 변수 설정 (캐시 경로 등)
3. `3_create_user_data_dir.sh`: 사용자 데이터 디렉토리 및 홈 링크 생성
4. `4_setup_user_conda.sh`: 사용자별 Conda 환경 설정
5. `5_fix_user_permission.sh`: 사용자 데이터 디렉토리 권한 정리
6. `setup_new_user.sh`: 위 스크립트를 통합하여 사용자 환경 일괄 설정
7. `setup_global_after_startup.sh`: 시스템 재부팅 후 글로벌 환경 복구
8. `clean_cache.sh`: 캐시 정리 및 디스크 공간 확보

이 스크립트들은 `/data/system/scripts/` 경로에 있으며, 필요에 따라 개별적으로 실행할 수 있습니다.

## ⚠️ 시스템 위험성 및 대응 방안

이 설정 방식은 효율적이지만 몇 가지 잠재적 위험이 있습니다:

### 1. 단일 장애점 문제 🚨

- **위험**: `/data` 볼륨에 하드웨어 장애가 발생하면 모든 사용자 데이터가 손실될 수 있습니다.
- **대응**: 
  - 정기적으로 중요 데이터를 `/backup` 볼륨에 백업하세요.
  - `rsync -av /data/users/ /backup/users/` 명령으로 사용자 데이터 백업 가능

### 2. 권한 및 보안 취약점 🔓

- **위험**: 공유 캐시/모델 디렉토리는 여러 사용자가 접근 가능하므로 악성 코드나 패키지가 설치될 위험이 있습니다.
- **대응**:
  - 신뢰할 수 있는 소스의 패키지만 설치하세요.
  - 정기적으로 사용자 권한을 점검하세요: `sudo /data/system/scripts/5_fix_user_permission.sh <사용자명>`

### 3. 리소스 경합 문제 ⚡

- **위험**: 여러 사용자가 동시에 같은 물리적 디스크를 사용하면 I/O 병목현상이 발생할 수 있습니다.
- **대응**:
  - 대규모 파일 작업은 피크 시간을 피해 수행하세요.
  - `ionice` 명령을 사용하여 I/O 우선순위를 조정하세요.
  - `pip install` 대신 `uv pip install`을 사용하세요.

### 4. 공유 데이터 손상 위험 🗑️

- **위험**: 권한이 있는 사용자가 실수로 중요 공유 디렉토리를 삭제하면 모든 사용자에게 영향을 미칩니다.
- **대응**:
  - 중요 명령 실행 전 항상 경로를 확인하세요.
  - 공유 디렉토리는 관리자만 수정하도록 권한을 제한하세요.

### 5. 시스템 업그레이드 어려움 🔄

- **위험**: 공유 시스템(Miniconda 등)을 업그레이드하면 모든 사용자 환경에 영향을 줄 수 있습니다.
- **대응**:
  - 업그레이드 전 모든 사용자에게 통지하세요.
  - 테스트 환경에서 먼저 업그레이드를 검증하세요.

### 💡 안전한 운영을 위한 추천사항

- 정기적인 백업 수행 (주 1회 이상)
- 모든 사용자에게 공유 리소스 사용법 교육
- 디스크 사용량 및 성능 모니터링 도구 활용
- 주기적인 캐시 정리로 디스크 공간 확보

## 📞 추가 정보

자세한 내용은 호미에이아이 이응빈 (eungbean@homilabs.ai)에게 문의하세요.

## 🤝 기여하기

이 프로젝트는 오픈소스로 운영되며, 모든 기여와 제안을 환영합니다:

- 🐛 버그 리포트
- 💡 새로운 기능 제안
- 📝 문서 개선
- 🔧 코드 개선 및 리팩토링

모든 기여는 프로젝트의 품질과 안정성 향상에 도움이 됩니다.
문의사항이나 제안이 있으시다면 언제든 연락주세요.

