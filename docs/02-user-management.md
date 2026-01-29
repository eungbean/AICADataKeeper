# 02. 사용자 관리 가이드

## 개요

신규 사용자 추가, 환경 복구, SSH 키 설정 등 사용자 관리 작업을 안내합니다.

## 신규 사용자 추가

### 방법 1: 대화형 위자드 사용 (권장)

```bash
# 통합 관리 스크립트 실행
sudo /data/AICADataKeeper/main.sh

# 메뉴에서 "새 사용자 추가" 선택
```

위자드는 다음 작업을 자동으로 수행합니다:
1. Linux 사용자 계정 생성
2. 그룹 추가
3. 홈 디렉토리 심볼릭 링크 생성
4. SSH 키 설정 (선택)
5. Conda 환경 설정
6. 파일 권한 설정
7. 자동 복구 레지스트리 등록

### 방법 2: 수동 설정

```bash
# 1. Linux 사용자 생성
sudo adduser alice

# 2. 그룹 추가
sudo usermod -aG gpu-users alice

# 3. 사용자 환경 설정
sudo /data/AICADataKeeper/scripts/user-setup.sh alice gpu-users

# 4. 자동 복구 레지스트리 등록
sudo /data/AICADataKeeper/scripts/user-register.sh alice gpu-users
```

## SSH 키 설정

### 신규 사용자 생성 시 SSH 키 설정

대화형 위자드를 사용하면 사용자 생성 중 SSH 키를 설정할 수 있습니다:

```
[SSH 키 설정]
1. 기존 공개키 붙여넣기
2. 새 키 쌍 생성
3. 나중에 설정

선택 [1-3]: 
```

**옵션 1: 기존 공개키 붙여넣기**
- 사용자의 공개키(id_rsa.pub 또는 id_ed25519.pub 내용)를 붙여넣습니다
- 공개키는 `~/.ssh/authorized_keys`에 자동으로 추가됩니다

**옵션 2: 새 키 쌍 생성**
- 서버에서 새 SSH 키 쌍을 생성합니다
- 개인키는 사용자에게 전달해야 합니다 (보안 주의!)
- 공개키는 자동으로 등록됩니다

**옵션 3: 나중에 설정**
- SSH 키 설정을 건너뜁니다
- 나중에 수동으로 설정할 수 있습니다

### 기존 사용자 SSH 키 추가

```bash
# 사용자로 로그인
su - alice

# .ssh 디렉토리 생성
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# authorized_keys 파일 생성/편집
nano ~/.ssh/authorized_keys

# 공개키 붙여넣기 후 저장

# 권한 설정
chmod 600 ~/.ssh/authorized_keys
```

## 사용자 환경 복구

서버 재시작 후 또는 환경 문제 발생 시 사용자 환경을 복구할 수 있습니다.

### 전체 복구

```bash
# 모든 설정 한번에 복구
sudo /data/AICADataKeeper/scripts/user-setup.sh alice gpu-users
```

### 개별 복구

```bash
# 홈 디렉토리 링크만 복구
sudo /data/AICADataKeeper/scripts/user-create-home.sh alice gpu-users

# Conda 환경만 복구
sudo /data/AICADataKeeper/scripts/user-setup-conda.sh alice gpu-users

# 파일 권한만 수정
sudo /data/AICADataKeeper/scripts/user-fix-permissions.sh alice gpu-users
```

## 사용자 삭제

```bash
# 1. 자동 복구 레지스트리에서 제거
sudo sed -i '/^alice:/d' /data/config/users.txt

# 2. Linux 사용자 삭제
sudo userdel alice

# 3. 홈 디렉토리 심볼릭 링크 제거
sudo rm /home/alice

# 4. 사용자 데이터 백업 (선택)
sudo mv /data/users/alice /backup/users/alice.$(date +%Y%m%d)

# 또는 완전 삭제
sudo rm -rf /data/users/alice
```

## 사용자 그룹 관리

### 그룹 추가

```bash
# 사용자를 추가 그룹에 추가
sudo usermod -aG additional-group alice

# 그룹 확인
groups alice
```

### 그룹 제거

```bash
# 사용자를 그룹에서 제거
sudo gpasswd -d alice additional-group
```

## 사용자 권한 관리

### sudo 권한 부여

```bash
# sudo 그룹에 추가
sudo usermod -aG sudo alice
```

### 제한적 sudo 권한

기본적으로 `gpu-users` 그룹 사용자는 다음 명령을 비밀번호 없이 실행할 수 있습니다:

```bash
# 캐시 정리
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --all

# 디스크 사용량 확인
sudo df -h /data
```

추가 권한이 필요한 경우 `/etc/sudoers.d/aica-datakeeper` 파일을 수정하세요.

## 자동 복구 레지스트리

서버 재부팅 후 자동으로 복구될 사용자 목록을 관리합니다.

### 사용자 등록

```bash
sudo /data/AICADataKeeper/scripts/user-register.sh alice gpu-users
```

### 등록 확인

```bash
cat /data/config/users.txt
```

출력 형식: `username:groupname`

### 수동 편집

```bash
sudo nano /data/config/users.txt

# 형식: username:groupname
alice:gpu-users
bob:gpu-users
charlie:gpu-users
```

## 사용자 데이터 백업

### 개별 사용자 백업

```bash
# rsync를 사용한 백업
sudo rsync -av /data/users/alice/ /backup/users/alice/

# tar를 사용한 압축 백업
sudo tar -czf /backup/users/alice.$(date +%Y%m%d).tar.gz -C /data/users alice
```

### 전체 사용자 백업

```bash
# 모든 사용자 데이터 백업
sudo rsync -av /data/users/ /backup/users/

# 또는 압축 백업
sudo tar -czf /backup/users-all.$(date +%Y%m%d).tar.gz -C /data users
```

## 사용자 디스크 할당량 확인

```bash
# 사용자별 디스크 사용량
sudo du -sh /data/users/*

# 특정 사용자 상세 정보
sudo du -h --max-depth=1 /data/users/alice | sort -hr
```

## 문제 해결

### 홈 디렉토리 심볼릭 링크 깨짐

```bash
sudo /data/AICADataKeeper/scripts/user-create-home.sh alice gpu-users
```

### Conda 환경 인식 안 됨

```bash
# 사용자로 로그인
su - alice

# Conda 재초기화
conda init bash
source ~/.bashrc
```

### 파일 권한 문제

```bash
# 사용자 데이터 권한 재설정
sudo /data/AICADataKeeper/scripts/user-fix-permissions.sh alice gpu-users
```

### SSH 접속 불가

```bash
# SSH 디렉토리 권한 확인
sudo ls -la /data/users/alice/.ssh

# 권한 수정
sudo chmod 700 /data/users/alice/.ssh
sudo chmod 600 /data/users/alice/.ssh/authorized_keys
sudo chown -R alice:gpu-users /data/users/alice/.ssh
```

## 모범 사례

1. **사용자 추가 시 항상 자동 복구 레지스트리에 등록**
2. **정기적으로 사용자 데이터 백업 (주 1회 이상)**
3. **사용자 삭제 전 데이터 백업 확인**
4. **SSH 키 사용 권장 (비밀번호 인증보다 안전)**
5. **umask 002 설정 확인 (그룹 쓰기 권한 보장)**

## 다음 단계

- [03. 환경 설정](03-environment.md): Conda, Pip, uv 사용법
- [04. 유지보수](04-maintenance.md): 정기 유지보수 작업
- [05. 문제 해결](05-troubleshooting.md): 일반적인 문제 해결 방법
