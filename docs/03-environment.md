# 03. 환경 설정 가이드

## 개요

Conda, Pip, uv 등 패키지 관리자 사용법과 환경 변수 설정을 안내합니다.

## 환경 변수

AICADataKeeper는 공유 캐시와 모델 저장소를 위한 환경 변수를 자동으로 설정합니다.

### 전역 환경 변수

`/etc/profile.d/global_envs.sh`에 정의된 환경 변수:

```bash
# 캐시 경로
export SYSTEM_CACHE_DIR="/data/cache"
export PIP_CACHE_DIR="/data/cache/pip"
export CONDA_PKGS_DIRS="/data/cache/conda/pkgs"
export UV_CACHE_DIR="/data/cache/uv"
export NPM_CONFIG_CACHE="/data/cache/npm"
export YARN_CACHE_FOLDER="/data/cache/yarn"

# AI 모델 경로
export TORCH_HOME="/data/models/torch"
export HF_HOME="/data/models/huggingface"
export TRANSFORMERS_CACHE="/data/models/huggingface/transformers"
export HF_DATASETS_CACHE="/data/models/huggingface/datasets"
```

### 환경 변수 확인

```bash
# 모든 환경 변수 확인
source /etc/profile.d/global_envs.sh
env | grep -E "(CACHE|HOME|CONDA)"

# 개별 확인
echo $PIP_CACHE_DIR
echo $CONDA_PKGS_DIRS
echo $TORCH_HOME
```

### 사용자별 환경 변수 오버라이드

필요한 경우 `~/.bashrc`에서 환경 변수를 오버라이드할 수 있습니다:

```bash
# ~/.bashrc에 추가
export PIP_CACHE_DIR="$HOME/.cache/pip"  # 개인 캐시 사용
```

## Conda 환경 관리

### 기본 사용법

```bash
# 새 환경 생성
conda create -n myenv python=3.10

# 환경 활성화
conda activate myenv

# 환경 비활성화
conda deactivate

# 환경 목록 확인
conda env list

# 환경 삭제
conda env remove -n myenv
```

### 패키지 설치

```bash
# Conda로 패키지 설치
conda install numpy pandas matplotlib

# 특정 버전 설치
conda install pytorch=2.0.0

# 여러 패키지 동시 설치
conda install numpy pandas scikit-learn
```

### 환경 내보내기/가져오기

```bash
# 환경 내보내기
conda env export > environment.yml

# 환경 가져오기
conda env create -f environment.yml
```

### Conda 설정

사용자별 Conda 설정은 `~/.condarc`에 저장됩니다:

```yaml
channels:
  - defaults
  - conda-forge

pkgs_dirs:
  - /data/cache/conda/pkgs

envs_dirs:
  - ~/.conda/envs
```

## Pip 패키지 관리

### 기본 사용법

```bash
# 패키지 설치
pip install numpy

# 특정 버전 설치
pip install torch==2.0.0

# requirements.txt로 설치
pip install -r requirements.txt

# 패키지 업그레이드
pip install --upgrade numpy

# 패키지 제거
pip uninstall numpy
```

### 캐시 관리

```bash
# 캐시 위치 확인
pip cache dir

# 캐시 정보 확인
pip cache info

# 캐시 정리 (관리자 권한 필요)
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --pip
```

### pip 설정

시스템 전역 설정은 `/etc/pip.conf`에 저장됩니다:

```ini
[global]
cache-dir = /data/cache/pip
```

사용자별 설정은 `~/.config/pip/pip.conf`에서 오버라이드할 수 있습니다.

## uv 패키지 관리자

`uv`는 Rust로 작성된 초고속 Python 패키지 관리자입니다 (pip보다 10-100배 빠름).

### 설치

```bash
sudo /data/AICADataKeeper/scripts/install-uv.sh
```

### 기본 사용법

```bash
# pip 명령어를 uv로 대체
uv pip install numpy pandas torch

# requirements.txt로 설치
uv pip install -r requirements.txt

# 패키지 업그레이드
uv pip install --upgrade numpy

# 패키지 제거
uv pip uninstall numpy
```

### Conda 환경과 함께 사용

```bash
# Conda 환경 활성화
conda activate myenv

# uv로 패키지 설치 (훨씬 빠름)
uv pip install transformers datasets
```

### 캐시 관리

uv 캐시는 `/data/cache/uv`에 저장됩니다:

```bash
# 캐시 위치 확인
echo $UV_CACHE_DIR

# 캐시 정리 (관리자 권한 필요)
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --uv
```

## 가상 환경 관리

### venv (Python 기본)

```bash
# 가상 환경 생성
python -m venv myenv

# 활성화 (Linux/Mac)
source myenv/bin/activate

# 비활성화
deactivate
```

### virtualenv

```bash
# 설치
pip install virtualenv

# 가상 환경 생성
virtualenv myenv

# 활성화
source myenv/bin/activate
```

## AI 모델 캐시 관리

### PyTorch Hub

```bash
# 모델 다운로드 (자동으로 /data/models/torch에 저장)
import torch
model = torch.hub.load('pytorch/vision:v0.10.0', 'resnet18', pretrained=True)

# 캐시 위치 확인
echo $TORCH_HOME
```

### HuggingFace

```bash
# 모델 다운로드 (자동으로 /data/models/huggingface에 저장)
from transformers import AutoModel
model = AutoModel.from_pretrained('bert-base-uncased')

# 캐시 위치 확인
echo $HF_HOME
echo $TRANSFORMERS_CACHE
```

### 캐시 정리

```bash
# PyTorch 캐시 정리
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --torch

# HuggingFace 캐시 정리
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --hf

# 모든 캐시 정리
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --all
```

## 캐시 전략

AICADataKeeper는 **Config Files + Environment Variables** 하이브리드 전략을 사용합니다.

### 시스템 설정 파일

- `/etc/conda/.condarc`: Conda 패키지 캐시 경로
- `/etc/pip.conf`: Pip 패키지 캐시 경로
- `/etc/npmrc`: NPM 캐시 경로

이 설정 파일들은 non-login shell(cron, systemd 등)에서도 동작합니다.

### 환경 변수 (Override 용도)

사용자별 환경변수로 캐시 경로를 override할 수 있습니다:

```bash
# ~/.bashrc에 추가
export PIP_CACHE_DIR="$HOME/.cache/pip"
export CONDA_PKGS_DIRS="$HOME/.conda/pkgs"
```

## 권한 모델

### setgid + umask 조합

AICADataKeeper는 `chmod 777` 대신 **setgid + umask 002** 조합을 사용합니다.

```bash
# setgid 확인
ls -ld /data/cache/pip
# 결과: drwxrwsr-x (2775, 's'가 setgid 표시)

# umask 확인
umask
# 결과: 0002 (권장)

# umask 설정 (필수)
echo "umask 002" >> ~/.bashrc
source ~/.bashrc
```

### 권한 문제 해결

```bash
# 공유 디렉토리 권한 재설정
sudo /data/AICADataKeeper/scripts/system-permissions.sh

# 사용자 데이터 권한 재설정
sudo /data/AICADataKeeper/scripts/user-fix-permissions.sh alice gpu-users
```

## 모범 사례

1. **Conda 환경 사용 권장**: 패키지 충돌 방지
2. **uv 사용 권장**: 빠른 패키지 설치
3. **requirements.txt 관리**: 재현 가능한 환경 구축
4. **umask 002 설정**: 그룹 쓰기 권한 보장
5. **정기적인 캐시 정리**: 디스크 공간 확보
6. **큰 모델 다운로드 전 공지**: 다른 사용자 배려

## 주의사항

- **공유 캐시**: 모든 사용자가 접근 가능하므로 신뢰할 수 있는 소스에서만 패키지 설치
- **디스크 공간**: 큰 패키지/모델 설치 전 디스크 공간 확인
- **동시 설치**: 여러 사용자가 동시에 같은 패키지를 설치하면 충돌 가능 (일반적으로 안전하지만 주의)

## 문제 해결

### Conda 환경 활성화 안 됨

```bash
# Conda 재초기화
conda init bash
source ~/.bashrc
```

### 패키지 설치 Permission Denied

```bash
# Conda 환경 내에서 설치
conda activate myenv
pip install package-name

# umask 확인
umask  # 0002여야 함
```

### 캐시 디렉토리 접근 불가

```bash
# 권한 재설정
sudo /data/AICADataKeeper/scripts/system-permissions.sh
```

## 다음 단계

- [04. 유지보수](04-maintenance.md): 정기 유지보수 작업
- [05. 문제 해결](05-troubleshooting.md): 일반적인 문제 해결 방법
