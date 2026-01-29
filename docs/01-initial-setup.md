# 01. 초기 설정 가이드

## 개요

AICADataKeeper를 처음 설치하고 설정하는 전체 과정을 안내합니다.

## 전제 조건

- NHN Cloud AI 서버에 `ubuntu` 계정으로 SSH 접속
- `ubuntu` 계정은 sudo 권한 보유
- `/data`와 `/backup` 디렉토리가 마운트되어 있음

## 1단계: 저장소 클론

```bash
cd /data
git clone https://github.com/eungbean/AICADataKeeper
chmod +x /data/AICADataKeeper/scripts/*.sh
chmod +x /data/AICADataKeeper/main.sh
```

## 2단계: 초기 설정 (위자드 사용)

```bash
sudo bash /data/AICADataKeeper/main.sh
```

**메뉴에서 "0. 초기 설정 (처음 설치 시)" 선택**

위자드가 체크리스트를 표시합니다. 설치할 항목을 선택하세요:

| 항목 | 설명 |
|------|------|
| 그룹 생성 | `groupadd gpu-users` + 현재 사용자 그룹 추가 |
| /data 권한 설정 | `chown root:gpu-users` + `chmod 2775` |
| /backup 권한 설정 | `chown root:gpu-users` + `chmod 2775` |
| Miniconda 설치 | `/data/apps/miniconda3`에 공유 Miniconda |
| 글로벌 환경 변수 | `/etc/profile.d/global_envs.sh` 생성 |
| 캐시 디렉토리 생성 | `/data/cache/`, `/data/models/` 생성 |
| 공유 디렉토리 권한 | setgid 적용 |
| sudoers 설정 | 비관리자 제한적 sudo 권한 |

완료 후 **반드시** 다음을 실행하세요:

```bash
newgrp gpu-users
echo "umask 002" >> ~/.bashrc
source ~/.bashrc
```

## 3단계: 사용자 추가

### 방법 A: 대화형 위자드 (권장)

```bash
sudo bash /data/AICADataKeeper/main.sh
```

**메뉴에서 "2. 새 사용자 추가" 선택**

위자드가 다음을 자동으로 처리합니다:
- Linux 사용자 생성 (`adduser`)
- 그룹 추가 (`usermod -aG`)
- 홈 디렉토리 설정 (`/home/user` → `/data/users/user`)
- SSH 키 설정 (대화형)
- Conda 환경 설정
- 자동 복구 등록

### 방법 B: 수동 설정

```bash
GROUP_NAME=gpu-users
USER_NAME=alice
```

```bash
sudo adduser $USER_NAME
sudo usermod -aG $GROUP_NAME $USER_NAME
sudo /data/AICADataKeeper/scripts/user-setup.sh $USER_NAME $GROUP_NAME
sudo /data/AICADataKeeper/scripts/user-register.sh $USER_NAME $GROUP_NAME
```

**user-setup.sh가 실행하는 작업:**

| 순서 | 스크립트 | 역할 |
|------|----------|------|
| 1 | `user-create-home.sh` | `/data/users/<user>` 생성 + `/home/<user>` 심볼릭 링크 |
| 2 | `user-setup-conda.sh` | `.condarc` 설정 + conda 초기화 |
| 3 | `user-fix-permissions.sh` | 디렉토리 소유권/권한 수정 |

**SSH 키 수동 설정:**

```bash
sudo mkdir -p /data/users/$USER_NAME/.ssh
echo "ssh-ed25519 AAAA..." | sudo tee /data/users/$USER_NAME/.ssh/authorized_keys
sudo chmod 700 /data/users/$USER_NAME/.ssh
sudo chmod 600 /data/users/$USER_NAME/.ssh/authorized_keys
sudo chown -R $USER_NAME:$GROUP_NAME /data/users/$USER_NAME/.ssh
```

## 4단계: 설정 확인

```bash
su - $USER_NAME

pwd                    # /data/users/<user>
ls -la ~               # 심볼릭 링크 확인
conda --version        # conda 동작 확인
echo $PIP_CACHE_DIR    # /data/cache/pip
```

## umask 002 설정 (필수)

**모든 사용자**가 반드시 설정해야 합니다:

```bash
echo "umask 002" >> ~/.bashrc
source ~/.bashrc
```

| 설정 | 새 파일 권한 | 그룹 쓰기 |
|------|-------------|----------|
| 기본 umask (022) | 644 (rw-r--r--) | ❌ |
| umask 002 | 664 (rw-rw-r--) | ✅ |

## 선택사항: uv 패키지 관리자 설치

`uv`는 Rust로 작성된 초고속 Python 패키지 관리자입니다 (pip보다 10-100배 빠름).

```bash
sudo /data/AICADataKeeper/scripts/install-uv.sh
```

## 선택사항: 자동 복구 서비스 설정

서버 재부팅 후 환경을 자동으로 복구하는 systemd 서비스를 설정합니다.

```bash
# 서비스 파일 생성
sudo tee /etc/systemd/system/aica-recovery.service > /dev/null <<EOF
[Unit]
Description=AICADataKeeper Auto Recovery Service
After=network.target

[Service]
Type=oneshot
ExecStart=/data/AICADataKeeper/scripts/ops-recovery.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 서비스 활성화
sudo systemctl daemon-reload
sudo systemctl enable aica-recovery.service
```

## 선택사항: 디스크 모니터링 설정

디스크 사용량을 주기적으로 확인하는 cron 작업을 설정합니다.

```bash
# 매시간 디스크 사용량 확인 (임계치 80%)
echo '0 * * * * /data/AICADataKeeper/scripts/ops-disk-alert.sh --threshold 80' | sudo crontab -

# cron 작업 확인
sudo crontab -l
```

## 문제 해결

### 권한 오류

```bash
# 권한 재설정
sudo /data/AICADataKeeper/scripts/system-permissions.sh
```

### 환경 변수 로드 안 됨

```bash
# 수동으로 환경 변수 로드
source /etc/profile.d/global_envs.sh

# 또는 로그아웃 후 재로그인
```

### Miniconda 설치 실패

```bash
# 기존 설치 제거 후 재설치
sudo rm -rf /data/apps/miniconda3
sudo /data/AICADataKeeper/scripts/install-miniconda.sh
```

## 다음 단계

초기 설정이 완료되었습니다. 이제 다음 문서를 참고하세요:

- [02. 사용자 관리](02-user-management.md): 신규 사용자 추가 및 관리
- [03. 환경 설정](03-environment.md): Conda, Pip, uv 사용법
- [04. 유지보수](04-maintenance.md): 정기 유지보수 작업
- [05. 문제 해결](05-troubleshooting.md): 일반적인 문제 해결 방법
