# 13. Product Backlog

> Status: Accepted (v2) · Last updated: 2026-09-18 · Related: `11-development-roadmap.md`, `12-acceptance-criteria.md`, `16-definition-of-ready-done.md`, `03-system-architecture.md`, `06-learning-engine-rules.md`
>
> 2026-09-18 반영: 자체 서버 + Tailscale HTTPS, 서버 PostgreSQL 16, `devtoken` 운영 인증(BL-SEC-16), DeepSeek(BL-AIP-03·11·15·17), 수동 배포·`pg_dump` 백업(BL-OPS-07·11), git 전략(BL-OPS-21). Anthropic·도메인 항목은 `~~취소~~` 또는 Later로 옮겼다. Tailscale 전용·`devtoken`은 **임시 수단**이고 최종은 공개 배포다 — Supabase Auth(`BL-SEC-18`)는 그 필수 선행이고 OCI Always Free(arm64)는 배포지 후보다(`11` §3.10). "(검토 제안, 미결정)" 표시 항목은 착수 전에 사용자 결정이 필요하다.
>
> 모든 구현 작업의 단위 목록이다. 에이전트 작업 지시(`11-development-roadmap.md` §7)는 이 문서의 `BL-*` ID 하나 또는 같은 Sprint의 인접 ID 묶음 단위로 한다. 요구사항 ID(`FR-*`, `NFR-*`)의 상세는 `01-product-requirements.md`, 화면 ID(`SCR-*`)는 `02-user-scenarios-and-ux.md`를 따른다.

---

## 1. 우선순위 정의

| Priority | 정의 | 일정 압박 시 처리 |
|---|---|---|
| **P0** | 해당 Sprint exit criteria(AC)를 통과하는 데 필수이거나, 이월하면 다음 Sprint 작업이 막힌다 | 이월 금지. Sprint 목표를 줄여서라도 끝낸다 |
| **P1** | MVP 범위이고 AC에 연결되지만, RISK-01 stop-loss(`11-development-roadmap.md` §6)가 발동하면 Later로 옮길 수 있다 | 다음 Sprint로 1회 이월 가능. 2회 이월 시 `20-decisions-and-risks.md`에 결정 기록 |
| **P2** | 품질·편의 향상. AC에 직접 영향이 없다 | Sprint 여유가 있을 때만 착수 |
| **P3** | Later (2027-02 이후). 현재 일정 밖 | 착수하지 않는다 |

## 2. 작성 규칙

- ID: `BL-<EPIC>-<nn>`. 한번 부여한 ID는 재사용하지 않는다. 항목을 삭제하면 행을 지우지 않고 제목 앞에 `~~취소~~`를 붙인다.
- **굵은 클래스 이름**은 `03-system-architecture.md` §3.2의 도메인 규칙 클래스다. 규칙과 test vector는 `06-learning-engine-rules.md`가 기준이다.
- 구현은 **전부 에이전트가 한다.** 사용자는 결정(ADR 승인)·PR 리뷰·계정/서버 설정만 한다(`11-development-roadmap.md` §5).
- "(DoR 미충족)" 표시 항목은 규칙 정의가 canonical 문서에 없다. 착수 전에 문서를 먼저 보강한다(`16-definition-of-ready-done.md` §1).
- Depends on에는 선행 BL만 적는다. Spike 결과가 선행 조건이면 해당 Spike BL을 적는다.
- Sprint 기간: S0 2026-09-17~09-27 · S1 09-28~10-11 · S2 10-12~10-25 · S3 10-26~11-15 · S4 11-16~12-06 · S5 12-07~12-20 · S6 12-21~2027-01-04 · S7 2027-01-05~01-25 · Later 2027-02~

## 3. Epic 목록

| Epic | 이름 | 범위 |
|---|---|---|
| `FND` | Foundation | 백엔드 골격, 공통 모듈(`common`), migration, 프로필 API, 스케줄 공통 |
| `SEC` | Security · Privacy | 인증, allowlist, 격리, 헤더, 스캔, export·계정 삭제 |
| `OPS` | Deploy · Ops | 서버 준비, Caddy, CI/CD(git 전략), Tailscale HTTPS, 수동 배포, 백업, runbook, 모니터링 |
| `CLI` | Flutter Client | 앱 셸, API 클라이언트, 모든 화면, PWA |
| `CAR` | Career · Plan | 커리어 목표, 계획·버전, 온보딩, budget·risk·replan |
| `SKL` | Skill | skill catalog, skill state, 학습 이벤트, 레벨 갱신 |
| `TDY` | Today | planner, daily plan, 학습 세션, dashboard, 캘린더 |
| `MEM` | Memory Review | 복습 항목, 스케줄, due, 평가, variant |
| `TRN` | Training | challenge, attempt, self-explanation, Hint Ladder, 제출·평가, 진단 |
| `COA` | Project Coach | 코드 리뷰, finding, 응답 피드백, thinking pattern, purge |
| `EVD` | Evidence · Weekly | 지표, 주간 리뷰, thinking 추세, evidence, export |
| `JOB` | Job Radar | JD 분석, requirement 분류 |
| `AIP` | AI Platform | `integration.ai` 전체, 비동기 AI 공통, evals |
| `CNT` | Content | seed YAML, 검증기, seeder, prompt 파일 |

---

## 4. Backlog

### 4.1 FND — Foundation

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-FND-01 | SP-4 툴체인 호환 spike | seed 빌드 파일로 Gradle 9.7.1 + Boot 4.1.1 + Temurin 25.0.4에서 compile(-Werror)·Spotless·Checkstyle·PMD·SpotBugs·bootJar는 확인됨(09-17). 서버 Docker 터널 Testcontainers 실행과 RestClient + DeepSeek `/responses` smoke는 확인됨(09-18). 남은 확인: ArchUnit·springdoc 동작, 도구별 위반 검출. Java SDK·WireMock 의존성 없음. 절차는 `11-development-roadmap.md` §4 SP-4 | P0 | S0 | — | — | NFR-07, NFR-10 |
| BL-FND-02 | Monorepo 구조·루트 파일 | `backend/ app/ content/ evals/ infra/ docs/` 구조, `CLAUDE.md`(`@AGENTS.md`), `AGENTS.md`, `.gitattributes`(sh·gradlew·yml LF), `.editorconfig`, `.gitignore`, `.env.example`(키 이름만) | P0 | S0 | — | — | NFR-07 |
| BL-FND-03 | Backend bootstrap | Initializr 좌표 그대로 사용, Gradle Kotlin DSL + `libs.versions.toml`, toolchain은 SP-4 결과. `application.yml` 기본값(open-in-view=false, ddl-auto=validate, Flyway schema `devpilot`, actuator health만 노출), `GET /actuator/health` | P0 | S0 | BL-FND-01, BL-FND-02 | — | NFR-03 |
| BL-FND-04 | 품질 게이트 | Spotless(google-java-format AOSP, 100열), Checkstyle(명명 규칙 전용, ASCII 정규식), PMD 7, SpotBugs, JaCoCo(`09-test-and-quality.md` §15가 열거한 패키지 목록 기준 gate — 와일드카드 금지, 수치도 `09` §15) → `./gradlew check` 하나로 실행 | P0 | S0 | BL-FND-03 | — | NFR-07 |
| BL-FND-05 | ArchUnit 기본 규칙 | `08-coding-conventions.md`의 ARCH-* 규칙: 계층 의존, 필드 주입 금지, 무인자 `now()` 금지, `System.out` 금지, `@RestController` 위치, 모듈 의존표(`03` §2.2). 모듈이 추가될 때마다 규칙 대상 확장 | P0 | S0 | BL-FND-03 | — | NFR-07 |
| BL-FND-06 | Flyway V1 + migration 통합 테스트 | `V1__baseline.sql`(schema 생성 + 조건부 하드닝 DO 블록 — 순수 PostgreSQL에서는 no-op, Supabase 도입 시 revoke). Testcontainers `postgres:16`(서버 개발 DB와 같은 major)에서 빈 DB → 전체 migration → `ddl-auto=validate` 기동 테스트 | P0 | S0 | BL-FND-03, BL-OPS-01 | AC-20 | NFR-07 |
| BL-FND-07 | TraceId·요청 크기·Clock | `TraceIdFilter`(32 hex, MDC, 응답 헤더), `RequestBodySizeLimitFilter`(64KB 초과 413 `REQUEST_TOO_LARGE`), `ClockConfig`(UTC) + 테스트용 `MutableClock` | P0 | S0 | BL-FND-03 | AC-08 | NFR-06 |
| BL-FND-08 | 오류 처리 아키텍처 | `ErrorCode`(오류 코드 카탈로그 1:1), `DevPilotException` 계열, `GlobalExceptionHandler`(`03` §7 매핑, `code`·`traceId`·`errors`), `messages_ko.properties` | P0 | S1 | BL-FND-07 | AC-08 | NFR-04 |
| BL-FND-09 | 설정 바인딩 | `DevPilotProperties` 중첩 record + `@Validated`. 가중치 합·threshold 순서 검증, 소수 설정의 bp/micro 변환(N-6) 실패 시 기동 실패. 모듈 착수 시 해당 절을 추가 | P0 | S1 | BL-FND-03 | — | NFR-07 |
| BL-FND-10 | `PlanDayCalculator` | `planDate`, `planDayStart` 구현 + `06` §2 test vector 전부 | P0 | S1 | BL-FND-07 | AC-17 | FR-24, NFR-09 |
| BL-FND-11 | JPA 기반 | `BaseTimeEntity`, JPA Auditing, 애플리케이션 생성 UUID + `Persistable#isNew`, Hibernate jsonb·배열 매핑 검증 테스트 | P0 | S1 | BL-FND-06 | — | NFR-07 |
| BL-FND-12 | Cursor pagination | `CursorCodec`(`(sortKey, id)` ↔ base64url), `CursorPage<T>`, 잘못된 cursor 400 `INVALID_CURSOR` | P0 | S1 | BL-FND-08 | — | NFR-02 |
| BL-FND-13 | Idempotency | `IdempotencyService`(`03` §5.4) + 인증 `POST` 헤더 필수 검사(400 `IDEMPOTENCY_KEY_REQUIRED`, replan preview만 선택), canonical JSON hash, `Idempotent-Replayed` 헤더, 예외 시 record 삭제 | P0 | S1 | BL-FND-08, BL-FND-14 | AC-23 | NFR-04 |
| BL-FND-14 | Flyway V2·V3 | `V2__user_career_skill.sql`, `V3__plan.sql`. 내용은 `database/schema.sql` 해당 부분과 동일 | P0 | S1 | BL-FND-06 | AC-01 | FR-03, FR-04 |
| BL-FND-15 | Flyway V4 | `V4__learning_today_review.sql` | P0 | S2 | BL-FND-14 | AC-02, AC-05 | FR-07, FR-11 |
| BL-FND-16 | Flyway V5 | `V5__training.sql` | P0 | S3 | BL-FND-15 | AC-04 | FR-09 |
| BL-FND-17 | Flyway V6 | `V6__coach.sql` | P1 | S4 | BL-FND-16 | AC-06 | FR-12 |
| BL-FND-18 | Flyway V7 | `V7__evidence_weekly.sql` | P1 | S5 | BL-FND-17 | AC-21 | FR-17, FR-18 |
| BL-FND-19 | Flyway V8 | `V8__job_radar.sql` | P1 | S7 | BL-FND-18 | AC-22 | FR-19 |
| BL-FND-20 | 구조화 로그·감사 로그 | prod JSON structured logging, `AuditLogger`(감사 이벤트 목록은 `07-security-and-privacy.md`), `userRef` = HMAC 앞 12 hex, `DEVPILOT_LOG_HASH_KEY` 없으면 prod 기동 실패 | P0 | S1 | BL-FND-07 | AC-08 | NFR-06 |
| BL-FND-21 | 프로필 API | `MeController`, `ProfileService`. `GET /me`(profile, onboardingCompleted, `aiStatus`, `aiUsage` — S3 전에는 provider `disabled`이므로 `aiStatus=DISABLED`, `aiUsage`는 호출 0·월 비용 0·예산값. record는 BL-AIP-16), `PATCH /me`(displayName, timezone IANA 검증, dayStartHour 0~6, weekday/weekendStudyMinutes 0~720, version) | P0 | S1 | BL-SEC-04, BL-FND-10, BL-AIP-16 | AC-17 | FR-24 |
| BL-FND-22 | OpenAPI 스냅샷 | springdoc(Swagger UI는 local만), `docs/api/openapi.yaml` 생성 task, `./gradlew openApiCheck`로 스냅샷 diff 발생 시 CI 실패. `ci.yml` `backend` job이 S0부터 실행하므로 S0 | P0 | S0 | BL-FND-03, BL-OPS-06 | — | NFR-07 |
| BL-FND-23 | 비동기 실행기·AI 작업 공통 | `AsyncConfig`(`aiTaskExecutor` core 2 / max 2 / queue 20), 비동기 AI task 템플릿(`@TransactionalEventListener(AFTER_COMMIT)` + `@Async`, `PENDING → RUNNING → COMPLETED/FAILED`, `AsyncFailureCode` 매핑, 최상위 catch 1곳), `common.job.OrphanAsyncTaskSweeper` port 정의 + `OrphanAsyncTaskJob`(`common.job`, 기동 1회 + 10분, `RUNNING` 10분 초과 → `FAILED(INTERRUPTED)`). job은 `List<OrphanAsyncTaskSweeper>`만 주입받고 도메인 모듈을 직접 의존하지 않는다(`03` §2.2 규칙 4, ARCH-01). 구현은 coach·training·review(Later)·evidence·job이 각자 한다 | P0 | S3 | BL-FND-25, BL-FND-16 | AC-12 | NFR-03 |
| BL-FND-24 | `RetentionCleanupJob` | `common.job.RetentionCleanupTarget` port 정의 + `RetentionCleanupJob`(`common.job`): 만료 `idempotency_record` 삭제(자기 소유) + 주입받은 target 전부 호출 + 전날 AI 호출·비용·오류·job 실패 수 일일 요약 INFO 1줄(`dailySummary`). `ai_call_log` 180일 삭제는 `integration.ai.log.AiCallLogRetentionService`가 구현한다 — `common`은 도메인 모듈을 의존하지 않는다(`03` §2.2 규칙 4, ARCH-01) | P1 | S3 | BL-FND-25, BL-AIP-07 | — | NFR-05, NFR-06 |
| BL-FND-25 | 스케줄 job 공통 규약 | `@EnableScheduling`, test profile 스케줄러 비활성, job 시작·건수·소요시간 INFO 1줄, 실패 `JOB_FAILED` WARN, 사용자 단위 트랜잭션 분리 템플릿 | P0 | S3 | BL-FND-20 | — | NFR-06 |
| BL-FND-26 | Job 지표 | `devpilot.jobs.runs{job,result}` Micrometer 지표 (외부 비노출). AI 지표는 BL-AIP-07 | P2 | S3 | BL-FND-25 | — | NFR-06 |

### 4.2 SEC — Security · Privacy

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-SEC-01 | ~~취소~~ SP-5 Supabase Auth 단독 운용 spike | 2026-09-18 취소(결정 A: 운영 인증도 devtoken). 내용은 BL-SEC-18(Later)이 흡수 | — | ~~S0~~ | — | — | — |
| BL-SEC-02 | ~~취소~~ Supabase 하드닝 | 2026-09-18 취소. 내용(GitHub OAuth provider, 가입 비활성, Data API 비활성, publishable key)은 BL-SEC-18(Later)이 흡수 | — | ~~S0~~ | — | — | — |
| BL-SEC-03 | JWT resource server | `SecurityConfig`: `devpilot.security.auth-mode`로 `JwtDecoder` 선택 — `devtoken`(기본·운영)은 앱이 가진 EC P-256 공개키로 `NimbusJwtDecoder.withPublicKey`(JWKS HTTP 조회 없음), `supabase`(Later)는 JWKS·`jws-algorithms`; issuer·`aud=authenticated`, clock skew 60초, STATELESS, CSRF 비활성, CORS local만, 인증 제외 경로(health, `calendar/*.ics`, devtoken 모드의 `/dev/**`, local api-docs), 401 `AUTHENTICATION_REQUIRED` ProblemDetail. `spring.security.oauth2.resourceserver.jwt.*`는 supabase 모드에서만 쓰고 `${SUPABASE_URL:}` 기본값을 비워 기동이 막히지 않게 한다 | P0 | S0 | BL-FND-03 | AC-08, AC-25 | FR-01 |
| BL-SEC-04 | 사용자 프로비저닝·allowlist | `UserProvisioningService`(`03` §4.3: ON CONFLICT, allowed-emails/subjects, 요청마다 재확인, `AUTH_USER_PROVISIONED`/`AUTH_USER_REJECTED`), `UserContextFilter`, `CurrentUser`, `CurrentUserArgumentResolver`, `DELETION_REQUESTED` 사용자 403 `FORBIDDEN` | P0 | S1 | BL-SEC-03, BL-FND-14, BL-FND-20 | AC-18 | FR-01 |
| BL-SEC-05 | 사용자 격리 테스트 하네스 | 사용자 소유 endpoint 목록 기반 파라미터화 테스트: 타 사용자 ID → 404, 목록 응답에 타 사용자 항목 0건, 상태 변경 없음. Sprint마다 새 endpoint를 목록에 추가 | P0 | S1 | BL-SEC-04 | AC-08 | NFR-04 |
| BL-SEC-06 | 로그 민감정보 차단 | Authorization 헤더·요청/응답 body·사용자 코드·AI 프롬프트·이메일 미기록 검증 테스트(로그 캡처), calendar 토큰 경로 `…/calendar/****.ics` 마스킹 | P0 | S1 | BL-FND-20 | AC-08 | NFR-05, NFR-06 |
| BL-SEC-07 | Caddy 보안 헤더 | HSTS, `X-Content-Type-Options`, `Referrer-Policy`, `X-Frame-Options DENY`, `Permissions-Policy`, `-Server`, `/actuator/*`(health 제외) 404, CSP는 Report-Only로 시작 | P0 | S0 | BL-OPS-05 | AC-08 | NFR-04 |
| BL-SEC-08 | CSP 강제 전환 | S2 실사용 시작(2026-10-26) 후 1주 동안 Report-Only 위반 0건 확인 → 헤더를 `Content-Security-Policy`로 전환. 절차는 `07-security-and-privacy.md` | P1 | S3 | BL-SEC-07, BL-CLI-01 | AC-08 | NFR-04 |
| BL-SEC-09 | Secret scanning · S0 보안 도구 | GitHub secret scanning + push protection 활성(DEC-04), CI gitleaks job(DeepSeek 키 규칙 `sk-` + hex 32자 포함), third-party action commit SHA 고정 + `actions-pin-check`, Dependabot(gradle, pub, github-actions; 주 1회), `.env`·`config/*.json`(example 제외)·`DevPilot-ops/` ignore | P0 | S0 | BL-FND-02 | — | NFR-04 |
| BL-SEC-10 | 의존성·이미지 스캔 | Trivy fs(CI `security` job)·Trivy image(`release.yml`, 수정 가능한 CRITICAL/HIGH 실패), CodeQL(Java), Dockerfile base image digest 고정. S0 도구는 BL-SEC-09까지만 | P1 | S2 | BL-OPS-06, BL-OPS-07 | — | NFR-04 |
| BL-SEC-11 | Rate limit | `RateLimitFilter` + `TokenBucketRateLimiter`: JWT `sub`당 120 req/min, calendar 유효 토큰 60회/시간, 무효 토큰 IP당 30회/시간, 초과 429 `RATE_LIMITED` + `Retry-After` (`07-security-and-privacy.md`) | P1 | S2 | BL-SEC-04 | AC-08 | NFR-04 |
| BL-SEC-12 | 운영 계정 보안 | GitHub, DeepSeek 플랫폼, Tailscale, healthchecks.io 계정 2FA/passkey(지원하는 곳), 서버 SSH 키 로그인만, DeepSeek API 키 1개(prod·eval 공용 잔액, 결정 E)·선불 소액 유지, 접속 정보는 저장소 밖 `DevPilot-ops/`에만 (수동 체크리스트) | P0 | S0 | — | — | NFR-04 |
| BL-SEC-13 | 데이터 export | `account` 모듈 `AccountExportService` + `GET /me/export`: 사용자 소유 aggregate 전체 JSON, 타 사용자 데이터 0건, `calendar_token_hash`·`idempotency_record` 제외, `DATA_EXPORTED` 감사 로그 | P1 | S6 | BL-FND-21 | AC-15 | FR-23, NFR-05 |
| BL-SEC-14 | 계정 삭제 요청 | `AccountDeletionService` + `DELETE /me`(`amr[].timestamp` 최댓값 — devtoken은 발급 시각 — 5분 초과 403 `RECENT_LOGIN_REQUIRED`, `DELETION_REQUESTED`, 캘린더 토큰 null, 202, `ACCOUNT_DELETION_REQUESTED` 감사 로그). 이후 `GET /me`·`DELETE /me` 외 403(BL-SEC-04). 실제 삭제 job은 BL-SEC-17(Later) | P1 | S1 | BL-SEC-04 | AC-15 | FR-23, NFR-05 |
| BL-SEC-15 | 하드닝 점검 | `07-security-and-privacy.md` 체크리스트 전체 점검, OWASP Top 10 대응표 갱신, AC-08·AC-18·AC-25 전체 재검증(AC-20은 Supabase 도입 시) | P1 | S6 | BL-SEC-05, BL-SEC-08 | AC-08, AC-18, AC-25 | NFR-04 |
| BL-SEC-16 | devtoken 모드 백엔드 | `DevTokenController` + `DevTokenService`(`auth-mode=devtoken`일 때만 bean): EC P-256 키(`DEVPILOT_DEV_JWT_KEY` PEM, 비면 기동 시 생성 → 재기동 시 기존 토큰 무효, prod는 필수), `POST /api/v1/dev/token {email}` → 200 `{accessToken, expiresAt}`(permitAll, allowlist 검사, 불허 403 `USER_NOT_ALLOWED`, IK 불필요), `GET /api/v1/dev/jwks.json`(permitAll). JWT `iss=${APP_BASE_URL}/dev`, `aud=authenticated`, `sub=uuid v5(email)`, `email`, `amr=[{method:"devtoken",timestamp}]`, ttl 720h. `JwtDecoder`는 같은 키의 공개키로 직접 구성. test profile은 `TestJwksServer` 대신 이 키를 공유(`09` §6.2). **비공개 네트워크 배포 전용** — tailnet 밖 노출 없음이 전제이고(`07` §3), 공개 노출 전에 `auth-mode=supabase`로 전환한다(`BL-SEC-18`, `03` §4.2). prod + devtoken이면 기동 시 WARN 1줄 | P0 | S0 | BL-SEC-03 | AC-25, AC-18 | FR-01, NFR-04 |
| BL-SEC-17 | 계정 삭제 job | `AccountDeletionJob`(5분 주기, `DELETION_REQUESTED` 사용자 cascade 삭제, `ai_call_log.user_id=null`, `ACCOUNT_DELETION_COMPLETED` 감사 로그). 그 전까지는 `account-deletion` runbook(allowlist 제거 + 수동 SQL) | P3 | Later | BL-SEC-14, BL-FND-25 | AC-15 | FR-23, NFR-05 |
| BL-SEC-18 | Supabase Auth 도입 | `auth-mode=supabase` 활성: Supabase 프로젝트·GitHub OAuth provider·가입 비활성·Data API 비활성(DEC-15)·publishable key만 클라이언트 사용, `SUPABASE_URL`·`SUPABASE_JWT_ALGORITHM`, JWKS 검증 경로, Flutter `AUTH_MODE=supabase`(SCR-LOGIN GitHub 버튼, SCR-AUTH-CALLBACK), `account-deletion` runbook에 Auth 사용자 수동 삭제 추가, AC-20 S2·S3, 구 SP-5 절차를 spike로 재실행. BL-SEC-01·02 흡수. **공개 노출의 필수 선행 조건** — `devtoken`은 비공개 배포 전용이다(ADR-033, `03` §4.2). 착수 시점은 Sprint가 아니라 공개 전환 게이트가 정한다(`11` §3.10) | P0 | 공개 배포 전 | BL-SEC-03 | AC-20 | FR-01, NFR-04 |

### 4.3 OPS — Deploy · Ops

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-OPS-01 | SP-2 서버 PG16 + 원격 Docker Testcontainers | 서버 PostgreSQL 16(`devpilot` DB/role, TLS 없음)에 전체 migration 적용, `dev-docker-tunnel.ps1`(SSH 소켓 포워딩, `DOCKER_HOST`·`TESTCONTAINERS_HOST_OVERRIDE`)로 Testcontainers `postgres:16` 실행 — **2026-09-18 검증 완료**. 남은 것: Hikari 동시 20요청 확인, DO 블록 no-op 확인(BL-FND-06). 절차는 `11-development-roadmap.md` §4 SP-2, `18` §3 | P0 | S0 | — | — | NFR-03 |
| BL-OPS-02 | SP-3 amd64 이미지 → GHCR → 서버 pull + Tailscale HTTPS | `ubuntu-24.04` runner에서 linux/amd64 이미지 빌드 → GHCR → 서버 `deploy.sh` pull → Caddy `127.0.0.1:18080`(TLS 없음) → `tailscale serve --bg --https=443` → tailnet 안 유효 인증서 접속, 자동 롤백, 메모리(`-Xmx1g`, `mem_limit 1.5g`) 확인. 절차는 `11-development-roadmap.md` §4 SP-3 | P0 | S0 | BL-OPS-04 | — | NFR-10 |
| BL-OPS-03 | ~~취소~~ 도메인·DNS | 2026-09-18 취소(DEC-07: 도메인 미사용, Tailscale MagicDNS 호스트명 `https://<tailnet-host>` 사용) | — | ~~S0~~ | — | — | — |
| BL-OPS-04 | 서버 준비 `prepare-server.sh` | 기존 자체 서버(Rocky 9.8 x86_64, 2 vCPU/8GB 공용, Docker 29.6.1, Tailscale 1.98.8)에서 root 1회 멱등 실행: 전제 조건 확인(docker, tailscale, 18080 비어 있음) → `deploy` 사용자(+docker 그룹) → `/opt/devpilot/{backups,web}` + `api.env`·`ops.env` 템플릿(0600) → systemd 유닛(`devpilot-backup`, `devpilot-healthping`) 설치·enable → 안내 출력. OS 설정(daemon.json, podman, sshd, firewalld, dnf-automatic, `tailscale up`)은 건드리지 않는다(공용 서버). 구 `bootstrap-vm.sh` 삭제. 사용자 직접 작업: tailnet MagicDNS + HTTPS Certificates 활성화, `tailscale serve` 1회 | P0 | S0 | — | — | NFR-03 |
| BL-OPS-05 | 이미지·compose·Caddy | `Dockerfile`(temurin 25 JRE, 현재 빌드는 amd64 — 공개 전환 시 arm64 추가, `11` §3.10; 비root), `compose.prod.yml`(api: publish 없음, `JAVA_TOOL_OPTIONS=-Xmx1g`, `mem_limit 1.5g`, read_only, no-new-privileges; caddy: `127.0.0.1:18080:80`만 publish, `mem_limit 128m`; ACME·80/443·443/udp·certs 볼륨·`DOMAIN`·`SUPABASE_HOST` 없음), `Caddyfile`(TLS 없음, 보안 헤더, 정적 파일 `/srv/web` no-cache·SPA rewrite, `/api/*`·`/actuator/health` → `api:8080`), `/opt/devpilot/api.env` 권한 600 | P0 | S0 | BL-OPS-04, BL-FND-03 | — | NFR-10 |
| BL-OPS-06 | CI `ci.yml` | job 4개 = branch protection 필수 check(`main`·`developer` 둘 다) `security`(actions SHA 고정 검사, gitleaks — Trivy fs는 S2 BL-SEC-10), `backend`(`spotlessCheck check`, `openApiCheck`), `app`(format, analyze, `app/tool/check_identifiers.sh`, test, `build web`), `content`(`python3 content/tools/validate_content.py`). 트리거: `main`·`developer` push + 두 브랜치 대상 PR | P0 | S0 | BL-FND-04, BL-CLI-02, BL-OPS-21 | — | NFR-07 |
| BL-OPS-07 | CD `release.yml` + 수동 `deploy.sh` | 태그 `v0.<sprint>.<patch>` push → `ubuntu-24.04` runner → Flutter web 빌드(릴리스 아티팩트 zip) → 백엔드 이미지 linux/amd64(현재 서버) → GHCR `ghcr.io/<owner>/devpilot-api:<tag>`(Trivy image는 S2). 공개 전환 시 `linux/amd64,linux/arm64` 멀티아치로 바꾼다(OCI Always Free는 Ampere arm64, `11` §3.10). 배포는 로컬에서 `ssh <server>` → `sudo -u deploy /opt/devpilot/deploy.sh v0.x.y`(web zip → `/opt/devpilot/web`, GHCR pull, `docker compose -f /opt/devpilot/compose.prod.yml up -d`, `curl http://127.0.0.1:18080/actuator/health` 60초, 실패 시 이전 태그 롤백) → `infra/scripts/smoke-headers.sh`(서버 안 `127.0.0.1:18080` 기준). 구 `deploy.yml` 삭제. Actions → tailnet 자동 배포는 BL-OPS-22(Later) | P0 | S0 | BL-OPS-05 | AC-08 | NFR-10 |
| BL-OPS-08 | ~~취소~~ Tailscale 배포 경로 | 2026-09-18 취소(결정 D: CI OAuth client·`tag:ci` ACL·Tailscale SSH는 Later BL-OPS-22). 운영자 접속은 이미 Tailscale, 공개 SSH 없음 | — | ~~S0~~ | — | — | — |
| BL-OPS-09 | 로컬 개발 환경 | `local` profile은 `DATABASE_URL/USERNAME/PASSWORD` 필수(기본값 없음, 서버 PG16을 Tailscale 경유로 사용), `infra/scripts/dev-docker-tunnel.ps1`(서버 Docker 소켓 포워딩 — Docker Desktop 불필요), `infra/compose.dev.yml`(오프라인 대체, `postgres:16`, 포트 55432), `.env` import, Flutter `config/local.example.json`(`AUTH_MODE=dev`). 절차는 `18-project-setup-and-local-dev.md` | P0 | S0 | BL-FND-03 | — | NFR-07 |
| BL-OPS-10 | Runbook: 배포·롤백 | 태그 → `release.yml` 확인 → `deploy.sh` 실행, 수동 롤백 명령(`deploy.sh <이전 태그>`), migration 포함 배포 전 `backup.sh` 1회 실행 (`10-deployment-and-operations.md`) | P0 | S0 | BL-OPS-07 | — | NFR-03 |
| BL-OPS-11 | 백업 자동화 | `infra/scripts/backup.sh`(`pg_dump -Fc` → `/opt/devpilot/backups/devpilot-<UTC ts>.dump`, 7일 보관), systemd `devpilot-backup.timer` 매일 19:00 UTC, 로컬 PC `infra/scripts/pull-backup.ps1` 주 1회 scp pull → `%USERPROFILE%\DevPilot-backups\`(8주 보관), `db-restore` 절차(`pg_restore --clean --if-exists --no-owner -d devpilot`)로 로컬 복구 1회 확인. 오브젝트 스토리지·rclone·age 없음(tailnet 내부). 실사용 시작(10-26) 전에 활성 | P0 | S2 | BL-OPS-01, BL-OPS-04 | — | NFR-03, NFR-05 |
| BL-OPS-12 | Runbook: 서버·DB 복구 | `server-restore`(서버 재설치 시 `prepare-server.sh` → `tailscale serve` → `api.env` 복원 → `deploy.sh` → `db-restore`), `db-restore`(로컬 사본 또는 서버 `backups/`에서 `pg_restore`) | P0 | S2 | BL-OPS-11 | — | NFR-03 |
| BL-OPS-13 | 헬스 모니터(healthchecks.io) | `infra/scripts/healthping.sh` + `devpilot-healthping.timer`(5분): `http://127.0.0.1:18080/actuator/health` 200이면 `HEALTHCHECKS_PING_URL`(`/opt/devpilot/ops.env`) GET, 실패면 `${HEALTHCHECKS_PING_URL}/fail`. healthchecks.io 누락·실패 알림 이메일. 외부 uptime 서비스 없음(tailnet 전용이라 외부에서 닿지 않음) | P1 | S2 | BL-OPS-04 | — | NFR-03 |
| BL-OPS-14 | ~~취소~~ 무료 플랜 운영 점검 | 2026-09-18 취소(Supabase·OCI 미사용). 공용 서버 자원 점검은 BL-OPS-16 `host-check.sh` | — | ~~S2~~ | — | — | — |
| BL-OPS-15 | Runbook: DeepSeek 키 유출 | `incident-api-key-leak`: platform.deepseek.com에서 키 삭제 → 새 키 발급 → `api.env`·GitHub `ai-eval` secret 교체 → `ai_call_log` 대비 콘솔 사용량 확인(잔액이 소액이라 피해 상한) → git 이력 조치 판단. prod AI 활성화 전 완료 | P0 | S3 | BL-AIP-15 | AC-13 | NFR-04 |
| BL-OPS-16 | 백업·호스트 운영 점검 | healthchecks.io 알림 실제 수신 확인, 서버 `backups/` 7일·로컬 8주 보관 개수 확인, `pull-backup.ps1` 주 1회 실행 기록. 호스트 점검: `infra/scripts/host-check.sh`(디스크·컨테이너 상태·`tailscale serve status`; 메모리 <20% 규칙·127.0.0.1:443 검사 없음) (`10-deployment-and-operations.md` §11) | P1 | S6 | BL-OPS-11, BL-OPS-13 | — | NFR-03, NFR-05 |
| BL-OPS-17 | 복구 리허설 | 로컬 PC 사본을 `compose.dev.yml` PostgreSQL 16에 `pg_restore` → 테이블별 행 수·최신 `learning_event.occurred_at` 비교 → 기록표. 이후 월 1회 | P0 | S6 | BL-OPS-11 | — | NFR-03 |
| BL-OPS-18 | Runbook: 키 교체·계정 삭제 | `secret-rotation`(DB 비밀번호, DeepSeek key, devtoken 서명 키 `DEVPILOT_DEV_JWT_KEY` — 교체 시 전체 재로그인, `DEVPILOT_LOG_HASH_KEY`), `account-deletion`(allowlist 제거 + 재기동 + 수동 SQL 삭제; Supabase 도입 시 Auth 사용자 수동 삭제 추가), `db-restore` 리허설 결과 반영 | P1 | S6 | BL-SEC-14, BL-OPS-17 | AC-15 | NFR-05 |
| BL-OPS-19 | 성능 스모크 | prod에서 non-AI 주요 API(`GET /today`, `GET /reviews/due`, `GET /plans/active`, `GET /dashboard`) 각 50회 → p95 < 1000ms 확인 | P2 | S2 | BL-TDY-08, BL-MEM-05 | — | NFR-02 |
| BL-OPS-20 | 데모 모드 | `demo` profile: 가상 사용자·4주 샘플 데이터, `FakeAiProvider`, 쓰기 요청 차단 | P3 | Later | — | — | — |
| BL-OPS-21 | git 전략·developer 보호·CI 트리거 | 브랜치 `feature/BL-<EPIC>-<nn>-<슬러그>`·`fix/`·`chore/`·`docs/` → `developer`(squash merge) → `main`(PR + merge commit), 태그 `v0.<sprint>.<patch>`는 `main`에서만, Conventional Commits(영문), PR 제목에 BL ID. GitHub branch protection: `main`·`developer` 둘 다 PR 필수 + 필수 check 4개 + 직접 push 금지. `.github/pull_request_template.md`(`16` §3), `ci.yml` 트리거 두 브랜치 | P0 | S0 | BL-FND-02 | — | NFR-07 |
| BL-OPS-22 | Actions → tailnet 자동 배포 | Tailscale OAuth client + ACL 태그 + 노드 태깅 + Tailscale SSH로 `release.yml`이 `deploy.sh`를 직접 실행. 수동 배포가 월 4회를 넘거나 실수가 생기면 착수 | P3 | Later | BL-OPS-07 | — | NFR-10 |

### 4.4 CLI — Flutter Client

화면 ID·라우트·상태 UI·문구는 `02-user-scenarios-and-ux.md`가 기준이다.

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-CLI-01 | SP-1 Flutter Web 한글 입력 spike | 한글 IME 조합·커서·붙여넣기, 코드 붙여넣기, 폰트 번들, 첫 로드 시간 확인. 절차는 `11-development-roadmap.md` §4 SP-1 | P0 | S0 | — | AC-10 | NFR-08 |
| BL-CLI-02 | Flutter bootstrap | FVM 버전 고정, `flutter_riverpod`, `go_router`, `dio`, `freezed`/`json_serializable`, ARB l10n(ko), 한글 폰트 번들, `--dart-define=AUTH_MODE=dev\|supabase`(기본 `dev`; `supabase_flutter`는 BL-SEC-18 — 공개 전환 게이트), lint 경고 0건 | P0 | S0 | BL-CLI-01 | — | NFR-08 |
| BL-CLI-03 | Walking skeleton 화면 · dev 로그인 | SCR-LOGIN dev 모드(이메일 입력 1칸 + 로그인 버튼 → `POST /api/v1/dev/token` → 토큰을 메모리 + `sessionStorage`에 보관 → `GET /me`; 403 → SCR-NOT-ALLOWED; 초대 시 1회 DeepSeek 안내 문구), `AuthInterceptor`(Bearer, 401이면 토큰 삭제 → `/login?reason=expired`), SCR-NOT-FOUND, 로그인 후 `GET /api/v1/me` 결과 표시, widget test 1개(`login_screen_test.dart`). SCR-AUTH-CALLBACK·GitHub 버튼은 supabase 모드(Later) | P0 | S0 | BL-CLI-02, BL-SEC-16 | AC-25 | FR-01 |
| BL-CLI-04 | 앱 셸 | go_router redirect 규칙(세션·allowlist·온보딩), SCR-NOT-ALLOWED, 반응형 내비(모바일 하단 탭 / 데스크톱 rail), 테마 토큰, 360px 폭 대응 | P0 | S1 | BL-CLI-03 | AC-10, AC-18 | NFR-08 |
| BL-CLI-05 | API 클라이언트 | dio interceptor: Bearer, `Idempotency-Key`(사용자 행동당 UUID v4, 네트워크 재시도는 같은 키), `X-Trace-Id`, Problem Details `code` 분기, 알 수 없는 enum → `unknown`. OpenAPI 스냅샷 기준 수기 freezed 모델(DEC-12) | P0 | S1 | BL-CLI-03, BL-FND-22 | AC-23 | NFR-07 |
| BL-CLI-06 | 공통 상태 UI | loading skeleton, empty(다음 행동 1개), error(`detail` + 문제 신고 영역의 traceId), 409 `CONCURRENT_MODIFICATION` 새로고침 안내 | P0 | S1 | BL-CLI-05 | AC-08 | NFR-08 |
| BL-CLI-07 | 온보딩 화면 | SCR-ONBOARDING 4단계(목표 → 시간·하루 시작 시각 → 카테고리 자기평가 13개 → 계획 확인) | P0 | S1 | BL-CLI-04, BL-CAR-06 | AC-11 | FR-02, FR-24 |
| BL-CLI-08 | Plan 화면 | SCR-PLAN(타임라인, milestone status/description/순서 PATCH), SCR-CAREER-GOAL, SCR-PLAN-HISTORY, SCR-PLAN-VERSION | P0 | S1 | BL-CAR-01, BL-CAR-02, BL-CAR-04 | AC-01 | FR-03, FR-04 |
| BL-CLI-09 | Replan 화면 (저장) | SCR-REPLAN: milestone 추가·삭제·날짜·skill 편집 → 새 버전 저장, milestone id mapping 반영 | P0 | S1 | BL-CAR-05 | AC-01, AC-24 | FR-04 |
| BL-CLI-10 | Skill 화면 | SCR-SKILL-TREE(카테고리 트리), SCR-SKILL-DETAIL(축별 evidence·planning 레벨 막대 + 목표선). 이력은 BL-CLI-22 | P1 | S1 | BL-SKL-01, BL-SKL-02 | AC-09 | FR-06 |
| BL-CLI-11 | Settings 기본 | SCR-SETTINGS: 표시 이름, timezone, 하루 시작 시각(변경 영향 안내), 평일·주말 학습 시간 | P0 | S1 | BL-FND-21 | AC-17 | FR-24 |
| BL-CLI-12 | Today 화면 | SCR-TODAY: 시간 칩·컨디션 → 생성, main task 1개 + reasons + REVIEW task, 시작·완료(세션 `actualMinutes`, 회고)·건너뛰기·미루기, 재생성 409 처리, 복귀 모드 문구 | P0 | S2 | BL-TDY-07, BL-TDY-08, BL-TDY-09, BL-TDY-10 | AC-02, AC-17 | FR-07, FR-08, FR-21 |
| BL-CLI-13 | Review 화면 | SCR-REVIEW-HOME, SCR-REVIEW-SESSION: 카드 1장씩, 답 입력, "힌트 보기"(rubric 첫 항목, `CONCEPT_HINT`)·"정답 먼저 보기"(`FULL_EXAMPLE`), 답 확인 → 자기평가 4버튼, `adjustedBy`·다음 due 표시 | P0 | S2 | BL-MEM-05, BL-MEM-06 | AC-05, AC-10 | FR-11, NFR-08 |
| BL-CLI-14 | 복습 카드 관리 화면 | SCR-REVIEW-ITEMS(skill·status 필터), SCR-REVIEW-ITEM-EDIT(수동 생성·수정·일시중지·보관). 2026-09-18 S2 → S3(수동 카드 CRUD 범위 축소) | P1 | S3 | BL-MEM-07 | AC-05 | FR-11 |
| BL-CLI-15 | Dashboard 최소 화면 | SCR-DASHBOARD: 오늘 상태, due 수, 최근 7 plan-day 학습 시간, 현재 milestone | P0 | S2 | BL-TDY-11 | AC-02 | FR-16 |
| BL-CLI-16 | More 화면 | SCR-MORE(모바일 폭 전용 진입 목록, 폭 ≥ 600이면 `/today` redirect) | P0 | S2 | BL-CLI-04 | AC-10 | NFR-08 |
| BL-CLI-17 | PWA | manifest, 아이콘, 홈 화면 추가 안내, 배포 후 새 버전 반영 확인(no-cache) | P0 | S2 | BL-OPS-05 | AC-10 | NFR-08 |
| BL-CLI-18 | 캘린더 구독 설정 | SCR-SETTINGS 캘린더 구독 URL 발급·재발급(평문 URL은 발급 응답에서만 표시). 2026-09-18 S2 → S3 | P1 | S3 | BL-TDY-13 | — | FR-20 |
| BL-CLI-19 | UI 통합 테스트 | Flutter `integration_test`: 온보딩 → Today 생성 1개 흐름 | P1 | S2 | BL-CLI-07, BL-CLI-12 | AC-02, AC-11 | NFR-07 |
| BL-CLI-20 | AI 공통 UI | AI unavailable 배너, `aiStatus`·`aiUsage` 표시(SCR-SETTINGS 포함), `DISABLED`·`BALANCE_EXHAUSTED`("AI 잔액 소진" 배지·사유 문구) 시 AI 진입 버튼 비활성, `BUDGET_WARNING` 안내, 비동기 진행 표시(2초 polling, 최대 3분). enum 미지 값은 `unknown` | P0 | S3 | BL-AIP-10, BL-AIP-16 | AC-12, AC-13 | FR-22, NFR-03 |
| BL-CLI-21 | Training 화면 | SCR-TRAINING-LIST(목록·생성 요청 polling), SCR-CHALLENGE-DETAIL, SCR-TRAINING-ATTEMPT(self-explanation/건너뛰기, Hint Ladder 다음 단계 버튼, `PSEUDOCODE` 이상 확인 대화상자, 제출·평가 polling·retry, rubric 결과) | P0 | S3 | BL-TRN-02, BL-TRN-05, BL-TRN-08, BL-TRN-09 | AC-04, AC-16 | FR-09, FR-10 |
| BL-CLI-22 | Skill 이력 | SCR-SKILL-DETAIL 레벨 변경 이력(rule_code, 근거 이벤트 요약) | P1 | S3 | BL-SKL-06 | AC-09 | FR-06 |
| BL-CLI-23 | 진단 제안 화면 | SCR-DIAGNOSTICS(건너뛰기 가능 카드, 시작 시 attempt 생성) | P1 | S3 | BL-TRN-13 | AC-11 | FR-15 |
| BL-CLI-24 | Coach 화면 | SCR-COACH-LIST, SCR-COACH-NEW(붙여넣기, 동의 체크 + DeepSeek 동의 문구 "코드는 AI 공급자 DeepSeek(중국 소재)로 전송되며, 입력을 학습에 쓰지 않는다는 약정이 없습니다. 회사 코드를 붙여넣지 마세요.", self-review, `maskedSecretCount`), SCR-COACH-DETAIL(polling·retry — `AI_REFUSED`는 retry 불가 안내, finding 배지: type·category·verification·confidence 텍스트, 응답·피드백, hint, 해결/해당 없음, 완료, 원문 삭제) | P1 | S4 | BL-COA-02, BL-COA-04, BL-COA-06, BL-COA-09, BL-COA-10 | AC-06, AC-07, AC-14, AC-19 | FR-12, FR-14 |
| BL-CLI-25 | Replan 미리보기 | SCR-REPLAN: 미리보기(risk, `ratioBp`, defer·축소 제안 체크, `riskAfterSuggestions`) → 새 버전 저장, SCR-PLAN budget·risk 표시 | P0 | S5 | BL-CAR-11, BL-CAR-12, BL-CAR-13 | AC-03 | FR-05 |
| BL-CLI-26 | Dashboard 완성·Weekly | SCR-DASHBOARD(risk 추세, skill 카테고리 요약, 약한 thinking 축 Top 3), SCR-WEEKLY-LIST, SCR-WEEKLY-DETAIL(지표, 회고 작성) | P1 | S5 | BL-TDY-12, BL-EVD-03, BL-EVD-04 | AC-19, AC-21 | FR-13, FR-16, FR-17 |
| BL-CLI-27 | Evidence 화면 | SCR-EVIDENCE-LIST, SCR-EVIDENCE-DETAIL(수동 작성, AI 초안 polling, 편집, accept/reject, Markdown export 다운로드) | P1 | S6 | BL-EVD-05, BL-EVD-06, BL-EVD-07, BL-EVD-08 | AC-21 | FR-18 |
| BL-CLI-28 | Export·계정 삭제 화면 | SCR-SETTINGS export 다운로드, SCR-ACCOUNT-DELETE(403 `RECENT_LOGIN_REQUIRED` → 재로그인(dev 모드: `/api/v1/dev/token` 재발급으로 새 `amr` timestamp) → 자동 재요청, 202 후 로그아웃) | P1 | S6 | BL-SEC-13, BL-SEC-14 | AC-15 | FR-23 |
| BL-CLI-29 | Job Radar 화면 | SCR-JOBS-LIST, SCR-JOB-NEW, SCR-JOB-DETAIL(분류별 개수·목록만, 확률·점수·퍼센트 없음) | P1 | S7 | BL-JOB-02, BL-JOB-03 | AC-22 | FR-19 |
| BL-CLI-30 | Android 앱 | Android 빌드·서명·배포 (DEC-18) | P3 | Later | — | — | — |
| BL-CLI-31 | 세션 완료 화면 즉시 진전 표시 | (검토 제안, 미결정) 세션 완료 직후 오늘 학습 시간·연속 일수·이번 주 완료 세션 수를 완료 시트에 바로 표시. 사용자 결정 후 착수 | P3 | Later | BL-CLI-12 | — | FR-08, FR-16 |

### 4.5 CAR — Career · Plan

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-CAR-01 | 커리어 목표 API | `CareerGoal`, `CareerGoalFocusSkill`, `CareerGoalService`, `CareerGoalQueryService`. `GET /career-goal`(없으면 404 `CAREER_GOAL_NOT_FOUND`), `PUT /career-goal`(version, 날짜 검증, 날짜 변경 시 활성 plan `replan_recommended = true` — application event로 전달) | P0 | S1 | BL-FND-14, BL-SKL-01 | AC-01 | FR-03 |
| BL-CAR-02 | Plan 조회 API | `PlanQueryService`. `GET /plans/active`(milestones + skillTargets + latest snapshot, 없으면 404 `PLAN_NOT_FOUND`), `GET /plans?cursor=`, `GET /plans/{planId}`(SUPERSEDED 포함) | P0 | S1 | BL-FND-14, BL-FND-12 | AC-01 | FR-04 |
| BL-CAR-03 | Plan 템플릿 생성 서비스 | `PlanCommandService.createFromTemplate`(온보딩 내부 호출 전용): 활성 plan 없을 때 템플릿으로 v1 생성, 있으면 `ACTIVE_PLAN_EXISTS`. `role_skill_target` → `plan_skill_target` 복사(`ROLE_DEFAULT`). 공개 endpoint `POST /plans`는 MVP에서 호출 경로가 없어 Later(BL-CAR-16) | P0 | S1 | BL-CAR-02, BL-CNT-05 | AC-01 | FR-04 |
| BL-CAR-04 | Milestone in-place 수정 | `PATCH /plans/{planId}/milestones/{milestoneId}`: status/description/sortOrder/version만. 비활성 plan 409 `PLAN_NOT_ACTIVE` (`06` §11.1) | P0 | S1 | BL-CAR-02 | AC-01, AC-24 | FR-04 |
| BL-CAR-05 | Replan 최소판 | `ReplanService` + `POST /plans/{planId}/replan`: milestone 구조 변경, 기존 plan `SUPERSEDED` + **flush** 후 새 version INSERT, id mapping, `plan_skill_target` 복사. `acceptedDeferrals`/`acceptedTargetReductions`/`restoredDeferrals`가 비어 있지 않으면 400. `PLAN_REPLANNED` 이벤트는 BL-CAR-07, snapshot은 BL-CAR-13 | P0 | S1 | BL-CAR-04 | AC-01, AC-24 | FR-04 |
| BL-CAR-06 | 온보딩 API | `OnboardingService` + `POST /onboarding`(201, 한 트랜잭션): 프로필·timezone·dayStartHour·학습 시간, career goal, **`SelfAssessmentPropagation`**(카테고리 최대 13개 → 활성 skill 전체 `user_skill_state`), plan v1(템플릿, BL-CAR-03), 409 `ONBOARDING_ALREADY_COMPLETED`, `OnboardingRequiredInterceptor`(409 `ONBOARDING_REQUIRED`). **S1은 8·9단계 생략**: 응답 `assignedSeedCardCount = 0`, `latestRiskLevel = null`. seed 카드 복사는 BL-MEM-08(S2, 기동 backfill), snapshot은 BL-CAR-13(S5)에서 연결 | P0 | S1 | BL-CAR-01, BL-CAR-03, BL-SKL-02, BL-CNT-05 | AC-11 | FR-02 |
| BL-CAR-07 | `PLAN_REPLANNED` 이벤트 연결 | V4 적용 후 replan에서 `LearningEventRecorder`로 `PLAN_REPLANNED` 기록 + 감사 로그 | P1 | S2 | BL-SKL-03, BL-CAR-05 | AC-01 | FR-04 |
| BL-CAR-08 | **`StudyBudgetCalculator`** | horizon, nominal, completion rate, effective (`06` §3, test vector 전부). | P0 | S5 | BL-FND-09, BL-FND-10 | AC-03 | FR-05 |
| BL-CAR-09 | **`DeadlineRiskEvaluator`** | skill별 required minutes, risk level, `ratioBp` (`06` §4.1~4.3, test vector 전부). | P0 | S5 | BL-SKL-02 | AC-03 | FR-05 |
| BL-CAR-10 | **`ReplanSuggestionPolicy`** | 제안 순서 = MUST 목표 축소를 먼저 `requiredMust ≤ effective`까지 → 그다음 SHOULD defer, `riskAfterSuggestions` (`06` §4.4 test vector 1·2, 2026-09-18 개정). | P0 | S5 | BL-CAR-09 | AC-03 | FR-05 |
| BL-CAR-11 | Budget API | `StudyBudgetService` + `GET /plans/active/budget`. completion 입력은 port `plan.application.StudyHistoryProvider`(plan 정의, `today` 모듈 구현: plan-day별 `available_minutes`와 COMPLETED 세션 `actual_minutes` 합)로 받는다 | P0 | S5 | BL-CAR-08, BL-CAR-09, BL-TDY-10 | AC-03 | FR-05 |
| BL-CAR-12 | Replan preview API | `POST /plans/{planId}/replan/preview`: 저장 없음, IK 무시, risk + 제안 + `riskAfterSuggestions` | P0 | S5 | BL-CAR-10, BL-CAR-11 | AC-03 | FR-05 |
| BL-CAR-13 | Replan 완성 | `acceptedDeferrals`(`DEFERRED`), `acceptedTargetReductions`(`TARGET_REDUCED`), `restoredDeferrals`(defer 해제) 적용, 새 plan 기준 오늘 snapshot upsert. 온보딩 처리의 snapshot upsert도 연결 | P0 | S5 | BL-CAR-12 | AC-03, AC-24 | FR-05 |
| BL-CAR-14 | `ProgressSnapshotJob` | 매시 5분, 로컬 시각이 `dayStartHour`인 사용자만 budget/risk 계산 → `plan_progress_snapshot` upsert, 사용자 단위 트랜잭션. S2~S4에는 `deadline_risk = null`(planner는 LOW 취급) | P0 | S5 | BL-CAR-11, BL-FND-25 | AC-03, AC-17 | FR-05 |
| BL-CAR-15 | 공휴일 반영 budget | nominal budget 계산에 공휴일 달력 반영 | P3 | Later | — | — | FR-05 |
| BL-CAR-16 | `POST /plans` endpoint | 활성 plan 없을 때 템플릿 plan 생성 공개 API(201 / 409 `ACTIVE_PLAN_EXISTS`, AC-24 S3). MVP에는 온보딩 외 호출 경로가 없어 Later(2026-09-18) | P3 | Later | BL-CAR-03 | AC-24 | FR-04 |

### 4.6 SKL — Skill

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-SKL-01 | Skill catalog API | `Skill`, `SkillPrerequisite`, `RoleSkillTarget` 매핑, `SkillCatalogQueryService`, `GET /skills/tree?role=JAVA_BACKEND` | P0 | S1 | BL-FND-14, BL-CNT-02 | AC-11 | FR-06 |
| BL-SKL-02 | Skill state API | `UserSkillState`, **`PlanningLevelPolicy`**(`06` §7.5, vector 13~14), `UserSkillStateQueryService`, `GET /skills/me`. | P0 | S1 | BL-SKL-01 | AC-09 | FR-06 |
| BL-SKL-03 | 학습 이벤트 기록 | `LearningEvent`, `LearningEventType`, payload record(`04` §6), `LearningEventRecorder`(dedupe_key 중복 시 기존 반환, `plan_date`), `LearningEventRecorded` 발행 | P0 | S2 | BL-FND-15 | AC-09 | FR-06 |
| BL-SKL-04 | **`SkillLevelRules`** | 상승·하락·진단 규칙(`06` §7.1~7.4, vector 1~12, 15). 입력은 60일 이벤트 payload만. | P0 | S3 | BL-SKL-03 | AC-09 | FR-06 |
| BL-SKL-05 | `SkillStateUpdater` | 동기 `@EventListener`, 무효화 이벤트 제외, 하락 우선, 축당 1단계, 24시간 cooldown, `skill_state_change`, `evidence_count`, `last_practiced_at`, `self_assessment_active`. ArchUnit: 레벨 setter는 이 경로만(I-12). | P0 | S3 | BL-SKL-04 | AC-09 | FR-06 |
| BL-SKL-06 | Skill 이력 API | `GET /skills/{skillId}/history?cursor=` (`skill_state_change`, rule_code, 근거 이벤트 요약) | P1 | S3 | BL-SKL-05 | AC-09 | FR-06 |
| BL-SKL-07 | 하루 1회 skill 재평가 | (검토 제안, 미결정) `SkillStateUpdater`는 새 이벤트가 올 때만 재평가하므로 시간 경과로만 성립하는 하락 규칙(`06` §7.3)이 늦게 적용된다. `ProgressSnapshotJob`(plan-day 시작 시)에서 사용자 skill 전체를 1회 재평가하는 방식을 검토. 사용자 결정 후 착수 | P2 | S5 | BL-SKL-05, BL-CAR-14 | AC-09 | FR-06 |

### 4.7 TDY — Today

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-TDY-01 | Daily plan 도메인 | `DailyPlan`, `LearningTask` 매핑, 상태 전이 메서드(`04` §4.1, 위반 409 `INVALID_STATE_TRANSITION`), WIP unique index 위반 변환 | P0 | S2 | BL-FND-15 | AC-02 | FR-07 |
| BL-TDY-02 | **`PlannerScoring`** | factor, weight, modifier, 동점 처리(`06` §5.4~5.5, §5.7 vector 전부). | P0 | S2 | BL-FND-09 | AC-02 | FR-07 |
| BL-TDY-03 | **`TaskProposalPolicy`** | 후보 skill별 main task 제안과 제목 템플릿(`06` §5.3). | P0 | S2 | BL-FND-09 | AC-02 | FR-07 |
| BL-TDY-04 | **`TimeAllocator`** | reviewMinutes, mainBudget, limit, 초과 시 조정(`06` §5.6 vector 전부). | P0 | S2 | BL-FND-09 | AC-02 | FR-07 |
| BL-TDY-05 | **`ReasonTemplates`** | reason 1~3개, modifier reason 우선, 최소 1개 보장(`06` §5.8). | P0 | S2 | BL-TDY-02 | AC-02 | FR-07 |
| BL-TDY-06 | **`ComebackModePolicy`** | 복귀 모드 판정(`06` §5.5 정의), cap 10, difficulty ≤ 2. | P0 | S2 | BL-FND-10 | AC-02 | FR-21 |
| BL-TDY-07 | Today 생성 API | `TodayPlanService` + `POST /today/generate`: availableMinutes 5~720, 후보(`06` §5.2), 재생성 표(`06` §5.9, PLANNED 삭제 후 flush), `generation_count`, 활성 plan 없음 404 `PLAN_NOT_FOUND`. S2에는 challenge 후보를 빈 목록으로 전달(BL-TDY-14) | P0 | S2 | BL-TDY-01, BL-TDY-02, BL-TDY-03, BL-TDY-04, BL-TDY-05, BL-TDY-06, BL-MEM-04, BL-TDY-10 | AC-02, AC-17 | FR-07, FR-21 |
| BL-TDY-08 | Today 조회 API | `TodayQueryService` + `GET /today`(없으면 404 `TODAY_NOT_GENERATED`) | P0 | S2 | BL-TDY-01 | AC-02, AC-17 | FR-07 |
| BL-TDY-09 | Task 상태 API | `PATCH /today/tasks/{taskId}`(status, version, SKIPPED→PLANNED는 활성 main 없을 때만) | P0 | S2 | BL-TDY-01 | AC-02 | FR-07 |
| BL-TDY-10 | 학습 세션 API | `LearningSession`, `LearningSessionService`: `POST /learning-sessions`(기존 IN_PROGRESS → ABANDONED 후 flush, I-05), `POST .../complete`(actualMinutes 0~720, selfReflection), `POST .../abandon`, `GET /learning-sessions?from=&to=&cursor=`, `SESSION_*` 이벤트 | P0 | S2 | BL-SKL-03 | AC-02 | FR-08 |
| BL-TDY-11 | Dashboard 최소 API | `DashboardQueryService` + `GET /dashboard`: 오늘 상태, due 수, 최근 7 plan-day 학습 시간, 현재 milestone | P0 | S2 | BL-TDY-08, BL-MEM-05 | AC-02 | FR-16 |
| BL-TDY-12 | Dashboard 완성 API | risk 추세(snapshot), skill 카테고리 요약, 약한 thinking 축 Top 3 | P1 | S5 | BL-TDY-11, BL-CAR-14, BL-COA-09 | AC-02 | FR-16 |
| BL-TDY-13 | 캘린더 피드 | `CalendarTokenService` + `POST /me/calendar-token`(32바이트 토큰, SHA-256 hash 저장, 재발급 시 이전 폐기), `CalendarFeedController` + `IcsFeedWriter` + `GET /calendar/{token}.ics`(Bearer 없음, 불일치 404, 제목·예상 시간만). 2026-09-18 S2 → S3 | P1 | S3 | BL-TDY-08, BL-SEC-06 | AC-08 | FR-20 |
| BL-TDY-14 | Today ↔ challenge 연결 | `ChallengeQueryService`를 `TaskProposalPolicy` 입력으로 연결(VALIDATED PRACTICE, 14 plan-day 내 attempt 제외, SOLVED_* outcome이 있는 challenge 제외). `aiStatus ∈ {DISABLED, BALANCE_EXHAUSTED}`이면 CHALLENGE 제안을 만들지 않는다(AI 평가 없이 풀 수 없음) | P0 | S3 | BL-TRN-02, BL-TDY-07, BL-AIP-10 | AC-02, AC-12 | FR-07 |
| BL-TDY-15 | plan-day 시작 시 Today 자동 생성 | (검토 제안, 미결정) `dayStartHour`에 전날 설정(시간·컨디션 기본값)으로 daily plan을 미리 만들어 첫 진입 시 "생성" 단계를 없애는 방식. 재생성 규칙·`generation_count`와의 상호작용 결정 필요. 사용자 결정 후 착수 | P3 | Later | BL-TDY-07, BL-CAR-14 | — | FR-07 |

### 4.8 MEM — Memory Review

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-MEM-01 | Review 도메인 | `ReviewItem`, `ReviewAnswer` 매핑, 상태 전이(`04` §4.5), `unique(user_id, concept_key)` 위반 변환 | P0 | S2 | BL-FND-15 | AC-05 | FR-11 |
| BL-MEM-02 | **`FinalRatingPolicy`** | 자기평가 → 최종 등급, `adjustedBy`(`06` §6.1). | P0 | S2 | BL-FND-09 | AC-05 | FR-11 |
| BL-MEM-03 | **`RuleBasedV1Scheduler`** | `ReviewSchedulingStrategy` 구현: 간격, clamp 1~60, horizon cap, `hard-strategy`(MULTIPLY/FIXED_2), due 계산(`06` §6.2, §6.6 vector 전부). | P0 | S2 | BL-FND-09, BL-FND-10 | AC-05 | FR-11 |
| BL-MEM-04 | **`DueReviewSelector`** | 오늘 due 대상·정렬·상한(20 / 복귀 모드 10)(`06` §6.5). | P0 | S2 | BL-FND-10 | AC-05, AC-17 | FR-11 |
| BL-MEM-05 | Due 조회 API | `ReviewQueryService`(다른 모듈 공개) + `GET /reviews/due?limit=`: prompt + expectedAnswer + rubric. variant 출제(`variant_status=READY`)는 BL-MEM-10(Later)과 함께 | P0 | S2 | BL-MEM-01, BL-MEM-04 | AC-05, AC-10 | FR-11 |
| BL-MEM-06 | 복습 답변 API | `ReviewService.answer` + `POST /reviews/{reviewItemId}/answer`(evaluate=false 경로): `review_answer` INSERT, 스케줄, leech(`06` §6.4 — 최근 1 plan-day 안 `LEECH_DETECTED` 이벤트가 있으면 planner reviewUrgency 최댓값), `REVIEW_ANSWERED`/`LEECH_DETECTED` 이벤트 | P0 | S2 | BL-MEM-02, BL-MEM-03, BL-MEM-05, BL-SKL-03 | AC-05, AC-10 | FR-11 |
| BL-MEM-07 | 복습 카드 관리 API | `ReviewItemService`: `GET /review-items?skillId=&status=&cursor=`, `POST /review-items`(수동, `concept_key = MANUAL:{uuid}`, 첫 due 다음 plan-day), `PATCH /review-items/{reviewItemId}`(status/prompt/expectedAnswer/version, SUSPENDED→ACTIVE due 재설정). 2026-09-18 S2 → S3(수동 카드 CRUD 범위 축소). S2의 leech 자동 SUSPENDED는 BL-MEM-06에서 처리하고 재활성화는 S3 | P0 | S3 | BL-MEM-01 | AC-05 | FR-11 |
| BL-MEM-08 | Seed 카드 배정 | `SeedCardAssignmentService`(`review.application.SeedCardRegistry`에 content가 등록): 온보딩 시 seed 카드 → `review_item` 복사(`06` §6.3 첫 행, 하루 5장 분산), 기동 시 `ContentSeeder`가 `SeedCardAssignmentService.backfillAll()`을 호출해 기존 사용자에게 신규 카드 추가. S1에 온보딩한 사용자는 S2 첫 배포 기동 시 배정 | P0 | S2 | BL-MEM-01, BL-CNT-06, BL-CAR-06 | AC-11 | FR-02, FR-11 |
| BL-MEM-09 | 복습 AI 평가 | `POST /reviews/{reviewItemId}/answer` `evaluate=true`: `REVIEW_EVALUATE` 동기(20초, 재시도 0, thinking off), 복습 rubric 균등 배분 coverage(`06` §8.1, `RubricScorer`는 `learning.domain`), 실패·차단 시 `NOT_EVALUATED` + `evaluationSkippedReason` | P1 | S3 | BL-MEM-06, BL-AIP-07 | AC-05, AC-12 | FR-11 |
| BL-MEM-10 | `ReviewVariantTask` | 연속 실패 ≥ 2이고 AI 사용 가능하면 커밋 후 `REVIEW_VARIANT` 비동기 생성, `variant_status` 전이(`04` §4.5), `GET /reviews/due` variant 출제, `AiPendingJobCounter` 구현(review). 2026-09-18 Later(`REVIEW_VARIANT` operation 보류; `03` §9 설정에는 남겨 둔다) | P3 | Later | BL-MEM-06, BL-FND-23, BL-AIP-07, BL-AIP-10 | AC-05 | FR-11 |
| BL-MEM-11 | FSRS 전략 | `ReviewSchedulingStrategy` 두 번째 구현. 전환 조건은 ADR-018 | P3 | Later | — | — | FR-11 |

### 4.9 TRN — Training

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-TRN-01 | Training 도메인 | `Challenge`, `ChallengeSkill`, `ChallengeAttempt`, `ChallengeSubmission` 매핑, 상태 전이(`04` §4.2) | P0 | S3 | BL-FND-16 | AC-04 | FR-09 |
| BL-TRN-02 | Challenge 조회 API | `ChallengeQueryService`(today 공개) + `GET /challenges?skillId=&purpose=&cursor=`(VALIDATED, seed + 본인 소유), `GET /challenges/{challengeId}`(본인 attempt 평가 완료 전 rubric·expectedConcepts 제외) | P0 | S3 | BL-TRN-01, BL-CNT-07 | AC-04, AC-08 | FR-09 |
| BL-TRN-03 | `ChallengeValidationService` | VALIDATED 조건(I-09), rubric weight 합 10000(I-10), difficulty 1~5, hints 1~3단계, skill code 존재 → `VALIDATED`/`REJECTED` + `rejection_reason` | P0 | S3 | BL-TRN-01 | AC-04 | FR-09 |
| BL-TRN-04 | Challenge 생성 | `ChallengeGenerationService` + `POST /challenges/generate`(202) + `ChallengeGenerationTask`(`CHALLENGE_GENERATE`). `AiPendingJobCounter` 구현(training: 생성 중 challenge의 PENDING/RUNNING 수) | P1 | S3 | BL-TRN-03, BL-FND-23, BL-AIP-07, BL-CNT-10, BL-AIP-10 | AC-04, AC-12, AC-23 | FR-09 |
| BL-TRN-05 | Attempt API | `AttemptService`: `POST /challenges/{challengeId}/attempts`(201, VALIDATED만), `GET /challenge-attempts/{attemptId}`, `POST .../abandon`, `CHALLENGE_STARTED` 이벤트 | P0 | S3 | BL-TRN-02, BL-SKL-03 | AC-04 | FR-09 |
| BL-TRN-06 | Self-explanation API | `POST /challenge-attempts/{attemptId}/self-explanation`(text 또는 skipped), `SELF_EXPLANATION_*` 이벤트 | P0 | S3 | BL-TRN-05 | AC-16 | FR-10 |
| BL-TRN-07 | **`HintLadderPolicy`** | HL-1~HL-8 판정(`06` §9.1~9.2 vector 전부) | P0 | S3 | BL-FND-09 | AC-16 | FR-10 |
| BL-TRN-08 | Challenge hint API | `HintService` + `POST /challenge-attempts/{attemptId}/hints`: 1~3단계 `hints_json`, 4단계 이상 `HINT_GENERATE` 동기, `hint_disclosure`, `HINT_DISCLOSED`, `max_hint_level` | P0 | S3 | BL-TRN-06, BL-TRN-07, BL-AIP-07 | AC-12, AC-16, AC-23 | FR-10 |
| BL-TRN-09 | 제출·평가 | `SubmissionService` + `POST .../submissions`(202, `SUBMISSION_LIMIT_REACHED`, `EVALUATION_IN_PROGRESS`, `SELF_EXPLANATION_REQUIRED`) + `SubmissionEvaluationTask`(`CHALLENGE_EVALUATE`), 코드 masking 후 저장. `AiPendingJobCounter` 구현(training: 평가 중 submission의 PENDING/RUNNING 수) | P0 | S3 | BL-TRN-06, BL-TRN-11, BL-AIP-09, BL-FND-23, BL-AIP-07, BL-CNT-10, BL-AIP-10 | AC-04, AC-14 | FR-09 |
| BL-TRN-10 | 평가 재시도 API | `POST .../submissions/{submissionNo}/retry`(202, FAILED만, 그 외 409 `AI_TASK_NOT_RETRYABLE`) | P0 | S3 | BL-TRN-09 | AC-04, AC-12 | FR-09 |
| BL-TRN-11 | **`RubricScorer`**, **`AttemptOutcomeCalculator`** | coverage, evaluatedOutcome, attempt outcome(`06` §8.1~8.2 vector 전부), `CHALLENGE_SUBMITTED`/`CHALLENGE_EVALUATED` payload | P0 | S3 | BL-FND-09 | AC-04, AC-09 | FR-09 |
| BL-TRN-12 | 실패 attempt → 복습 항목 | 평가 후 `06` §8.3 조건이면 challenge skill마다 review item upsert(due `planDayStart(today + 1)`) | P0 | S3 | BL-TRN-09, BL-MEM-07 | AC-05 | FR-09, FR-11 |
| BL-TRN-13 | 진단 제안 | `DiagnosticSuggestionService` + `GET /diagnostics/suggestions`(선택 규칙은 `05-api-spec.md`), 온보딩 응답 `suggestedDiagnostics` 연결, `DIAGNOSTIC_PASSED`/`DIAGNOSTIC_FAILED` 판정(`06` §7.4) | P1 | S3 | BL-TRN-11, BL-CNT-08 | AC-11 | FR-15 |
| BL-TRN-14 | 코드 실행 runner | 샌드박스 컴파일·테스트 실행 → `COMPILER`/`TEST_RESULT` 근거 | P3 | Later | — | — | FR-14 |
| BL-TRN-15 | 자기설명 선택화 · EXPLAIN 카드 상한 | (검토 제안, 미결정) 실사용 4주 후 self-explanation 필수(HL-2)가 부담이면 난이도 ≤ 2 challenge에서 선택으로 바꾸고, 하루 EXPLAIN 복습 카드 수에 상한을 두는 방식을 검토. `06` §9.1·§6.5 개정이 선행 | P3 | Later | BL-TRN-06, BL-CNT-14 | — | FR-10, FR-11 |

### 4.10 AIP — AI Platform

`17-ai-integration.md`가 기준이다. 이 표의 ID와 범위는 `17-ai-integration.md`의 구현 체크리스트와 같다.

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-AIP-01 | AI port·Fake·Disabled | `AiProvider`, `AiRequest<T>`, `AiResult<T>`, `AiOperation`, `AiCallStatus`(402 → `PROVIDER_ERROR` 재시도 불가, `content_filter` → `REFUSED`, `insufficient_system_resource`·`aborted`·429·5xx·timeout → 재시도 가능 `PROVIDER_ERROR`, 출력 상한 잘림 → `INVALID_OUTPUT`, 미지 값 → `stop:<raw>` 기록), `FakeAiProvider`(operation별 fixture, `finishReason: completed\|max_output_tokens\|content_filter\|insufficient_system_resource\|aborted`, `simulate: INSUFFICIENT_BALANCE\|CONTENT_FILTER`, usage `cacheHitTokens`·`reasoningTokens`), `DisabledAiProvider`(항상 `AI_UNAVAILABLE`). `AiStatus`·`AiUsageSnapshot` record는 BL-AIP-16(S1) | P0 | S3 | BL-FND-09, BL-AIP-16 | AC-12 | NFR-03, NFR-10 |
| BL-AIP-02 | AI 설정 바인딩 | `DevPilotProperties.ai`(provider, model, deepseek{base-url, api-key, store, retry-after-default}, monthly-budget-usd 기본 3, budget-warning-ratio, min-balance-usd, balance-check-cron, operations{mode, thinking, reasoning-effort, max-tokens, timeout, max-retries, input-token-budget}, pricing{peak-multiplier, models}, guard 임계값) 정수 변환(N-6), 모델 단가·operation 누락 시 기동 실패 (`03` §9) | P0 | S3 | BL-AIP-01 | AC-13 | NFR-07, NFR-10 |
| BL-AIP-03 | `DeepSeekAiProvider` (RestClient) | `integration.ai.deepseek.DeepSeekAiProvider`: Spring `RestClient`로 `POST /responses` + `text.format {type: json_schema, name, schema}`, `instructions`=system.md, `input`, `store:false`, `max_output_tokens`, `thinking {type: enabled\|disabled}`, `reasoning_effort low\|high\|max`; 요청에 `user`/`user_id` 금지(캐시 분리 방지); 응답 `output[]`의 `type=message` `output_text`만 순서대로 추출; op별 read timeout 고정 + 시도 사이 deadline 검사; `Retry-After`(없으면 `retry-after-default` 2s, deadline 상한) 대기(ARCH-07 예외 패키지); `HttpClientErrorException`(400/401/402/422/429)·`HttpServerErrorException`·`ResourceAccessException` → `AiCallStatus`; 잘림 재시도 시 thinking off; `/responses` 정확한 필드(`status: incomplete`, `incomplete_details.reason`, `usage.input_tokens_details.cached_tokens`, `usage.output_tokens_details.reasoning_tokens`)는 구현 시 실제 응답으로 확인. 테스트 `DeepSeekAiProviderRequestTest`(`MockRestServiceServer`). `DeepSeekBalanceClient`(`GET /user/balance`)는 BL-AIP-17 | P0 | S3 | BL-AIP-02, BL-FND-01 | AC-12 | NFR-10 |
| BL-AIP-04 | ~~취소~~ Refusal 처리 | 2026-09-18 취소(Anthropic 전용 서버 측 refusal fallback·iteration 비용). `content_filter` → `REFUSED` 매핑은 BL-AIP-01·03, coach `AI_REFUSED` 재시도 불가는 BL-COA-05 | — | ~~S3~~ | — | — | — |
| BL-AIP-05 | `PromptRegistry` | `classpath:prompts/<id>/<version>/` 로딩, 활성 버전, `PromptRenderer`(줄 번호, user content escape, 토큰 추정, 절삭 mode), prompt 파일 불변 테스트 | P0 | S3 | BL-AIP-02 | — | NFR-07 |
| BL-AIP-06 | 출력 스키마 | `OutputSchemaRegistry`, operation 출력 record 9종, 전용 `ObjectMapper`, 스키마-record 일치 테스트 | P0 | S3 | BL-AIP-01 | AC-04, AC-06 | NFR-07 |
| BL-AIP-07 | `AiGateway` | 예산 → provider → stop_reason → 스키마·가드 → (비동기 operation만) 1회 재시도 → `ai_call_log` 기록(`AiCallLog`, 별도 트랜잭션 writer, 원문 미저장, `guard_actions`), `devpilot.ai.*` Micrometer 지표 | P0 | S3 | BL-AIP-03, BL-AIP-05, BL-AIP-06, BL-AIP-10, BL-FND-16 | AC-12, AC-13 | NFR-06, NFR-07 |
| BL-AIP-08 | 출력 가드 | `OutputGuardChain`: `CodeLeakGuard`(HL-8), `EnumGuard`, `SkillCodeGuard`, `LanguageGuard` (S3), `VerificationGuard`(`06` §10 vector 전부, URL fetch 없음), `FindingCountGuard` (S4 coach와 함께) | P0 | S3 | BL-AIP-06 | AC-06, AC-07, AC-16 | FR-10, FR-12, FR-14 |
| BL-AIP-09 | `SecretMasker` | 패턴·test vector(`17-ai-integration.md`), private key 정규식 차단, `MaskingResult`, 적용 endpoint 연결(coach endpoint는 S4), `SECRET_BLOCKED` 감사 로그 | P0 | S3 | BL-AIP-01 | AC-14 | NFR-05 |
| BL-AIP-10 | `AiBudgetGuard` | 사용자당 일일 호출 60회(plan-day 기준), **서비스 전체** 월 비용 USD 3(`monthly-budget-usd`, Asia/Seoul 달력 월, 경고 80%), 사용자당 동시 실행 2(동기 진행 중 + 비동기 PENDING/RUNNING, permit 수명), 잔액 소진 플래그(`AiBalanceMonitor`, BL-AIP-17) 확인, `BUDGET_BLOCKED` 기록, `GET /me` `aiStatus`·`aiUsage` (ADR-029). port `common.time.UserTimeSettingsProvider`(user 모듈 구현)로 요청 밖 timezone·dayStartHour 조회, port `integration.ai.api.AiPendingJobCounter`(coach·training·evidence·job 구현; review는 BL-MEM-10 Later) 합산으로 비동기 진행 수 계산. 테스트 벡터는 test profile 예산 25 기준(`17`·`09`) | P0 | S3 | BL-AIP-02, BL-FND-21, BL-AIP-16 | AC-13 | FR-22, NFR-01 |
| BL-AIP-11 | `AiCostCalculator` | `pricing.models.<model> {input, cache-hit, output}`(USD/1M) × `peak-multiplier` 2(결정 F: 시각 규칙 없이 항상): `cost_micro = 2 × [(inputTokens − cachedTokens) × input + cachedTokens × cacheHit + outputTokens × output]`(정수 연산, 추론 토큰은 출력에 포함), `reasoning_tokens`·`effort(off\|low\|high\|max)` 기록. `deepseek-v4-pro` cache-hit 단가 미확인 → 입력 단가로 보수 계산 | P0 | S3 | BL-AIP-02 | AC-13 | NFR-01 |
| BL-AIP-12 | AI ArchUnit 규칙 | 트랜잭션 안 `AiGateway` 호출 금지(T-2), DeepSeek HTTP DTO·`RestClient`는 `integration.ai.deepseek`만(ARCH-07 `Thread.sleep` 예외도 이 패키지만), 도메인 모듈은 `AiGateway`와 `integration.ai.api`(`AiStatus`, `AiUsageSnapshot`, `AiBudgetDecision`, `AiConcurrencyReservation`)만 사용 | P0 | S3 | BL-AIP-07, BL-FND-05 | AC-12 | NFR-07 |
| BL-AIP-13 | Evals v1 | `evals/` 구조, `evalTest` source set·`aiEval` task, 채점·baseline·실행 전 비용 미리보기(`-PevalMaxCostUsd` 기본 0.5), `ai-eval.yml`(`workflow_dispatch`만, environment `ai-eval`, secret `DEEPSEEK_API_KEY`, prod와 같은 잔액 — 결정 E), coach·hint·challenge-evaluate seed case 전부 실행 | P1 | S4 | BL-AIP-07, BL-COA-03 | AC-06, AC-07 | FR-12, NFR-07 |
| BL-AIP-14 | 실측 반영 | `ai_call_log` 2주 집계로 토큰·추론 토큰·캐시 적중 추정 계수, 비용 추정표(USD 3/월 근거), operation별 thinking·reasoning-effort 조정 여부를 문서에 반영 | P1 | S5 | BL-AIP-07 | AC-13 | NFR-01 |
| BL-AIP-15 | AI 운영 게이트 (DeepSeek) | DeepSeek는 콘솔 지출 한도가 없다 → 선불 잔액을 소액(USD 10 안팎)으로 유지 + `AiBalanceCheckJob`(BL-AIP-17) + 앱 예산 가드가 상한. 공급자 정책 확인 결과를 ADR-013에 기록(중국 소재, 학습 미사용 약정 없음, zero-retention 없음 → 학습용 프로젝트로 진행), Coach 제출 화면·초대 시 1회 안내 동의 문구(BL-CLI-24·03) 반영 확인, API 키 1개(prod·eval 공용). 완료 전 prod `DEVPILOT_AI_PROVIDER=deepseek` 금지 | P0 | S3 | BL-AIP-17 | AC-13, AC-14 | NFR-01, NFR-05 |
| BL-AIP-16 | `AiStatus`·`AiUsageSnapshot` record | `integration.ai.api`의 `AiStatus` enum(`ENABLED`, `BUDGET_WARNING`, `DISABLED`, `BALANCE_EXHAUSTED`)과 `AiUsageSnapshot` record(`todayCalls`, `dailyCallLimit`, `monthCostUsd`, `monthlyBudgetUsd`)만 S1에 먼저 만들어 `GET /me`(BL-FND-21)가 쓴다. S1~S2는 provider `disabled` 고정값(`DISABLED`, 호출 0). BL-AIP-01에서 분리(2026-09-18) | P0 | S1 | BL-FND-09 | AC-12 | NFR-03 |
| BL-AIP-17 | `AiBalanceCheckJob` · 잔액 모니터 | `integration.ai.deepseek.DeepSeekBalanceClient`(`GET /user/balance`, 응답 형식은 구현 시 확인) + `integration.ai.budget.AiBalanceMonitor`(메모리 플래그) + `AiBalanceCheckJob`(매시 15분, `balance-check-cron`, `provider=deepseek`일 때만): 잔액 < `min-balance-usd`(1.00) 또는 402 수신 → `BALANCE_EXHAUSTED`(다음 정상 확인까지 `DISABLED`처럼 동작, 이유 표시), 회복 시 해제, 상태 변경 시 감사 `AI_BALANCE_LOW`/`AI_BALANCE_RESTORED` + WARN/INFO, 조회 실패는 상태 유지 (`03` §6, `17` §8) | P0 | S3 | BL-AIP-03, BL-FND-25, BL-AIP-16 | AC-12, AC-13 | NFR-01, NFR-03 |

### 4.11 COA — Project Coach

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-COA-01 | Coach 도메인 | `CoachReview`, `CoachFinding`, `ThinkingPatternObservation` 매핑, 상태 전이(`04` §4.3) | P1 | S4 | BL-FND-17 | AC-06 | FR-12 |
| BL-COA-02 | Coach 생성 API | `CoachReviewService` + `POST /coach/reviews`(202): 동의·크기(30000 bytes, 1000줄) → masking(422) → 예산(429/503) → 마스킹본 저장(`PENDING`, retention 30일) → `CoachReviewRequested`. `AiPendingJobCounter` 구현(coach: 분석 중 review의 PENDING/RUNNING 수) | P1 | S4 | BL-COA-01, BL-AIP-09, BL-FND-23, BL-AIP-07, BL-AIP-10 | AC-06, AC-14, AC-23 | FR-12 |
| BL-COA-03 | `CoachAnalysisTask` | `COACH_REVIEW` 비동기, skill state·약한 thinking 축 컨텍스트, findings INSERT, `INCORRECT_CLAIM` observation | P1 | S4 | BL-COA-02, BL-CNT-11, BL-AIP-08 | AC-06, AC-07, AC-19 | FR-12, FR-14 |
| BL-COA-04 | Coach 조회 API | `GET /coach/reviews/{reviewId}`(polling, 수정 코드 필드 없음), `GET /coach/reviews?cursor=` | P1 | S4 | BL-COA-01 | AC-06, AC-08 | FR-12 |
| BL-COA-05 | Coach 재시도 API | `POST /coach/reviews/{reviewId}/retry`(202, FAILED만, 원문 purge·`CONFIDENTIAL_SUSPECTED`·`AI_REFUSED`(content_filter)면 409 `AI_TASK_NOT_RETRYABLE`) | P1 | S4 | BL-COA-03 | AC-06, AC-12 | FR-12 |
| BL-COA-06 | Finding 응답 API | `CoachFindingService` + `POST .../findings/{findingId}/responses`: `COACH_RESPONSE_FEEDBACK` 동기, `user_identified_issue`, 실패·차단 시 응답만 저장 + `feedbackSkippedReason` | P1 | S4 | BL-COA-01, BL-AIP-07 | AC-12, AC-19 | FR-12 |
| BL-COA-07 | Finding hint API | `POST .../findings/{findingId}/hints`: `HintService` 재사용, 전 단계 `HINT_GENERATE`, HL-2(응답 또는 `skipSelfExplanation`) | P1 | S4 | BL-TRN-08, BL-COA-01 | AC-16 | FR-10 |
| BL-COA-08 | Finding 상태 API | `PATCH .../findings/{findingId}`(RESOLVED/DISMISSED, version, 닫힌 리뷰 409 `REVIEW_ALREADY_CLOSED`) | P1 | S4 | BL-COA-01 | AC-06 | FR-12 |
| BL-COA-09 | Review close | **`DiscoveredByResolver`**(`06` §9.3) + `ThinkingPatternRecorder` + `POST .../complete`: `closed_at`, `discovered_by` 확정, observation, `COACH_FINDING_CLOSED`, `COACH_REVIEW_COMPLETED`. skill이 있는 BUG/RISK finding 중 `discoveredBy ∈ {MISSED, FOUND_AFTER_HINT}`는 review item upsert(`COACH:{skillCode}:{category}`, due 다음 plan-day) | P1 | S4 | BL-COA-06, BL-SKL-03, BL-MEM-07 | AC-05, AC-09, AC-19 | FR-11, FR-12, FR-13 |
| BL-COA-10 | 원문 삭제·purge | `DELETE /coach/reviews/{reviewId}/content`(즉시), `CoachContentPurgeJob`(UTC 18:20, `content_retention_until < now`) | P1 | S4 | BL-COA-01, BL-FND-25 | AC-14, AC-15 | NFR-05 |
| BL-COA-11 | IDE plugin | JetBrains plugin: 선택 코드·diff → coach review 요청 (ADR-004) | P3 | Later | — | — | FR-12 |

### 4.12 EVD — Evidence · Weekly

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-EVD-01 | **`MetricsCalculator`** | `06` §12 지표 전부(정수). `requirementCoverageBp`는 port `evidence.application.JobCoverageProvider`를 `ObjectProvider`로 받고, 구현(BL-JOB-04)이 없는 S7 전에는 null | P1 | S5 | BL-FND-18 | AC-21 | FR-17 |
| BL-EVD-02 | `WeeklyReviewJob` | `WeeklyReviewService` + 매시 10분, 로컬 월요일 `dayStartHour` 사용자만 지난주 `metrics_json` 생성, `unique(user_id, week_start_date)`로 중복 없음 | P1 | S5 | BL-EVD-01, BL-FND-25 | AC-17, AC-21 | FR-17 |
| BL-EVD-03 | Weekly API | `WeeklyReviewController`: `GET /weekly-reviews?cursor=`, `GET /weekly-reviews/{weekStartDate}`, `PUT /weekly-reviews/{weekStartDate}/reflection`(version) | P1 | S5 | BL-EVD-02 | AC-21 | FR-17 |
| BL-EVD-04 | Thinking 추세 API | `GET /thinking-patterns/trend?weeks=8` (주별·축별 observation 수) | P1 | S5 | BL-COA-09 | AC-19 | FR-13 |
| BL-EVD-05 | Evidence 조회·수동 작성 API | `EvidenceService`: `GET /evidence?status=&cursor=`, `GET /evidence/{evidenceId}`, `POST /evidence` | P1 | S6 | BL-FND-18 | AC-21 | FR-18 |
| BL-EVD-06 | Evidence AI 초안 | `POST /evidence/drafts`(202, `sourceLearningEventId`) + `EvidenceDraftTask`(`EVIDENCE_DRAFT`, `ai_draft_json` 원본 보존). `AiPendingJobCounter` 구현(evidence: 생성 중 초안의 PENDING/RUNNING 수) | P1 | S6 | BL-EVD-05, BL-FND-23, BL-AIP-07, BL-CNT-12, BL-AIP-10 | AC-21, AC-23 | FR-18 |
| BL-EVD-07 | Evidence 편집·승인 API | `PATCH /evidence/{evidenceId}`(version), `POST .../accept`(`EVIDENCE_ACCEPTED` → `evidence_count`), `POST .../reject`, REJECTED → CANDIDATE 복원, ACCEPTED 되돌림 409 | P1 | S6 | BL-EVD-05, BL-SKL-05 | AC-09, AC-21 | FR-18 |
| BL-EVD-08 | STAR export | `EvidenceExportService` + `GET /evidence/export?format=markdown`(ACCEPTED만) | P1 | S6 | BL-EVD-07 | AC-21 | FR-18 |

### 4.13 JOB — Job Radar

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-JOB-01 | **`JobFitClassifier`** | requirement skill의 축별 `gap = max(target − evidence level)` → `READY`(≤ 0), `STRETCH`(= 1), `LATER`(≥ 2), skill 없음 → null. `matchedEvidenceIds`. 확률·점수 없음 (`06-learning-engine-rules.md`) | P1 | S7 | BL-SKL-02, BL-EVD-07 | AC-22 | FR-19 |
| BL-JOB-02 | JD 분석 요청 | `JobAnalysisService` + `POST /jobs`(202, `sourceUrl` fetch 금지) + `JobAnalysisTask`(`JOB_EXTRACT`, `SkillCodeGuard`). `AiPendingJobCounter` 구현(job: 분석 중 JD의 PENDING/RUNNING 수) | P1 | S7 | BL-JOB-01, BL-FND-19, BL-FND-23, BL-AIP-07, BL-CNT-13, BL-AIP-10 | AC-22, AC-23 | FR-19 |
| BL-JOB-03 | Job 조회·삭제 API | `JobController`: `GET /jobs/{jobId}`, `GET /jobs?cursor=`, `DELETE /jobs/{jobId}` | P1 | S7 | BL-FND-19 | AC-08, AC-22 | FR-19 |
| BL-JOB-04 | JD purge·지표 | `job.application.JobPostingPurgeService`(`common.job.RetentionCleanupTarget` 구현)로 `job_description` 180일 purge, `requirementCoverageBp` 지표. `JobCoverageProvider` 구현(최근 분석 JD 5개의 REQUIRED 수와 READY 수) | P2 | S7 | BL-FND-24, BL-EVD-01, BL-JOB-02 | AC-22 | NFR-05 |
| BL-JOB-05 | 공개 채용 소스 어댑터 | 약관 검토 후 공개 API만 (자동 크롤링 금지 유지) | P3 | Later | — | — | FR-19 |

### 4.14 CNT — Content

형식·검증 규칙·작성 가이드는 `19-content-spec.md`가 기준이다.

**S1 직렬 사슬 감시 권고**: `BL-CNT-01 → CNT-02·CNT-03 → CNT-05·SKL-01 → SKL-02 → CAR-06 → CLI-07`은 병렬화할 수 없는 7단계 사슬이라 S1(14일)의 임계 경로다. S1 시작 + 7일(2026-10-04)까지 `BL-CNT-03`이 merge되지 않으면 `11-development-roadmap.md` §2.2의 재추정 조치를 미리 적용한다. CNT-03(skill tree v0)은 사용자 검수가 필요하므로 S0 마지막 주에 초안을 시작하는 것이 좋다.

| ID | 제목 | 설명 | P | Sprint | Depends on | AC | FR/NFR |
|---|---|---|---|---|---|---|---|
| BL-CNT-01 | Content 검증기 | `content/` 구조, `YamlContentReader`, `ContentValidator`(기동 시: 스키마, code 유일, parent 존재, prerequisite 순환 금지, role target 참조, conceptKey 유일, rubric weight 합 10000, catalog_version), CI content job은 `content/tools/validate_content.py`로 같은 규칙 검사 | P0 | S1 | BL-FND-14 | AC-11 | FR-06 |
| BL-CNT-02 | `ContentSeeder` | ApplicationRunner, 검증 실패 시 기동 실패, `catalog_version` 비교 upsert, 사라진 skill `active=false`·challenge `RETIRED`, 단일 트랜잭션(`04` §9) | P0 | S1 | BL-CNT-01 | AC-11 | FR-06 |
| BL-CNT-03 | Skill tree v0 | `content/skill-tree/java-backend.yaml`: skill 60~90개, 13 카테고리, prerequisite, `minutesPerLevelStep` | P0 | S1 | BL-CNT-01 | AC-11 | FR-06 |
| BL-CNT-04 | Role target | JAVA_BACKEND priority·careerImportance·축별 목표 레벨. DEC-14: ALGORITHM SHOULD, INTERVIEW MUST | P0 | S1 | BL-CNT-03 | AC-03, AC-11 | FR-05, FR-06 |
| BL-CNT-05 | Plan template | JAVA_BACKEND milestone 템플릿(오늘 ~ horizon 배치 규칙, milestone skill) | P0 | S1 | BL-CNT-03 | AC-01, AC-11 | FR-02, FR-04 |
| BL-CNT-06 | Seed 복습 카드 | 50장 이상(JAVA·SPRING·DATABASE 중심), conceptKey·reviewType·rubric | P0 | S2 | BL-CNT-03 | AC-05, AC-10 | FR-11 |
| BL-CNT-07 | Seed practice challenge | 20개(difficulty 1~4), hints 1~3단계, rubric weightBp 합 10000, expectedConcepts, transferTargets | P0 | S3 | BL-CNT-03 | AC-04, AC-12 | FR-09 |
| BL-CNT-08 | Seed diagnostic challenge | `purpose=DIAGNOSTIC`, 카테고리별 1개 이상, 5~10분 분량 | P1 | S3 | BL-CNT-07 | AC-11 | FR-15 |
| BL-CNT-09 | Curated sources | `content/curated-sources.yaml`(CURATED_SOURCE 근거 ID). S3는 빈 목록 허용 | P1 | S3 | BL-CNT-01 | AC-07 | FR-14 |
| BL-CNT-10 | Prompt v1 (S3) | `challenge.generate`, `challenge.evaluate`, `hint.generate`, `review.evaluate`(`review.variant`는 BL-MEM-10 Later와 함께). system.md는 `/responses`의 `instructions`로 전달되며 JSON 스키마는 `text.format`으로 붙는다 | P0 | S3 | BL-AIP-05 | AC-04, AC-16 | FR-09, FR-10, FR-11 |
| BL-CNT-11 | Prompt v1 (S4) | `coach.review`, `coach.response-feedback` | P1 | S4 | BL-AIP-05 | AC-06, AC-19 | FR-12 |
| BL-CNT-12 | Prompt v1 (S6) | `evidence.draft` | P1 | S6 | BL-AIP-05 | AC-21 | FR-18 |
| BL-CNT-13 | Prompt v1 (S7) | `job.extract` | P1 | S7 | BL-AIP-05 | AC-22 | FR-19 |
| BL-CNT-14 | 1차 튜닝 | 실사용 4주 데이터로 planner 가중치·budget 계수·seed 목표·카드 품질 조정. 변경값과 근거를 ADR 또는 변경 이력에 기록 | P2 | S5 | BL-CAR-14 | AC-02, AC-03 | FR-05, FR-07 |

---

## 5. Sprint 요약

### 5.1 Epic × Sprint 항목 수

`~~취소~~` 표시 6개(`BL-SEC-01`, `BL-SEC-02`, `BL-OPS-03`, `BL-OPS-08`, `BL-OPS-14`, `BL-AIP-04`)는 P·Sprint가 비어 있어 표에서 빠진다. `BL-SEC-18`(Supabase Auth, P0)은 Sprint가 아니라 **공개 배포 게이트**에 걸려 있어 Sprint 열에 넣지 않는다(`11` §3.10).

§4 본문 행 216개 − 취소 6개 − 게이트 1개(`BL-SEC-18`) = **표 합계 209개**.

| Epic | S0 | S1 | S2 | S3 | S4 | S5 | S6 | S7 | Later | 합계 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| FND | 8 | 9 | 1 | 5 | 1 | 1 | — | 1 | — | 26 |
| SEC | 5 | 4 | 2 | 1 | — | — | 2 | — | 1 | 15 |
| OPS | 9 | — | 4 | 1 | — | — | 3 | — | 2 | 19 |
| CLI | 3 | 8 | 6 | 6 | 1 | 2 | 2 | 1 | 2 | 31 |
| CAR | — | 6 | 1 | — | — | 7 | — | — | 2 | 16 |
| SKL | — | 2 | 1 | 3 | — | 1 | — | — | — | 7 |
| TDY | — | — | 11 | 2 | — | 1 | — | — | 1 | 15 |
| MEM | — | — | 7 | 2 | — | — | — | — | 2 | 11 |
| TRN | — | — | — | 13 | — | — | — | — | 2 | 15 |
| AIP | — | 1 | — | 13 | 1 | 1 | — | — | — | 16 |
| COA | — | — | — | — | 10 | — | — | — | 1 | 11 |
| EVD | — | — | — | — | — | 4 | 4 | — | — | 8 |
| JOB | — | — | — | — | — | — | — | 4 | 1 | 5 |
| CNT | — | 5 | 1 | 4 | 1 | 1 | 1 | 1 | — | 14 |
| **합계** | **25** | **35** | **34** | **50** | **14** | **18** | **12** | **7** | **14** | **209** |

### 5.2 Sprint × Priority 항목 수

| Sprint | P0 | P1 | P2 | P3 | 합계 |
|---|---:|---:|---:|---:|---:|
| S0 | 25 | — | — | — | 25 |
| S1 | 33 | 2 | — | — | 35 |
| S2 | 28 | 5 | 1 | — | 34 |
| S3 | 36 | 13 | 1 | — | 50 |
| S4 | — | 14 | — | — | 14 |
| S5 | 8 | 8 | 2 | — | 18 |
| S6 | 1 | 11 | — | — | 12 |
| S7 | — | 6 | 1 | — | 7 |
| Later | — | — | — | 14 | 14 |
| **합계** | **131** | **59** | **5** | **14** | **209** |

- S3가 가장 무겁다(50개, 3주). S3의 P1·P2 **14개**(P1 13 + P2 1)는 S4로 1회 이월할 수 있고, 이월 순서는 `BL-FND-26` → `BL-CLI-22` → `BL-SKL-06` → `BL-CNT-09` → `BL-SEC-08` → `BL-MEM-09` → `BL-TRN-04` → 나머지다(`BL-CLI-14`, `BL-CLI-18`, `BL-CLI-23`, `BL-FND-24`, `BL-TDY-13`, `BL-TRN-13`, `BL-CNT-08`). `BL-MEM-10`은 REVIEW_VARIANT 축소로 P3·Later라 대상이 아니다.
- 항목 수는 작업량이 아니다. 작업량 추정과 재추정 규칙은 `11-development-roadmap.md` §2.

---

## 6. 커버리지 색인

설계 문서의 구성 요소가 모두 백로그에 있는지 확인하는 색인이다. 새 endpoint·job·규칙 클래스를 추가하면 이 표도 갱신한다.

### 6.1 API endpoint (resource별)

| Resource | Endpoint | BL |
|---|---|---|
| health | `GET /actuator/health` | BL-FND-03 |
| me | `GET /me`, `PATCH /me` | BL-FND-21 (aiStatus·aiUsage: BL-AIP-10) |
| me | `GET /me/export` | BL-SEC-13 |
| me | `DELETE /me` | BL-SEC-14 |
| calendar | `POST /me/calendar-token`, `GET /calendar/{token}.ics` | BL-TDY-13 |
| onboarding | `POST /onboarding` | BL-CAR-06 (seed 카드 BL-MEM-08, snapshot BL-CAR-13) |
| diagnostics | `GET /diagnostics/suggestions` | BL-TRN-13 |
| career-goal | `GET /career-goal`, `PUT /career-goal` | BL-CAR-01 |
| skills | `GET /skills/tree` | BL-SKL-01 |
| skills | `GET /skills/me` | BL-SKL-02 |
| skills | `GET /skills/{skillId}/history` | BL-SKL-06 |
| plans | `GET /plans/active`, `GET /plans`, `GET /plans/{planId}` | BL-CAR-02 |
| plans | `POST /plans` | BL-CAR-03 |
| plans | `PATCH /plans/{planId}/milestones/{milestoneId}` | BL-CAR-04 |
| plans | `POST /plans/{planId}/replan/preview` | BL-CAR-12 |
| plans | `POST /plans/{planId}/replan` | BL-CAR-05 (S1), BL-CAR-07 (S2), BL-CAR-13 (S5) |
| plans | `GET /plans/active/budget` | BL-CAR-11 |
| today | `POST /today/generate` | BL-TDY-07, BL-TDY-14 |
| today | `GET /today` | BL-TDY-08 |
| today | `PATCH /today/tasks/{taskId}` | BL-TDY-09 |
| learning-sessions | `POST /learning-sessions`, `POST .../complete`, `POST .../abandon`, `GET /learning-sessions` | BL-TDY-10 |
| challenges | `GET /challenges`, `GET /challenges/{challengeId}` | BL-TRN-02 |
| challenges | `POST /challenges/generate` | BL-TRN-04 |
| challenges | `POST /challenges/{challengeId}/attempts` | BL-TRN-05 |
| challenge-attempts | `GET /challenge-attempts/{attemptId}`, `POST .../abandon` | BL-TRN-05 |
| challenge-attempts | `POST .../self-explanation` | BL-TRN-06 |
| challenge-attempts | `POST .../hints` | BL-TRN-08 |
| challenge-attempts | `POST .../submissions` | BL-TRN-09 |
| challenge-attempts | `POST .../submissions/{submissionNo}/retry` | BL-TRN-10 |
| reviews | `GET /reviews/due` | BL-MEM-05 |
| reviews | `POST /reviews/{reviewItemId}/answer` | BL-MEM-06 (evaluate: BL-MEM-09) |
| review-items | `GET /review-items`, `POST /review-items`, `PATCH /review-items/{reviewItemId}` | BL-MEM-07 |
| coach/reviews | `POST /coach/reviews` | BL-COA-02 |
| coach/reviews | `GET /coach/reviews/{reviewId}`, `GET /coach/reviews` | BL-COA-04 |
| coach/reviews | `POST .../retry` | BL-COA-05 |
| coach/reviews | `POST .../findings/{findingId}/responses` | BL-COA-06 |
| coach/reviews | `POST .../findings/{findingId}/hints` | BL-COA-07 |
| coach/reviews | `PATCH .../findings/{findingId}` | BL-COA-08 |
| coach/reviews | `POST .../complete` | BL-COA-09 |
| coach/reviews | `DELETE .../content` | BL-COA-10 |
| dashboard | `GET /dashboard` | BL-TDY-11 (S2), BL-TDY-12 (S5) |
| evidence | `GET /evidence`, `GET /evidence/{evidenceId}`, `POST /evidence` | BL-EVD-05 |
| evidence | `POST /evidence/drafts` | BL-EVD-06 |
| evidence | `PATCH /evidence/{evidenceId}`, `POST .../accept`, `POST .../reject` | BL-EVD-07 |
| evidence | `GET /evidence/export` | BL-EVD-08 |
| weekly-reviews | `GET /weekly-reviews`, `GET /weekly-reviews/{weekStartDate}`, `PUT .../reflection` | BL-EVD-03 |
| thinking-patterns | `GET /thinking-patterns/trend` | BL-EVD-04 |
| jobs | `POST /jobs` | BL-JOB-02 |
| jobs | `GET /jobs/{jobId}`, `GET /jobs`, `DELETE /jobs/{jobId}` | BL-JOB-03 |

### 6.2 스케줄 job · 비동기 task (`03-system-architecture.md` §5.3, §6)

| 구성 요소 | 종류 | BL |
|---|---|---|
| `ProgressSnapshotJob` | job | BL-CAR-14 |
| `WeeklyReviewJob` | job | BL-EVD-02 |
| `CoachContentPurgeJob` | job | BL-COA-10 |
| `RetentionCleanupJob` (+ port `RetentionCleanupTarget`) | job | BL-FND-24, BL-JOB-04 |
| `AccountDeletionJob` | job | BL-SEC-14 |
| `OrphanAsyncTaskJob` (+ port `OrphanAsyncTaskSweeper`) | job | BL-FND-23 |
| `CoachAnalysisTask` | async | BL-COA-03 |
| `ChallengeGenerationTask` | async | BL-TRN-04 |
| `SubmissionEvaluationTask` | async | BL-TRN-09 |
| `ReviewVariantTask` | async | BL-MEM-10 |
| `EvidenceDraftTask` | async | BL-EVD-06 |
| `JobAnalysisTask` | async | BL-JOB-02 |

### 6.3 도메인 규칙 클래스 (`03-system-architecture.md` §3.2 굵은 이름)

| 클래스 | `06` 절 | BL | 구현 주체 |
|---|---|---|---|
| `PlanningLevelPolicy` | §7.5 | BL-SKL-02 | 에이전트 |
| `SkillLevelRules` | §7.1~7.4 | BL-SKL-04 | 에이전트 |
| `StudyBudgetCalculator` | §3 | BL-CAR-08 | 에이전트 |
| `DeadlineRiskEvaluator` | §4.1~4.3 | BL-CAR-09 | 에이전트 |
| `ReplanSuggestionPolicy` | §4.4 | BL-CAR-10 | 에이전트 |
| `PlannerScoring` | §5.4~5.5, §5.7 | BL-TDY-02 | 에이전트 |
| `TaskProposalPolicy` | §5.3 | BL-TDY-03 | 에이전트 |
| `TimeAllocator` | §5.6 | BL-TDY-04 | 에이전트 |
| `ReasonTemplates` | §5.8 | BL-TDY-05 | 에이전트 |
| `ComebackModePolicy` | §5.5 | BL-TDY-06 | 에이전트 |
| `FinalRatingPolicy` | §6.1 | BL-MEM-02 | 에이전트 |
| `RuleBasedV1Scheduler` | §6.2, §6.6 | BL-MEM-03 | 에이전트 |
| `DueReviewSelector` | §6.5 | BL-MEM-04 | 에이전트 |
| `HintLadderPolicy` | §9.1~9.2 | BL-TRN-07 | 에이전트 |
| `RubricScorer`, `AttemptOutcomeCalculator` | §8.1~8.2 | BL-TRN-11 | 에이전트 |
| `DiscoveredByResolver` | §9.3 | BL-COA-09 | 에이전트 |
| `MetricsCalculator` | §12 | BL-EVD-01 | 에이전트 |
| `JobFitClassifier` | §13 | BL-JOB-01 | 에이전트 |
| `SelfAssessmentPropagation` (굵게 아님) | — (`05-api-spec.md`) | BL-CAR-06 | 에이전트 |

### 6.4 AI platform (`03-system-architecture.md` §3.3)

| 구성 요소 | BL |
|---|---|
| `AiProvider`, `AiRequest`, `AiResult`, `AiOperation`, `AiCallStatus`, `FakeAiProvider`, `DisabledAiProvider` | BL-AIP-01 |
| `DevPilotProperties.ai` | BL-AIP-02 |
| `DeepSeekAiProvider`, `DeepSeekBalanceClient` | BL-AIP-03 |
| `PromptRegistry` | BL-AIP-05 |
| `OutputSchemaRegistry`, `integration.ai.api.output` record 9종, 전용 `ObjectMapper` | BL-AIP-06 |
| `AiGateway`, `AiCallLog`, `AiCallLogRepository`, `AiCallLogWriter`(REQUIRES_NEW) | BL-AIP-07 |
| `OutputGuardChain` (6종) | BL-AIP-08 |
| `SecretMasker` | BL-AIP-09 |
| `AiBudgetGuard` | BL-AIP-10 |
| `AiBalanceMonitor`, `AiBalanceCheckJob` (`integration.ai.budget`) | BL-AIP-17 |
| `AiCallLogRetentionService` (`common.job.RetentionCleanupTarget` 구현) | BL-FND-24 |
| `AiCostCalculator` | BL-AIP-11 |
| AI ArchUnit 규칙 | BL-AIP-12 |
| evals | BL-AIP-13 |
