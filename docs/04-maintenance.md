# 04. 유지보수 가이드

## 개요

AICADataKeeper 시스템의 정기 유지보수 작업과 모니터링 방법을 안내합니다.

## 정기 유지보수 일정

### 일일 작업

**디스크 사용량 모니터링**

```bash
# 디스크 사용량 확인
df -h /data

# 사용자별 디스크 사용량
sudo du -sh /data/users/*

# 캐시 사용량
sudo du -sh /data/cache/*
```

### 주간 작업

**캐시 정리**

```bash
# 모든 캐시 정리
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --all

# 또는 개별 캐시 정리
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --conda
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --pip
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --torch
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --hf
```

**사용자 데이터 백업**

```bash
# 전체 사용자 데이터 백업
sudo rsync -av /data/users/ /backup/users/

# 또는 압축 백업
sudo tar -czf /backup/users-$(date +%Y%m%d).tar.gz -C /data users
```

### 월간 작업

**시스템 점검**

```bash
# 스크립트 문법 검사
bash -n /data/AICADataKeeper/scripts/*.sh

# 환경 파일 확인
ls -l /etc/profile.d/global_envs.sh

# Miniconda 확인
ls -l /data/apps/miniconda3

# 사용자 레지스트리 확인
cat /data/config/users.txt
```

**권한 점검**

```bash
# 공유 디렉토리 권한 확인
ls -ld /data/cache/*
ls -ld /data/models/*

# setgid 확인 (s 또는 S가 있어야 함)
ls -ld /data/cache/pip | grep "^d.*s"

# 필요시 권한 재설정
sudo /data/AICADataKeeper/scripts/system-permissions.sh
```

**로그 검토**

```bash
# 자동 복구 로그
tail -100 /var/log/aica-recovery.log

# 디스크 알림 로그
tail -100 /var/log/aica-disk-alert.log

# 시스템 로그
journalctl -u aica-recovery.service -n 100
```

### 분기별 작업

**전체 백업**

```bash
# 설정 파일 백업
sudo tar -czf /backup/config-$(date +%Y%m%d).tar.gz \
  /data/config \
  /etc/profile.d/global_envs.sh \
  /etc/sudoers.d/aica-datakeeper

# 스크립트 백업
sudo tar -czf /backup/scripts-$(date +%Y%m%d).tar.gz \
  /data/AICADataKeeper/scripts

# 사용자 데이터 전체 백업
sudo rsync -av --delete /data/users/ /backup/users/
```

**시스템 업데이트 검토**

```bash
# AICADataKeeper 업데이트 확인
cd /data/AICADataKeeper
git fetch
git log HEAD..origin/main --oneline

# 업데이트 적용 (신중하게)
git pull
chmod +x scripts/*.sh
```

## 캐시 관리

### 캐시 정리 스크립트

```bash
# 사용법
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh [옵션]

# 옵션:
#   --all     모든 캐시 정리
#   --conda   Conda 패키지 캐시 정리
#   --pip     Pip 캐시 정리
#   --torch   PyTorch 모델 캐시 정리
#   --hf      HuggingFace 캐시 정리
#   --uv      uv 캐시 정리
```

### 수동 캐시 정리

```bash
# Conda 캐시 정리
conda clean --all

# Pip 캐시 정리
pip cache purge

# uv 캐시 정리
uv cache clean
```

### 캐시 사용량 모니터링

```bash
# 캐시 디렉토리별 사용량
du -sh /data/cache/*

# 상세 정보
du -h --max-depth=2 /data/cache | sort -hr | head -20
```

## 디스크 관리

### 디스크 사용량 알림

```bash
# 수동 실행
sudo /data/AICADataKeeper/scripts/ops-disk-alert.sh --threshold 80

# Dry-run (로그 파일에 기록하지 않음)
sudo /data/AICADataKeeper/scripts/ops-disk-alert.sh --threshold 80 --dry-run

# 로그 확인
cat /var/log/aica-disk-alert.log
```

### Cron 자동화

```bash
# 매시간 디스크 사용량 확인
echo '0 * * * * /data/AICADataKeeper/scripts/ops-disk-alert.sh --threshold 80' | sudo crontab -

# Cron 작업 확인
sudo crontab -l

# Cron 작업 제거
sudo crontab -r
```

### 디스크 공간 확보

```bash
# 1. 캐시 정리
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --all

# 2. 오래된 백업 삭제
sudo find /backup -name "*.tar.gz" -mtime +90 -delete

# 3. 사용자별 큰 파일 찾기
sudo find /data/users -type f -size +1G -exec ls -lh {} \;

# 4. 임시 파일 정리
sudo find /data/users -name "*.tmp" -delete
sudo find /data/users -name "__pycache__" -type d -exec rm -rf {} +
```

## 서버 재시작 후 복구

### 자동 복구 (systemd 서비스)

서버 재부팅 시 자동으로 실행됩니다:

```bash
# 서비스 상태 확인
sudo systemctl status aica-recovery.service

# 서비스 로그 확인
sudo journalctl -u aica-recovery.service -n 100

# 서비스 재시작
sudo systemctl restart aica-recovery.service
```

### 수동 복구

```bash
# 전체 복구 (글로벌 환경 + 모든 등록 사용자)
sudo /data/AICADataKeeper/scripts/ops-recovery.sh

# Dry-run (실제 실행하지 않고 계획만 확인)
sudo /data/AICADataKeeper/scripts/ops-recovery.sh --dry-run

# 복구 로그 확인
tail -f /var/log/aica-recovery.log
```

### 글로벌 환경만 복구

```bash
sudo /data/AICADataKeeper/scripts/ops-setup-global.sh gpu-users
```

## 사용자 관리

### 사용자 레지스트리 관리

```bash
# 레지스트리 확인
cat /data/config/users.txt

# 사용자 추가
sudo /data/AICADataKeeper/scripts/user-register.sh alice gpu-users

# 사용자 제거
sudo sed -i '/^alice:/d' /data/config/users.txt
```

### 비활성 사용자 정리

```bash
# 90일 이상 로그인하지 않은 사용자 찾기
lastlog -b 90

# 사용자 데이터 아카이브
sudo tar -czf /backup/users/alice-archive-$(date +%Y%m%d).tar.gz \
  -C /data/users alice

# 사용자 삭제
sudo userdel alice
sudo rm /home/alice
sudo mv /data/users/alice /backup/users/
```

## 권한 관리

### 권한 재설정

```bash
# 공유 디렉토리 권한 재설정
sudo /data/AICADataKeeper/scripts/system-permissions.sh

# 사용자 데이터 권한 재설정
sudo /data/AICADataKeeper/scripts/user-fix-permissions.sh alice gpu-users
```

### Sudoers 설정 확인

```bash
# Sudoers 파일 확인
sudo cat /etc/sudoers.d/aica-datakeeper

# 문법 검사
sudo visudo -c -f /etc/sudoers.d/aica-datakeeper

# 재설정
sudo /data/AICADataKeeper/scripts/system-sudoers.sh
```

## 모니터링

### 시스템 리소스 모니터링

```bash
# CPU 사용량
top

# 메모리 사용량
free -h

# 디스크 I/O
iostat -x 1

# 네트워크 사용량
iftop
```

### 사용자 활동 모니터링

```bash
# 현재 로그인 사용자
who

# 사용자 로그인 기록
last -n 20

# 사용자별 프로세스
ps aux | grep username
```

## 로그 관리

### 로그 파일 위치

- `/var/log/aica-recovery.log`: 자동 복구 로그
- `/var/log/aica-disk-alert.log`: 디스크 알림 로그
- `journalctl -u aica-recovery.service`: systemd 서비스 로그

### 로그 정리

```bash
# 오래된 로그 삭제
sudo find /var/log -name "aica-*.log" -mtime +30 -delete

# 로그 로테이션 설정
sudo tee /etc/logrotate.d/aica-datakeeper > /dev/null <<EOF
/var/log/aica-*.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
EOF
```

## 성능 최적화

### I/O 우선순위 조정

```bash
# 대용량 파일 작업 시 낮은 우선순위로 실행
ionice -c 3 rsync -av /source /destination
```

### 캐시 워밍

```bash
# 자주 사용하는 패키지 미리 다운로드
conda install --download-only numpy pandas scikit-learn
pip download -d /tmp torch torchvision
```

## 문제 예방

### 정기 점검 체크리스트

- [ ] 디스크 사용량 80% 미만 유지
- [ ] 주간 캐시 정리 수행
- [ ] 월간 백업 확인
- [ ] 사용자 레지스트리 최신 상태 유지
- [ ] 권한 설정 정상 (setgid 확인)
- [ ] 로그 파일 검토
- [ ] 자동 복구 서비스 정상 작동

### 모범 사례

1. **정기적인 백업**: 주 1회 이상 사용자 데이터 백업
2. **디스크 모니터링**: 임계치 80% 설정
3. **캐시 정리**: 주 1회 또는 디스크 사용량 높을 때
4. **로그 검토**: 월 1회 이상 로그 파일 검토
5. **권한 점검**: 분기 1회 권한 설정 확인
6. **시스템 업데이트**: 분기 1회 AICADataKeeper 업데이트 검토

## 비상 상황 대응

### 디스크 풀 (100%)

```bash
# 1. 즉시 캐시 정리
sudo /data/AICADataKeeper/scripts/ops-clean-cache.sh --all

# 2. 큰 파일 찾기
sudo find /data -type f -size +10G -exec ls -lh {} \;

# 3. 임시 파일 정리
sudo find /data -name "*.tmp" -delete
sudo find /data -name "core.*" -delete

# 4. 사용자에게 공지
wall "디스크 공간 부족. 불필요한 파일 삭제 요망."
```

### 권한 문제 대량 발생

```bash
# 전체 권한 재설정
sudo /data/AICADataKeeper/scripts/system-permissions.sh

# 모든 사용자 권한 재설정
for user in $(cat /data/config/users.txt | cut -d: -f1); do
  group=$(cat /data/config/users.txt | grep "^$user:" | cut -d: -f2)
  sudo /data/AICADataKeeper/scripts/user-fix-permissions.sh "$user" "$group"
done
```

### 자동 복구 실패

```bash
# 로그 확인
sudo journalctl -u aica-recovery.service -n 100

# 수동 복구 실행
sudo /data/AICADataKeeper/scripts/ops-recovery.sh

# 개별 사용자 복구
sudo /data/AICADataKeeper/scripts/user-setup.sh alice gpu-users
```

## 다음 단계

- [05. 문제 해결](05-troubleshooting.md): 일반적인 문제 해결 방법
- [01. 초기 설정](01-initial-setup.md): 초기 설정 가이드
- [02. 사용자 관리](02-user-management.md): 사용자 관리 가이드
