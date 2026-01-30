# Bun / NFS 호환성 정리 (BUN_REPORT.md)

## 배경: 홈 디렉터리가 NFS에 있는 이유

AICADataKeeper는 **재부팅 시 초기화되는 SSD**와 **영구 보관용 HDD(NFS)** 를 나누어 쓰기 위해, 사용자 홈을 NFS 쪽으로 붙이는 구조를 씁니다.

- **설계**: `/home/<username>` → 심볼릭 링크 → `/data/users/<username>`
- **`/data`**: 영구 HDD 스토리지, NFS v3 마운트 (예: `192.168.0.86:/GJ_SHARE_FS5/...`)
- **결과**: `$HOME`이 NFS 위의 `/data/users/<username>`을 가리키므로, **홈 전체가 NFS에 있다고 봐야 함**
  - `~/.bun/`, `~/.cache/`, `~/.config/` 등 홈 하위 경로도 모두 NFS

자세한 구조는 [AGENTS.md](AGENTS.md)의 Project Structure, Infrastructure 섹션 참고.

---

## 문제: BunInstallFailedError

### 증상

OpenCode 등에서 **Bun**으로 플러그인/패키지를 설치할 때 다음처럼 실패함:

- **에러 이름**: `BunInstallFailedError`
- **로그 예**: `FileNotFound: failed copying files from cache to destination for package <name>`
- **영향**: oh-my-opencode, opencode-anthropic-auth, @gitlab/opencode-gitlab-auth 등 Bun 기반 설치가 불안정하거나 실패

### 원인

1. **캐시와 설치 경로가 모두 NFS**
   - Bun 설치 캐시: `~/.bun/install/cache` (NFS)
   - OpenCode 플러그인 설치 위치: `~/.cache/opencode` (NFS)

2. **NFS 특성**
   - 캐시 → 설치 디렉터리로의 **파일 복사** 시 NFS 락/파일 핸들/일시적 오류 등으로 `FileNotFound` 또는 복사 실패가 발생할 수 있음.
   - 같은 NFS 내에서의 대량 복사/생성 시 특히 불안정할 수 있음.

3. **정리**
   - “홈이 NFS”라는 이 레포 설계 때문에, Bun의 기본 경로(~/.bun, ~/.cache)가 전부 NFS가 되고, 그 위에서의 install이 실패하는 구조임.

### NFS에서 실패하는 기술적 이유

Bun 설치 흐름은 대략 **다운로드 → 캐시에 압축 해제 → 캐시에서 설치 경로로 복사/이동**이다. 이때 캐시와 설치 경로가 **둘 다 NFS**이면 아래 NFS 특성 때문에 `FileNotFound`(또는 ESTALE)가 난다.

| 원인 | 설명 |
|------|------|
| **rename() 동작** | Bun은 설치 시 "임시 파일 쓰기 → 최종 경로로 rename" 방식을 쓸 수 있다. NFS에서 rename은 클라이언트 기준으로만 원자적이고, 디렉터리/속성 캐시가 갱신되기 전에 다음 읽기가 이뤄지면 **ENOENT(파일 없음)** 로 보일 수 있다. |
| **Stale file handle** | 캐시에서 파일을 연 상태에서, 같은 프로세스나 다른 프로세스가 그 파일을 이동/삭제/덮어쓰면 inode가 바뀌고, 열려 있던 핸들이 **stale**이 된다. 이후 읽기 시 **ESTALE** 또는 **FileNotFound**로 실패한다. |
| **동일 NFS 내 대량 I/O** | 수백~수천 개의 작은 파일을 캐시 → 설치 경로로 복사할 때, NFS의 락/속성 캐시/디렉터리 캐시가 꼬이기 쉽고, 타이밍에 따라 "방금 쓴 파일이 없다"처럼 보이는 경우가 있다. |
| **.nfs* 파일** | NFS에서는 "열린 파일을 삭제"하면 클라이언트가 `.nfsXXXXXXXX` 같은 임시 파일로 유지한다. Bun이 캐시를 정리하거나 이동하는 동안 아직 읽기가 끝나지 않았으면, 원래 경로에서는 **파일이 없어진 것처럼** 보여 복사 단계에서 실패할 수 있다. |

즉, **캐시와 설치 대상이 같은 NFS에 있으면** rename/열린 핸들/캐시 일관성 문제가 겹쳐서 "cache → destination 복사" 단계에서 `FileNotFound`가 나는 것이다. **캐시만 로컬 디스크**로 두면, 최소한 "읽기"는 로컬에서 이뤄지고 NFS는 "쓰기"만 하게 되어 훨씬 안정적이다.

### Bun만 이런가? (다른 도구와 비교)

**이번에 겪은 그 오류는 Bun 쪽 동작 때문이다.** NFS에서 깨질 수 있는 건 Bun만은 아니지만, "FileNotFound: failed copying files from cache to destination"처럼 **캐시에서 설치 경로로 복사하는 단계**에서 터지는 패턴은 Bun이 쓰는 방식 때문이다.

| 구분 | 설명 |
|------|------|
| **Bun** | 전역 캐시(`~/.bun/install/cache`)에 풀어 둔 뒤, **캐시 → 설치 경로로 복사/rename**을 많이 씀. 캐시와 대상이 둘 다 NFS면 이 구간에서 NFS 특성(rename/핸들/캐시) 때문에 실패하기 쉽고, 그때 `BunInstallFailedError`가 난다. |
| **npm** | `node_modules`에 직접 풀거나, 캐시에서 복사하는 방식이 다르고, 전역 캐시 경로도 다름(`~/.npm`). NFS에서 가끔 느리거나 깨질 수는 있지만, Bun과 같은 "캐시→destination 복사 실패" 메시지는 보통 안 난다. |
| **pip / conda** | 캐시·설치 경로·I/O 패턴이 달라서, NFS에서도 Bun만큼 같은 형태로 터지지는 않는 경우가 많다. (NFS에서 느리거나 다른 증상은 있을 수 있음.) |
| **이전에 문제 없었던 이유** | 예전에는 Bun을 쓰지 않았거나(예: npm/pip/conda만 사용), OpenCode처럼 **Bun으로 플러그인을 설치하는 흐름**을 타지 않았을 가능성이 크다. Bun을 쓰기 시작한 시점부터 이 조합(NFS 홈 + Bun install)에서만 이 오류가 드러난다. |

정리하면, **NFS에서 문제를 일으킬 수 있는 건 Bun만은 아니지만**, 지금 겪은 **그 구체적인 오류**는 Bun의 "캐시 → 설치 경로 복사" 방식 때문에 나는 것이다. 다른 패키지 매니저들은 같은 메시지로 잘 안 터진다.

---

## 홈이 NFS(심볼릭 링크)일 때 해결 가능 여부

**가능하다.** `/home/<user>` → `/data/users/<user>` 심볼릭 링크 설계를 바꾸지 않고도, Bun 관련 문제만 해결할 수 있다.

| 구분 | 설명 |
|------|------|
| **홈 구조 유지** | AICADataKeeper의 “홈을 NFS에 두는” 설계는 그대로 둔다. 사용자 데이터·설정은 계속 NFS(`/data/users/<user>`)에 있다. |
| **해결 방식** | Bun이 **쓰는 경로만** 로컬 디스크로 우회한다. (1) Bun **캐시**를 환경 변수로 로컬로, (2) 필요 시 **설치 대상** 디렉터리(~/.cache/opencode, ~/.bun 등)를 심볼릭 링크로 로컬을 가리키게 한다. |
| **효과** | Bun/OpenCode는 “캐시 읽기”와 “설치 디렉터리 쓰기”를 로컬에서 하므로, NFS 위에서의 rename/핸들/캐시 문제를 피할 수 있다. |

**정리**: 홈 폴더 자체는 계속 NFS에 두고, **Bun이 사용하는 캐시·설치 경로만** 로컬로 빼면 된다. 레포의 심볼릭 링크 구조를 바꿀 필요는 없다.

---

## 대응: Bun 캐시만 로컬 디스크로 옮기기

**캐시**만 로컬(예: `/tmp`)로 두고, **설치 대상**은 기존처럼 NFS(~/.cache/opencode)를 쓰면 대부분 정상 동작합니다.

### 1. 환경 변수 설정

쉘 설정(`~/.bashrc` 또는 `~/.zshrc`)에 추가:

```bash
# NFS 홈 환경에서 Bun 설치 오류 방지: 캐시를 로컬 디스크로
export BUN_INSTALL_CACHE_DIR="${BUN_INSTALL_CACHE_DIR:-/tmp/bun-install-cache-$USER}"
```

- `/tmp`는 보통 로컬 디스크(ext4 등)에 마운트되어 있음.
- `$USER`별로 디렉터리를 나누어 다중 사용자 시 충돌을 줄임.

### 2. (선택) 로컬 캐시 디렉터리 생성

한 번만 만들어 두면 됨:

```bash
mkdir -p /tmp/bun-install-cache-$USER
chmod 700 /tmp/bun-install-cache-$USER
```

### 3. 기존 캐시 정리 후 재시도

한 번 실패한 뒤에는 캐시/설치 디렉터리를 비우고 다시 시도하는 것이 좋음:

```bash
rm -rf ~/.bun/install/cache ~/.cache/opencode
source ~/.zshrc   # 또는 source ~/.bashrc
opencode          # 또는 해당 Bun 사용 앱 재실행
```

---

## 추가 대응: 설치 경로까지 NFS에서 벗어나고 싶을 때

위 방법으로도 계속 실패하면, **OpenCode 플러그인 설치 경로**까지 로컬로 옮길 수 있음.  
(OpenCode는 `OPENCODE_CACHE` 같은 공식 env가 없으므로, 심볼릭 링크로 우회)

```bash
rm -rf ~/.cache/opencode
mkdir -p /tmp/opencode-cache-$USER
ln -s /tmp/opencode-cache-$USER ~/.cache/opencode
```

- **주의**: `/tmp`는 재부팅 시 정리될 수 있어, 재부팅 후에는 플러그인이 다시 설치될 수 있음.
- 이 레포의 “홈은 NFS” 설계와는 별개로, OpenCode/Bun만을 위한 임시 완화용으로 보는 것이 좋음.

---

## 요약

| 항목 | 내용 |
|------|------|
| **홈가 NFS인 이유** | 이 레포(AICADataKeeper)가 `/home/<user>` → `/data/users/<user>` 심볼릭 링크로 사용자 데이터를 NFS에 두기 때문 |
| **문제** | Bun 기본 캐시/설치 경로가 NFS라서, install 시 `BunInstallFailedError` / `FileNotFound` 발생 |
| **해결 가능 여부** | **가능.** 홈(심볼릭 링크) 구조는 그대로 두고, Bun이 쓰는 캐시·설치 경로만 로컬로 우회하면 됨 |
| **권장 대응** | `BUN_INSTALL_CACHE_DIR=/tmp/bun-install-cache-$USER` 로 캐시만 로컬로 두기 |
| **추가 대응** | 필요 시 `~/.cache/opencode` 를 `/tmp/opencode-cache-$USER` 로 심볼릭 링크 (재부팅 시 플러그인 재설치 가능성 있음) |

이 내용은 “이 레포 때문에 홈가 NFS”인 환경에서 Bun 사용 시 참고용으로 정리한 것이다.
