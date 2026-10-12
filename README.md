# hoyaaaa dotfiles

chezmoi로 전역 설정, Codex 사용자 스킬, 설치 소프트웨어 목록을 관리합니다.
하나의 저장소와 `main` 브랜치를 사용하며, 변경 내용을 서명 커밋·푸시로 동기화합니다.

| 플랫폼 | 현재 범위 |
| --- | --- |
| macOS | 설정 복원, 패키지 관리, 시크릿 관리, 자동 동기화 |
| Fedora | OS별 제외 규칙과 분리 구조 준비. 설치·적용 도구는 후속 구현 |
| Windows | 계획만 작성 |

Fedora·Windows 구현 계획은 [플랫폼 계획](docs/platform-plan.md)에 있습니다.
현재 `bin/dotfiles` 명령은 macOS에서만 실행됩니다.

## 저장소 구조

```text
.chezmoiignore                 # OS별 적용 대상과 운영 파일 제외
.chezmoitemplates/darwin/      # macOS Bash·Profile·Zsh·Git 설정 원문
dot_*.tmpl                   # 설정 원문을 해당 홈 파일로 렌더링
dot_codex/                   # Codex 전역 지침·스킬·훅·자동화 설정
private_dot_agents/          # 사용자 스킬과 관리 대상 심볼릭 링크
private_dot_config/          # 앱 설정과 암호화된 시크릿 소스
bin/dotfiles                 # 명령 진입점
scripts/                     # 수집·검증·서명 커밋·푸시
scripts/darwin/              # macOS 패키지 업데이트·앱 목록 수집
packages/darwin/Brewfile      # Homebrew·Cask·Mac App Store 설치 목록
packages/manual.md           # 수동 설치와 복원 방법
packages/discovered-apps.md  # 패키지 관리 밖의 앱 조사 목록
docs/platform-plan.md        # Fedora·Windows 후속 계획
```

`dot_`, `private_`, `encrypted_`는 chezmoi의 소스 파일 이름 규칙입니다.
템플릿 원문과 운영 스크립트는 홈에 그대로 배포하지 않습니다.

## 새 Mac에서 복원

1. Apple Passwords의 `chezmoi age recovery key`를 클립보드로 복사하고 로컬 키 파일을 복구합니다.

   ```sh
   mkdir -p ~/.config/chezmoi
   pbpaste > ~/.config/chezmoi/key.txt
   chmod 600 ~/.config/chezmoi/key.txt
   ```

2. 저장소를 복제합니다.

   ```sh
   git clone https://github.com/hoyaaaa/.dotfiles.git ~/.dotfiles
   ```

3. 초기 설치와 설정 적용을 실행합니다.

   ```sh
   ~/.dotfiles/bin/dotfiles bootstrap
   ```

`bootstrap`은 Homebrew 준비, age·chezmoi 설치, 복구한 age 키 확인,
Brewfile 설치, 관리 설정 적용, 주간 패키지 관리 등록을 수행합니다.

GitHub 인증과 Secretive `notify-key` 서명 환경은 해당 Mac에서 별도로 준비해야 합니다.
Codex 자동화 설정에는 현재 채팅 ID가 포함되므로, 다른 Mac에서는 대상 채팅에 맞게 다시 등록합니다.

## 명령

아래 명령은 `~/.dotfiles/bin/dotfiles <명령>`으로 실행합니다.

| 명령 | 동작 |
| --- | --- |
| `status` | chezmoi 차이, Git 변경, Homebrew 업데이트 대상 확인 |
| `apply` | 관리 중인 설정을 실제 전역 경로에 적용 |
| `snapshot` | 전역 설정 변경과 설치 목록을 로컬 저장소에 수집 |
| `sync` | 수집 → 검사 → 서명 커밋 → `main` 푸시 → 원격 SHA 확인 |
| `packages-snapshot` | 현재 설치 목록으로 `packages/darwin/Brewfile` 갱신 |
| `apps-snapshot` | `packages/discovered-apps.md` 갱신 |
| `update` | 로컬 설정 수집 후 설치된 패키지 관리자 업데이트 |
| `install` | 설정 적용과 주간 패키지 관리 등록 |
| `bootstrap` | 새 Mac 초기 설치와 설정 복원 |

`update`는 Homebrew와 설치된 pipx·uv·npm·rustup을 대상으로 합니다.
`sync`는 원격 설정을 가져와 실제 설정에 적용하는 명령이 아닙니다.

## 전역 스킬

| 스킬 | 역할 |
| --- | --- |
| `dotfiles-config` | 전역 설정과 사용자 소유 스킬을 관리하고 변경 수집 |
| `dotfiles-software` | 설치 소프트웨어 목록과 수동 복원 방법 관리 |
| `dotfiles-secrets` | 저장된 인증 정보를 먼저 확인하고 암호화 시크릿 관리 |

소프트웨어 설치는 Homebrew/Cask → Mac App Store → 문서화한 수동 설치 순서입니다.
`packages/discovered-apps.md`는 조사 목록이며, 모든 항목을 재설치하라는 목록은 아닙니다.
Codex 내장·플러그인·앱 소유 스킬은 해당 도구가 관리합니다.
Ego 스킬은 앱 소유 경로를 가리키는 심볼릭 링크만 관리합니다.

## 자동 동기화

| 실행 계기 | 동작 |
| --- | --- |
| Codex 세션 종료 훅 | `snapshot`: 로컬 변경 수집 |
| 매시간 Codex 자동화 | `sync`: 서명 커밋·`main` 푸시까지 수행 |
| 매주 월요일 10:00, Mac 현지 시간 | 기존 launchd 작업으로 패키지 업데이트 |

시간당 동기화용 백그라운드 서비스는 사용하지 않습니다.
정상적인 자동화 실행은 조용히 처리하고, 실패하거나 사용자 조치가 필요하면 알립니다.

기존 관리 파일은 `chezmoi re-add`로 수집합니다. macOS 셸·Git의 네 템플릿은
실제 파일 변경을 `.chezmoitemplates/darwin/` 원문에 먼저 복사해 수집합니다.
암호화된 시크릿은 `dotfiles-secrets`의 전용 도구로 갱신합니다.

자동 커밋은 Git 추적 파일만 포함합니다. 새 파일은 검토 후 명시적으로 등록해야 합니다.
기존 staged 변경, 원격 `main`의 앞선 변경·분기, 시크릿 검사 실패, 서명 실패가 있으면
푸시를 중단합니다. 강제 푸시하거나 서명을 끄지 않습니다.

| 기록 | 위치 |
| --- | --- |
| 수집·동기화 로그 | `~/Library/Logs/dotfiles-sync.log` |
| 패키지 업데이트 로그 | `~/Library/Logs/dotfiles-update.log` |
| 실행 상태 | `~/.local/state/dotfiles/snapshot-state.json` |

실행 상태는 `started`, `running`, `completed`, `failed`로 기록합니다.

## 시크릿 보관

시크릿의 로컬 원본은 `~/.config/chezmoi-secrets/secrets.json`이며,
저장소에는 age로 암호화한 소스만 보관합니다.
비밀 값은 채팅·명령 출력·로그에 표시하지 않습니다.

age identity는 `~/.config/chezmoi/key.txt`에만 두고 복구 사본은 Apple Passwords에 보관합니다.
복호화한 시크릿, 개인 키, 인증 캐시, 인증서, 실행 로그와 히스토리는 커밋하지 않습니다.
