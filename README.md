# AICADataKeeper

> ⚠️ **주의**: 이 프로젝트는 참고용으로만 활용해주세요.  
> 보안 문제나 시스템 오류에 대해서는 책임지지 않습니다.

[![KR](https://img.shields.io/badge/lang-한국어-red.svg)](README.md)
[![EN](https://img.shields.io/badge/lang-English-blue.svg)](README_eng.md)

> **Author**: Eungbean Lee (eungbean@homilabs.ai)  
> **Organization**: HOMI AI Inc.
> **Version**: 2.0.0

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## Overview

NHN Cloud AI 서버를 위한 **다중 사용자 GPU 환경 관리 시스템**입니다.

### 핵심 문제

| 스토리지 | 용량 | 특징 |
|---------|------|------|
| **SSD** | 200GB | 빠름, **재부팅 시 초기화** ⚠️ |
| **HDD (NFS)** | 70TB | 느림, **영구 저장** ✅ |

**문제점**: SSD의 `/home` 디렉토리는 재부팅 시 모두 초기화됨

### 해결: 하이브리드 홈 아키텍처 (v2)

**핵심 아이디어**: SSD에 홈 디렉토리를 유지하되, 영구 데이터는 NFS로 심볼릭 링크

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  SSD (빠름, 휘발성)                    NFS/HDD (느림, 영구)                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  /home/alice/                          /data/                               │
│  ├── .cache/         ← 빠른 I/O        ├── users/alice/                     │
│  │   ├── pip/                          │   ├── dotfiles/    ← 설정 원본     │
│  │   ├── uv/                           │   │   ├── .bashrc                  │
│  │   └── npm/                          │   │   ├── .zshrc                   │
│  │                                     │   │   ├── .condarc                 │
│  ├── .bashrc ──────────────────────────│───│───┴── .ssh/                    │
│  ├── .zshrc  ─────── 심볼릭 링크 ──────│───│                                │
│  ├── .condarc ─────────────────────────│───┘                                │
│  ├── .ssh/ ────────────────────────────│                                    │
│  │                                     │   ├── conda/envs/  ← Conda 환경    │
│  └── data/ ────────────────────────────┴───┴── projects/    ← 프로젝트      │
│                                                                             │
│                                        ├── cache/conda/pkgs/ ← 공유 캐시    │
│                                        ├── models/           ← AI 모델      │
│                                        │   ├── huggingface/                 │
│                                        │   └── torch/                       │
│                                        └── apps/miniconda3/  ← 공유 앱      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**심볼릭 링크 구조**:
| 위치 (SSD) | → | 대상 (NFS) |
|------------|---|-----------|
| `~/.bashrc` | → | `~/data/dotfiles/.bashrc` |
| `~/.zshrc` | → | `~/data/dotfiles/.zshrc` |
| `~/.condarc` | → | `~/data/dotfiles/.condarc` |
| `~/.ssh/` | → | `~/data/dotfiles/.ssh/` |
| `~/data/` | → | `/data/users/<username>/` |

**장점**:
| 항목 | 저장 위치 | 이유 |
|------|----------|------|
| pip/uv/npm 캐시 | SSD (`~/.cache/`) | 작은 파일 많음, 빠른 I/O 필요 |
| 설정 파일 (dotfiles) | NFS (심볼릭 링크) | 재부팅 후 복구 필요 |
| Conda 환경, 프로젝트 | NFS (`~/data/`) | 대용량, 영구 저장 |
| AI 모델 | NFS (`/data/models/`) | 대용량, 전체 공유 |

### 캐시 전략

| 캐시 유형 | 저장 위치 | 공유 방식 |
|-----------|-----------|-----------|
| **AI 모델** (HuggingFace, PyTorch) | `/data/models/` | 전체 공유 (대용량) |
| **Conda 패키지** | `/data/cache/conda/` | 전체 공유 |
| **pip/uv/npm** | `~/.cache/` (SSD) | 개인별 (빠른 I/O) |

### 권한 관리 전략

```bash
# ❌ 절대 사용 금지
chmod 777 /data/shared

# ✅ setgid + umask 002 조합
chmod 2775 /data/shared    # setgid: 새 파일이 그룹 상속
umask 002                   # 새 파일 권한: 664 (rw-rw-r--)
```

| 권한 | 설명 |
|------|------|
| `2775` | setgid 비트 + rwxrwxr-x |
| `umask 002` | 그룹 쓰기 권한 허용 |

### 자동 복구 전략

```
재부팅 후 자동 실행 (systemd: aica-recovery.service)
    │
    ├── 1. Miniconda 설치/확인
    ├── 2. 환경 변수 복원 (/etc/profile.d/)
    ├── 3. 캐시 디렉토리 권한 복원
    └── 4. 등록된 사용자별 복구
        ├── v2: SSD 홈 디렉토리 생성 + dotfile 심볼릭 링크
        └── v1: 전체 홈 심볼릭 링크 (레거시)
```

### 기술 스택

| 구분 | 기술 |
|------|------|
| **스크립트** | Bash |
| **TUI** | dialog |
| **Init** | systemd (자동 복구 서비스) |
| **패키지 관리** | Conda + uv (pip 대체, 10-100배 빠름) |
| **권한 관리** | setgid + umask 002 (NFS v3 호환) |

### 대상 환경

- **OS**: Ubuntu / CentOS (Linux)
- **규모**: 4-10명 팀 (GPU 자원 공유)
- **용도**: AI/ML 연구 및 개발

---

## 메뉴 구조

AICADataKeeper는 **관리자 모드**와 **사용자 모드** 두 가지로 동작합니다.

### 관리자 메뉴 (`sudo ./main.sh`)

```
┌─────────────── 관리자 메뉴 ───────────────┐
│ 1. 초기 설정                              │
│ 2. 설정 테스트                            │
│ 3. 사용자 추가                            │
│ 4. 사용자 삭제                            │
│ 5. 글로벌 패키지 설치                     │
│ 6. 자동 복구                              │
│ q. 종료                                   │
└───────────────────────────────────────────┘
```

### 사용자 메뉴 (`./main.sh`)

```
┌─────────────── 사용자 메뉴 ───────────────┐
│ 1. 환경 정보                              │
│ 2. 디스크 사용량                          │
│ 3. 캐시 정리                              │
│ 4. Conda 가이드                           │
│ 5. 도움말                                 │
│ q. 종료                                   │
└───────────────────────────────────────────┘
```

---

## 빠른 시작

### 1. 패키지 설치 및 저장소 클론

```bash
sudo apt install dialog 

sudo cd /data
sudo git clone https://github.com/eungbean/AICADataKeeper
sudo cd AICADataKeeper
sudo chmod +x scripts/*.sh main.sh
```

### 2. 초기 설정 위자드 실행

```bash
sudo ./main.sh
# → "1. 초기 설정" 선택
```

### 3. 다음 단계 실행 (위자드 완료 후)

```bash
# 그룹 멤버십 적용
newgrp $GROUP_NAME

# umask 설정 (필수!)
echo "umask 002" >> ~/.bashrc
source ~/.bashrc

# 사용자 추가
sudo ./main.sh
# → "3. 사용자 추가" 선택
```

---

## 초기 설정 위자드 상세

`sudo ./main.sh` → "1. 초기 설정" 선택 시 아래 단계가 순차적으로 실행됩니다.

![](docs/0_main.png)

![](docs/1_menu_setup.png)

### 1단계: GROUP - 그룹 생성

**목적**: 모든 사용자가 공유할 Linux 그룹 생성

**수행 작업**:
```bash
groupadd <그룹명>           # 예: gpu-users
```

**결과**:
- 새 그룹이 시스템에 등록됨
- 이후 모든 사용자가 이 그룹에 추가됨

---

### 2단계: STORAGE - 저장소 권한 할당

**목적**: `/data` 및 `/backup` 디렉토리에 그룹 공유 권한 설정

**수행 작업**:
```bash
chown root:<그룹> /data        # 예: chown root:gpu-users /data
chmod 2775 /data               # setgid + rwxrwxr-x

chown root:<그룹> /backup      # /backup이 있는 경우
chmod 2775 /backup
```

**결과**:
| 권한 | 의미 |
|------|------|
| `2` (setgid) | 새 파일/폴더가 자동으로 그룹 소유권 상속 |
| `775` | 소유자/그룹: 읽기+쓰기+실행, 기타: 읽기+실행 |

> `/backup` 디렉토리가 없으면 자동으로 건너뜁니다.

---

### 3단계: FOLDERS - 폴더 구조 생성

**목적**: 필수 디렉토리 구조 생성 (setgid 권한 적용)

**수행 작업**:
```bash
mkdir -p /data/users                      # 사용자 홈 디렉토리
mkdir -p /data/models/huggingface/hub     # HuggingFace 모델 공유
mkdir -p /data/models/huggingface/datasets
mkdir -p /data/models/torch               # PyTorch 모델 공유
mkdir -p /data/cache/conda/pkgs           # Conda 패키지 공유
mkdir -p /data/apps                       # 공유 앱 (Miniconda 등)
mkdir -p /data/config                     # 설정 파일
mkdir -p /data/dataset                    # 공유 데이터셋
mkdir -p /data/code                       # 공유 코드
```

모든 디렉토리에 `chmod 2775` (setgid) 및 그룹 소유권 적용.

---

### 4단계: ENV - 개발환경 설정

**목적**: Python 패키지 관리자 및 하이브리드 캐시 설정

#### 하이브리드 캐시 전략

| 캐시 유형 | 공유 방식 | 이유 |
|-----------|-----------|------|
| **AI 모델** (HuggingFace, PyTorch) | 공유 `/data/models/` | 대용량(5-50GB), 읽기전용, 공유 이점 큼 |
| **Conda 패키지** | 공유 `/data/cache/conda/pkgs/` | Conda가 공유 잘 지원 |
| **pip/uv/npm 캐시** | 개인 `~/.cache/` | 권한 충돌 방지, 이미 HDD에 있음 |

#### 4-1. Miniconda 설치

```bash
/data/apps/miniconda3/              # 공유 Miniconda 설치
/data/cache/conda/pkgs/             # 공유 패키지 캐시 (2775)
```

#### 4-2. uv 설치

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
mv ~/.local/bin/uv /usr/local/bin/uv
```

> uv 캐시는 개인 `~/.cache/uv` 사용 (이미 `/data/users/`에 있음)

**사용법**:
```bash
uv pip install numpy pandas torch   # pip 대신 사용 (10-100배 빠름)
```

#### 4-3. 환경 변수 설정

**전역 환경 변수 파일**: `/etc/profile.d/global_envs.sh`

| 변수 | 경로 | 용도 |
|------|------|------|
| `HF_HOME` | `/data/models/huggingface` | HuggingFace 루트 |
| `HF_HUB_CACHE` | `/data/models/huggingface/hub` | HuggingFace 모델 캐시 |
| `HF_DATASETS_CACHE` | `/data/models/huggingface/datasets` | HuggingFace 데이터셋 |
| `TORCH_HOME` | `/data/models/torch` | PyTorch 모델 캐시 |
| `COMFYUI_HOME` | `/data/models/comfyui` | ComfyUI 모델 캐시 |
| `FLUX_HOME` | `/data/models/flux` | Flux 모델 캐시 |
| `CONDA_PKGS_DIRS` | `/data/cache/conda/pkgs` | Conda 패키지 캐시 |
| `CONDA_ENVS_PATH` | `$HOME/conda/envs` | Conda 가상환경 (개인) |

> pip, uv, npm, yarn 캐시는 설정하지 않음 → 기본 `~/.cache/` 사용

**결과**:
- AI 모델: 모든 사용자가 공유 (중복 다운로드 방지)
- 패키지 캐시: 개인별 격리 (권한 충돌 방지)

---

### 5단계: SUDOERS - sudoers 설정

**목적**: 일반 사용자가 특정 관리 명령어를 비밀번호 없이 실행 가능하게 설정

**수행 작업**:
```bash
# /etc/sudoers.d/aica-datakeeper 생성
%<그룹> ALL=(ALL) NOPASSWD: /data/AICADataKeeper/scripts/ops-clean-cache.sh
%<그룹> ALL=(ALL) NOPASSWD: /usr/bin/df
```

**결과**:
- 그룹 멤버가 캐시 정리 스크립트 실행 가능
- 디스크 사용량 확인 가능

### 다음 스텝

```bash
# 그룹 멤버십 적용
newgrp $GROUP_NAME

# umask 설정 (필수!)
echo "umask 002" >> ~/.bashrc
source ~/.bashrc

# 사용자 추가
sudo ./main.sh
# → "3. 사용자 추가" 선택
```

---

## 설정 테스트

초기 설정이 제대로 완료되었는지 검증합니다.

```bash
sudo ./main.sh
# → "2. 설정 테스트" 선택
```

### 검증 항목

| 단계 | 검증 내용 | 통과 조건 |
|------|----------|----------|
| **1/5** | 그룹 | 그룹 존재, 멤버 1명 이상 |
| **2/5** | 저장소 | /data 권한 2775, 그룹 소유권 |
| **3/5** | 폴더 | users/, models/, cache/ 존재 + 2775 |
| **4/5** | 환경 | global_envs.sh, conda 캐시, HF 캐시 2775 |
| **5/5** | sudoers | /etc/sudoers.d/aica-datakeeper 존재 + 문법 정상 |

### 결과 해석

```
✓ 통과 - 정상
✗ 실패 - 수정 필요 (초기 설정 재실행)
⊘ 건너뜀 - 선택 항목 (예: 관리자 계정)
```

---

## 사용자 추가

초기 설정 완료 후, 새 사용자를 추가하려면:

```bash
sudo ./main.sh
# → "3. 사용자 추가" 선택
```

### 사용자 추가 과정

| 단계 | 작업 | 설명 |
|------|------|------|
| **1/6** | 사용자 생성 | `adduser --disabled-password` |
| **2/6** | 그룹 추가 | 선택한 그룹에 `usermod -aG` (다중 선택 가능) |
| **3/6** | SSH 키 설정 | 공개키 등록 또는 새 키 쌍 생성 |
| **4/6** | 쉘 선택 | bash / zsh-minimal / zsh-full / 건너뛰기 |
| **5/6** | 환경 설정 | 홈 디렉토리, 쉘, Conda 설정 |
| **6/6** | 완료 | 결과 요약 및 다음 단계 안내 |

### 자동 수행 작업

```
[1/6] 사용자 생성
  ✓ Linux 사용자 생성 (adduser)

[2/6] 그룹 추가
  ✓ 선택한 그룹에 추가 (usermod -aG)

[3/6] SSH 키 설정
  → 공개키 등록 / 새 키 생성 / 건너뛰기

[4/6] 쉘 선택
  → bash / zsh-minimal / zsh-full / 건너뛰기

[5/6] 환경 설정
  ✓ 홈 디렉토리 심볼릭 링크 (/home/user → /data/users/user)
  ✓ .hpcrc 복사 (alias, umask 설정)
  ✓ 쉘 환경 설정 (bash/zsh, oh-my-zsh)
  ✓ Conda 환경 설정 (.condarc, conda init)
  ✓ 권한 설정 (chown)

[6/6] 완료
  ✓ 사용자 설정 완료
```

### 쉘 옵션

| 옵션 | 설명 |
|------|------|
| **bash** | Bash 쉘 (기본) |
| **zsh-minimal** | Zsh + oh-my-zsh (minimal plugins) |
| **zsh-full** | Zsh + oh-my-zsh + autosuggestions + syntax-highlighting |
| **건너뛰기** | bash로 설정 |

### SSH 키 옵션

| 옵션 | 설명 |
|------|------|
| **공개키 붙여넣기** | 사용자의 기존 공개키를 `~/.ssh/authorized_keys`에 등록 |
| **새 키 쌍 생성** | ed25519/rsa/ecdsa 키 생성, 개인키를 사용자에게 전달 |
| **건너뛰기** | 나중에 설정 |

### 환경 변수

사용자 추가 시 글로벌 환경 변수가 자동 적용됩니다:

| 변수 | 경로 | 설명 |
|------|------|------|
| `HF_HOME` | `/data/models/huggingface` | HuggingFace 모델 공유 |
| `TORCH_HOME` | `/data/models/torch` | PyTorch 모델 공유 |
| `CONDA_PKGS_DIRS` | `/data/cache/conda/pkgs` | Conda 패키지 공유 |

> 환경 변수는 `/etc/profile.d/global_envs.sh`에서 로드되어 모든 사용자에게 적용됩니다.

### 사용자 전달 사항

사용자 추가 완료 후 아래 정보를 사용자에게 전달하세요:

```bash
# 1. 초기 비밀번호: 0000
#    ※ 첫 로그인 시 새 비밀번호로 변경 필수
#    ※ 비밀번호 변경 후 자동으로 접속 종료됨 (재접속 필요)

# 2. SSH 첫 접속
ssh username@<서버IP>
# Old Password: 0000
# New Password: (새 비밀번호 입력)
# Retype New Password: (새 비밀번호 재입력)
# → 비밀번호 변경 완료 후 자동 로그아웃

# 3. 비밀번호 변경 후 재접속
ssh username@<서버IP>
# Password: (새 비밀번호)

# 4. 사용자 정보 등록 (선택)
chfn

# 5. 환경 설정 적용 (재로그인 또는 아래 실행)
source ~/.bashrc
```

> **참고**: 초기 비밀번호는 `0000`이며, 첫 로그인 시 변경이 강제됩니다. 변경 후 자동으로 접속이 종료되므로 재접속하세요.

> **참고**: `umask 002`는 `.hpcrc`에 설정되어 있고, `.bashrc`에서 자동으로 로드됩니다.

---

## 글로벌 패키지 설치

모든 사용자가 공유하는 개발 도구를 글로벌로 설치합니다.

```bash
sudo ./main.sh
# → "5. 글로벌 패키지 설치" 선택
```

### 설치 가능한 패키지

| 패키지 | 설명 |
|--------|------|
| **oh-my-opencode** | AI 코딩 어시스턴트 (bun + opencode + oh-my-opencode 플러그인) |
| **CLI 도구** | fzf, ripgrep, fd, bat |
| **neovim** | 현대적 vim 에디터 |
| **btop** | 시스템 모니터 |
| **nvtop** | GPU 모니터 |
| **ruff** | 빠른 Python 린터 |

> **참고**: zsh는 사용자 추가 시 개인별로 설정 가능합니다 (4단계: 쉘 선택).

**oh-my-opencode 설치 과정**:
1. bun 설치 (JavaScript 런타임)
2. opencode CLI 설치 (Claude Code CLI)
3. oh-my-opencode 플러그인 설치
4. 사용자별 인증 설정: `opencode auth login`

**설치 위치**:
- 바이너리: `/usr/local/bin/`
- opencode: `~/.opencode/bin/opencode`
- 설정 파일: `~/.config/opencode/opencode.json`
- 플러그인: `~/.config/opencode/oh-my-opencode.json`

---

## 사용자 삭제

```bash
sudo ./main.sh
# → "4. 사용자 삭제" 선택
```

### 삭제 과정

1. 삭제할 사용자 선택 (목록에서)
2. **경고 메시지 확인**: 사용자 정보, 데이터 크기, 소속 그룹 표시
3. 홈 디렉토리 삭제 여부 선택
4. **최종 확인**: 사용자명 직접 입력 (오타 방지)
5. 삭제 수행

### 삭제되는 항목

| 항목 | 설명 |
|------|------|
| Linux 사용자 | `userdel <username>` |
| 자동 복구 목록 | `/data/config/users.txt`에서 제거 |
| 홈 심볼릭 링크 | `/home/<username>` 제거 |
| 홈 디렉토리 (선택) | `/data/users/<username>` 삭제 |

> ⚠️ **주의**: 홈 디렉토리 삭제는 되돌릴 수 없습니다!

---

## 자동 복구

재부팅 후 환경을 자동으로 복원하는 systemd 서비스를 관리합니다.

```bash
sudo ./main.sh
# → "6. 자동 복구" 선택
```

### 관리 옵션

| 옵션 | 설명 |
|------|------|
| **활성화** | systemd 서비스 시작 + 부팅 시 자동 실행 |
| **비활성화** | systemd 서비스 중지 + 자동 실행 해제 |
| **상태 확인** | 서비스 실행 상태 및 최근 로그 확인 |
| **수동 실행** | 즉시 복구 스크립트 실행 (테스트용) |

### 복구 과정

재부팅 후 `aica-recovery.service`가 자동 실행:

```
1. Miniconda 설치/확인 (/data/apps/miniconda3)
2. 환경 변수 복원 (/etc/profile.d/global_envs.sh)
3. 캐시 디렉토리 권한 복원 (2775)
4. 등록된 사용자별:
   - 홈 디렉토리 심볼릭 링크 복원
   - Conda 설정 복원
   - 파일 권한 수정
```

### 서비스 파일 위치

- 서비스 파일: `/etc/systemd/system/aica-recovery.service`
- 복구 스크립트: `/data/AICADataKeeper/scripts/ops-recovery.sh`
- 사용자 목록: `/data/config/users.txt`

---

## 디렉토리 구조

```
/data/
├── users/                    # 사용자 홈 디렉토리
│   ├── ubuntu/               # /home/ubuntu → /data/users/ubuntu
│   └── alice/                # /home/alice → /data/users/alice
├── cache/                    # 공유 캐시 (Conda만)
│   └── conda/pkgs/           # Conda 패키지 (공유)
├── models/                   # AI 모델 캐시 (공유)
│   ├── torch/                # PyTorch Hub 모델
│   └── huggingface/          # HuggingFace 모델
│       ├── hub/              # 모델 파일
│       └── datasets/         # 데이터셋 캐시
├── apps/                     # 공유 애플리케이션
│   └── miniconda3/           # Miniconda 설치 경로
├── config/                   # 설정 파일
│   ├── global_env.sh         # 전역 환경 변수
│   └── users.txt             # 자동 복구 사용자 목록
├── dataset/                  # 공유 데이터셋
├── code/                     # 공유 코드
└── AICADataKeeper/           # 관리 스크립트
    ├── main.sh               # 통합 위자드
    └── scripts/              # 개별 스크립트
```

---

## 일반 사용자 가이드

일반 사용자(sudo 권한 없음)는 `./main.sh`로 사용자 메뉴에 접근합니다.

```bash
./main.sh
```

### 1. 환경 정보

현재 사용자의 환경 설정을 확인합니다.

**표시 내용**:
- 홈 디렉토리: 심볼릭 링크 상태 (/home/user → /data/users/user)
- 환경 변수: HF_HOME, TORCH_HOME, CONDA_PKGS_DIRS 등
- Conda: 버전, 활성 환경, 내 환경 목록

**활용**: 환경 변수가 제대로 설정되었는지 확인

---

### 2. 디스크 사용량

`/data` 파티션 및 캐시 사용량 확인

**표시 내용**:
- /data 전체 디스크 사용량 (`df -h`)
- 캐시별 사용량 (conda, models)
- 내 홈 디렉토리 크기

**활용**: 디스크 공간 부족 시 어느 캐시가 큰지 파악

---

### 3. 캐시 정리

공유 캐시를 정리합니다 (다른 사용자에게 영향 줄 수 있음).

**정리 옵션**:
- Conda: `conda clean --all`
- Pip: pip 캐시 삭제
- PyTorch: torch 모델 캐시 삭제
- HuggingFace: HF 모델/데이터셋 캐시 삭제
- 전체: 모든 캐시 삭제

> ⚠️ **주의**: 공유 캐시 삭제 시 다른 사용자도 재다운로드 필요

---

### 4. Conda 가이드

Conda 환경 관리 명령어 안내

**기본 명령어**:
```bash
# 새 환경 생성
conda create -n myenv python=3.10
conda activate myenv

# 패키지 설치
conda install numpy pandas scikit-learn

# 환경 목록 확인
conda env list

# 환경 삭제
conda env remove -n myenv
```

---

### 5. 도움말

주요 명령어 및 디렉토리 경로 참고

**표시 내용**:
- Conda 기본 명령어
- 패키지 설치 (pip, uv)
- 디스크 확인
- 캐시 위치

---

## 추가 사용 팁

### uv로 패키지 설치 (pip보다 10-100배 빠름)

```bash
# uv 사용 (권장)
uv pip install torch torchvision transformers

# 또는 pip 사용
pip install torch torchvision transformers
```

### AI 모델 다운로드 시 자동 공유

```python
# HuggingFace 모델 - 자동으로 /data/models/huggingface/에 저장
from transformers import AutoModel
model = AutoModel.from_pretrained("bert-base-uncased")

# PyTorch Hub 모델 - 자동으로 /data/models/torch/에 저장
import torch
model = torch.hub.load('pytorch/vision', 'resnet50')
```

다른 사용자가 같은 모델을 사용하면 재다운로드 없이 공유 캐시 사용.

---

## 중요 사항

### umask 002 설정

**신규 사용자**: main.sh로 추가된 사용자는 자동 설정됩니다 (`.hpcrc` → `.bashrc`에서 로드).

**기존 사용자/관리자**: 수동 설정이 필요합니다:
```bash
echo "umask 002" >> ~/.bashrc
source ~/.bashrc
```

| 설정 | 새 파일 권한 | 그룹 쓰기 |
|------|-------------|----------|
| 기본 umask (022) | 644 (rw-r--r--) | ❌ |
| **umask 002** | 664 (rw-rw-r--) | ✅ |

### 주의사항

- **SSD에 데이터 저장 금지**: 모든 중요 파일은 `/data/`에 저장
- **공유 리소스 존중**: 캐시/모델은 모든 사용자가 접근 가능
- **대용량 모델 다운로드**: 다른 사용자에게 알리고 진행

---

## 문의

- **버그 리포트**: [GitHub Issues](https://github.com/eungbean/AICADataKeeper/issues)
- **문의**: eungbean@homilabs.ai
- **라이선스**: MIT License
