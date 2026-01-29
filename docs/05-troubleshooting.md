# 05. 문제 해결 가이드

## 개요

AICADataKeeper 사용 중 발생할 수 있는 일반적인 문제와 해결 방법을 안내합니다.

## 일반적인 문제

### 홈 디렉토리 심볼릭 링크 깨짐

**증상:**
```bash
ls -la ~
# 결과: /home/alice -> /data/users/alice (빨간색 또는 깨진 링크)
```

**원인:**
- 서버 재시작 후 심볼릭 링크가 복구되지 않음
- 수동으로 홈 디렉토리를 삭제했을 때

**해결:**
```bash
# 홈 디렉토리 링크 복구
sudo /data/AICADataKeeper/scripts/user-create-home.sh alice gpu-users

# 확인
ls -la /home/alice
```

### Conda 환경 활성화 안 됨

**증상:**
```bash
conda activate myenv
# 결과: CommandNotFoundError: Your shell has not been properly configured
```

**원인:**
- Conda 초기화가 되지 않음
- `.bashrc` 또는 `.zshrc`에 conda init 코드가 없음

**해결:**
```bash
# Conda 재초기화
conda init bash  # 또는 conda init zsh

# 쉘 재시작
source ~/.bashrc  # 또는 source ~/.zshrc

# 확인
conda --version
```

### 패키지 설치 Permission Denied

**증상:**
```bash
pip install numpy
# 결과: PermissionError: [Errno 13] Permission denied
```

**원인:**
- Conda 환경 외부에서 시스템 Python에 설치 시도
- umask 설정이 잘못됨

**해결:**
```bash
# 방법 1: Conda 환경 내에서 설치
conda activate myenv
pip install numpy

# 방법 2: umask 확인 및 설정
umask  # 0002여야 함
echo "umask 002" >> ~/.bashrc
source ~/.bashrc

# 방법 3: 사용자 권한 재설정
sudo /data/AICADataKeeper/scripts/user-fix-permissions.sh alice gpu-users
```

### 환경 변수 로드 안 됨

**증상:**
```bash
echo $PIP_CACHE_DIR
# 결과: (빈 출력)
```

**원인:**
- `/etc/profile.d/global_envs.sh`가 로드되지 않음
- Non-login shell 사용

**해결:**
```bash
# 수동으로 환경 변수 로드
source /etc/profile.d/global_envs.sh

# 확인
echo $PIP_CACHE_DIR

# 영구 적용 (로그아웃 후 재로그인)
exit
```

### 캐시 디렉토리 접근 불가

**증상:**
```bash
ls /data/cache/pip
# 결과: Permission denied
```

**원인:**
- 디렉토리 권한이 잘못 설정됨
- 사용자가 `gpu-users` 그룹에 속하지 않음

**해결:**
```bash
# 그룹 확인
groups
# gpu-users가 없으면 추가
sudo usermod -aG gpu-users alice
newgrp gpu-users

# 권한 재설정
sudo /data/AICADataKeeper/scripts/system-permissions.sh

# 확인
ls -ld /data/cache/pip
# 결과: drwxrwsr-x ... gpu-users
```

## 서버 재시작 관련 문제

### 자동 복구 실패

**증상:**
- 서버 재시작 후 환경이 복구되지 않음
- Miniconda가 없음
- 환경 변수가 로드되지 않음

**원인:**
- `aica-recovery.service`가 실행되지 않음
- 사용자가 레지스트리에 등록되지 않음

**해결:**
```bash
# 서비스 상태 확인
sudo systemctl status aica-recovery.service

# 서비스 로그 확인
sudo journalctl -u aica-recovery.service -n 100

# 수동 복구 실행
sudo /data/AICADataKeeper/scripts/ops-recovery.sh

# 사용자 레지스트리 확인
cat /data/config/users.txt

# 사용자 등록
sudo /data/AICADataKeeper/scripts/user-register.sh alice gpu-users
```

### 글로벌 환경 복구 실패

**증상:**
- Miniconda가 설치되지 않음
- `/etc/profile.d/global_envs.sh`가 없음

**원인:**
- `ops-setup-global.sh` 실행 실패
- 디스크 공간 부족

**해결:**
```bash
# 디스크 공간 확인
df -h /data

# 글로벌 환경 재설정
sudo /data/AICADataKeeper/scripts/ops-setup-global.sh gpu-users

# 확인
ls -l /data/apps/miniconda3
ls -l /etc/profile.d/global_envs.sh
```

## SSH 접속 문제

### SSH 키 인증 실패

**증상:**
```bash
ssh alice@server
# 결과: Permission denied (publickey)
```

**원인:**
- `~/.ssh/authorized_keys` 권한이 잘못됨
- 공개키가 등록되지 않음

**해결:**
```bash
# 서버에서 권한 확인
sudo ls -la /data/users/alice/.ssh

# 권한 수정
sudo chmod 700 /data/users/alice/.ssh
sudo chmod 600 /data/users/alice/.ssh/authorized_keys
sudo chown -R alice:gpu-users /data/users/alice/.ssh

# 공개키 확인
sudo cat /data/users/alice/.ssh/authorized_keys
```

### SSH 접속 후 홈 디렉토리 없음

**증상:**
```bash
ssh alice@server
# 결과: Could not chdir to home directory /home/alice: No such file or directory
```

**원인:**
- 홈 디렉토리 심볼릭 링크가 깨짐

**해결:**
```bash
# 관리자로 복구
sudo /data/AICADataKeeper/scripts/user-create-home.sh alice gpu-users
```

## 디스크 관련 문제

### 디스크 공간 부족

**증상:**
```bash
df -h /data
# 결과: /data 95% 사용
```

**원인:**
- 캐시 파일 누적
- 사용자 데이터 증가
- 큰 모델 파일

**해결:**
```bash
# 1. 캐시 정리
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --all

# 2. 큰 파일 찾기
sudo find /data -type f -size +10G -exec ls -lh {} \;

# 3. 사용자별 디스크 사용량 확인
sudo du -sh /data/users/*

# 4. 임시 파일 정리
sudo find /data -name "*.tmp" -delete
sudo find /data -name "__pycache__" -type d -exec rm -rf {} +

# 5. 오래된 백업 삭제
sudo find /backup -name "*.tar.gz" -mtime +90 -delete
```

### 디스크 I/O 병목

**증상:**
- 파일 작업이 매우 느림
- `iostat`에서 높은 I/O 대기 시간

**원인:**
- 여러 사용자가 동시에 대용량 파일 작업
- HDD 성능 한계

**해결:**
```bash
# I/O 우선순위 낮춰서 실행
ionice -c 3 rsync -av /source /destination

# 피크 시간 피해서 작업
# 또는 uv 사용 (pip보다 빠름)
uv pip install large-package
```

## 권한 관련 문제

### 공유 디렉토리 쓰기 불가

**증상:**
```bash
touch /data/cache/pip/test
# 결과: Permission denied
```

**원인:**
- setgid가 설정되지 않음
- umask가 잘못 설정됨
- 그룹 권한이 없음

**해결:**
```bash
# 1. 그룹 확인
groups
# gpu-users가 있어야 함

# 2. umask 확인
umask
# 0002여야 함

# 3. 권한 재설정
sudo /data/AICADataKeeper/scripts/system-permissions.sh

# 4. setgid 확인
ls -ld /data/cache/pip
# 결과: drwxrwsr-x (s가 있어야 함)
```

### 새 파일 그룹 권한 없음

**증상:**
```bash
touch /data/cache/pip/test
ls -l /data/cache/pip/test
# 결과: -rw-r--r-- (그룹 쓰기 권한 없음)
```

**원인:**
- umask가 022로 설정됨 (기본값)

**해결:**
```bash
# umask 설정
echo "umask 002" >> ~/.bashrc
source ~/.bashrc

# 확인
umask
# 결과: 0002

# 테스트
touch /data/cache/pip/test2
ls -l /data/cache/pip/test2
# 결과: -rw-rw-r-- (그룹 쓰기 권한 있음)
```

## Conda 관련 문제

### Conda 환경 목록 안 보임

**증상:**
```bash
conda env list
# 결과: base 환경만 보임
```

**원인:**
- 환경이 다른 위치에 생성됨
- `.condarc` 설정이 잘못됨

**해결:**
```bash
# .condarc 확인
cat ~/.condarc

# envs_dirs 확인
conda config --show envs_dirs

# 환경 재설정
sudo /data/AICADataKeeper/scripts/user-setup-conda.sh alice gpu-users

# 확인
conda env list
```

### Conda 패키지 캐시 공유 안 됨

**증상:**
- 같은 패키지를 여러 번 다운로드

**원인:**
- `CONDA_PKGS_DIRS` 환경 변수가 설정되지 않음
- `.condarc`에 pkgs_dirs가 없음

**해결:**
```bash
# 환경 변수 확인
echo $CONDA_PKGS_DIRS

# .condarc 확인
cat ~/.condarc

# 환경 변수 로드
source /etc/profile.d/global_envs.sh

# Conda 재설정
sudo /data/AICADataKeeper/scripts/user-setup-conda.sh alice gpu-users
```

## 스크립트 실행 문제

### 스크립트 실행 권한 없음

**증상:**
```bash
./script.sh
# 결과: Permission denied
```

**원인:**
- 실행 권한이 없음

**해결:**
```bash
# 실행 권한 추가
chmod +x script.sh

# 또는 bash로 실행
bash script.sh
```

### 스크립트 문법 오류

**증상:**
```bash
./script.sh
# 결과: syntax error near unexpected token
```

**원인:**
- 스크립트 문법 오류
- Windows 줄바꿈 문자 (CRLF)

**해결:**
```bash
# 문법 검사
bash -n script.sh

# 줄바꿈 문자 변환 (CRLF → LF)
dos2unix script.sh

# 또는 sed 사용
sed -i 's/\r$//' script.sh
```

## 성능 문제

### 패키지 설치가 느림

**증상:**
- pip install이 매우 느림

**원인:**
- pip는 Python으로 작성되어 느림
- 네트워크 속도 문제

**해결:**
```bash
# uv 사용 (10-100배 빠름)
uv pip install package-name

# 또는 conda 사용
conda install package-name
```

### 모델 다운로드가 느림

**증상:**
- HuggingFace 모델 다운로드가 느림

**원인:**
- 네트워크 속도 문제
- 여러 사용자가 동시에 다운로드

**해결:**
```bash
# 다른 사용자에게 미리 공지
wall "대용량 모델 다운로드 예정 (10GB)"

# 피크 시간 피해서 다운로드
# 또는 미러 사용
export HF_ENDPOINT=https://hf-mirror.com
```

## 진단 도구

### 시스템 상태 확인

```bash
# 전체 시스템 테스트
sudo /data/AICADataKeeper/main.sh
# 메뉴에서 "설정 테스트" 선택

# 또는 수동 확인
bash -n /data/AICADataKeeper/scripts/*.sh
ls -l /etc/profile.d/global_envs.sh
ls -l /data/apps/miniconda3
cat /data/config/users.txt
ls -ld /data/cache/*
```

### 로그 확인

```bash
# 자동 복구 로그
tail -100 /var/log/aica-recovery.log

# 디스크 알림 로그
tail -100 /var/log/aica-disk-alert.log

# systemd 서비스 로그
sudo journalctl -u aica-recovery.service -n 100
```

### 권한 진단

```bash
# setgid 확인
ls -ld /data/cache/* | grep "^d.*s"

# 그룹 확인
ls -ld /data/cache/* | grep gpu-users

# umask 확인
umask  # 0002여야 함

# 사용자 그룹 확인
groups  # gpu-users가 있어야 함
```

## 비상 연락처

문제가 해결되지 않으면 관리자에게 문의하세요:

- **이메일**: eungbean@homilabs.ai
- **조직**: HOMI AI

문의 시 다음 정보를 포함하세요:
1. 문제 증상 (에러 메시지)
2. 발생 시점
3. 시도한 해결 방법
4. 관련 로그 파일

## 추가 자료

- [01. 초기 설정](01-initial-setup.md): 초기 설정 가이드
- [02. 사용자 관리](02-user-management.md): 사용자 관리 가이드
- [03. 환경 설정](03-environment.md): 환경 설정 가이드
- [04. 유지보수](04-maintenance.md): 유지보수 가이드
- [README.md](../README.md): 프로젝트 개요
- [AGENTS.md](../AGENTS.md): 개발자 문서
