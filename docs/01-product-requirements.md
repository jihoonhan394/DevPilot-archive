# 01. Product Requirements (PRD)

> Status: Accepted (v2) · Last updated: 2026-09-18 · Related: DEC-01, DEC-05, DEC-06, DEC-16, DEC-18, `02-user-scenarios-and-ux.md`, `04-domain-model-and-db.md`, `06-learning-engine-rules.md`, `12-acceptance-criteria.md`
>
> 이 문서는 **무엇을, 왜, 어느 Sprint에** 만드는지 정의한다. 알고리즘 수치는 `06-learning-engine-rules.md`, enum·상태 전이는 `04-domain-model-and-db.md`, 요청·응답 DTO는 `05-api-spec.md`, 화면은 `02-user-scenarios-and-ux.md`가 기준이다. 여기서 ID(FR, NFR)를 정의하고 다른 문서는 이 ID로 참조한다.

---

## 1. 제품 개요 · 문제 정의

### 1.1 한 줄 정의

DevPilot은 **정해진 이직 시점까지 필요한 개발 역량을 확보하도록, 남은 시간·현재 실력·학습 기억·프로젝트 경험·채용 공고를 계속 재계산해 매일 가장 가치 높은 학습 1개를 안내하는 개인용 학습 코치**다.

| 항목 | 내용 |
|---|---|
| 제품명 | DevPilot |
| 형태 | 웹 우선 Flutter PWA + Spring Boot backend + AI 코칭 (Android 앱은 Later, DEC-18) |
| 대상 직무 | Java 백엔드 (`TargetRole.JAVA_BACKEND`만 지원) |
| 사용자 | 소유자 1명 + 초대 최대 2명 (DEC-01) |
| UI 언어 | 한국어 (식별자·기술 용어는 영어 원문) |

### 1.2 문제 정의

사용자는 이직 목표와 공부 의지가 있지만 다음 문제를 겪는다.

| # | 문제 | DevPilot의 대응 (FR) |
|---|---|---|
| P-1 | 퇴근 후 시간이 부족하고 피로해서 **학습 시작 자체**가 어렵다 | Today 1개 과제·15분 모드(FR-07), 복귀 모드(FR-21), 캘린더 구독(FR-20) |
| P-2 | 무엇을 먼저 공부해야 할지 매일 결정하기 어렵다 | 결정적 planner와 이유 표시(FR-07) |
| P-3 | 학습 내용을 빠르게 잊는다 | spaced review(FR-11) |
| P-4 | AI에게 코드를 맡기면서 원리 이해와 독립 해결력이 약해질 수 있다 | self-explain 선행, Hint Ladder(FR-09, FR-10) |
| P-5 | 자원 관리, 예외, null, 보안, 로그, 트랜잭션, 성능 문제를 스스로 인지하기 어렵다 | self-review 선행 Project Coach, thinking pattern(FR-12, FR-13) |
| P-6 | 현재 실력이 채용 요구와 얼마나 맞는지 판단하기 어렵다 | 증거 기반 skill state(FR-06), Job Radar(FR-19) |
| P-7 | 이직 기한이 정해져 있어 모든 기술을 완벽히 공부할 수 없다 | study budget·deadline risk·replan 제안(FR-05) |
| P-8 | 공부한 내용이 이력서·면접 소재로 정리되지 않는다 | Evidence·STAR export(FR-18) |

### 1.3 제품 목표 문장

목표 이직 시점과 현재 실력을 바탕으로 학습 계획을 재편하고, 매일 가장 가치 높은 학습을 제시하며, 실제 프로젝트 코드와 반복 회상을 통해 **AI 도움 없이 문제를 인지하고 해결하는 능력**을 높인다.

---

## 2. 목표 · 비목표

### 2.1 목표

| ID | 목표 | 확인 방법 |
|---|---|---|
| G-1 | 사용자가 매일 "무엇을 할지" 고민하지 않고 30초 안에 학습을 시작한다 | Today 생성 → 시작까지 화면 전환 2회 이하 (`02` §4.2) |
| G-2 | 2026-10-26부터 실제 학습에 매일 사용한다 | S2 종료 시 AC-02, AC-05, AC-10 통과 |
| G-3 | 학습 결과가 자기평가가 아니라 **증거**로 skill state에 반영된다 | AC-09, `06` §7 test vectors |
| G-4 | 도움(hint) 사용량이 줄고 스스로 발견한 위험이 늘어나는 추세를 사용자가 확인한다 | §6 지표 |
| G-5 | 이직 기한 대비 위험을 숫자 근거와 함께 보고, 무엇을 미룰지 결정한다 | AC-03 |
| G-6 | 지원 시작(2027-01) 전에 이력서·면접용 증거를 Markdown으로 내보낸다 | AC-21 |
| G-7 | AI 비용을 월 USD 3 이하로 통제하고, AI가 없어도 핵심 학습은 계속된다 | AC-12, AC-13 |

### 2.2 비목표

| # | 비목표 | 근거 |
|---|---|---|
| NG-1 | IDE 자체 제작, IDE 플러그인 (Later) | 원칙 9 |
| NG-2 | Copilot 대체, 자동 기능 개발 agent | 원칙 3 |
| NG-3 | 상용 LMS, 기업용 source code ingestion platform | 개인용 제품 |
| NG-4 | 실시간 pair programming | 범위 밖 |
| NG-5 | 첫 버전에서 Kafka/Kubernetes/MSA 학습 플랫폼 구현 | 범위 밖 |
| NG-6 | **합격 확률, 적합도 점수, 퍼센트 매칭 제공** | 근거 없는 수치가 결정을 왜곡함. Job Radar는 `READY/STRETCH/LATER`만 (FR-19) |
| NG-7 | **MVP에서 사용자 코드 실행**(compiler/test runner). `VERIFIED`는 curated source만 가능 | `06` §10. code runner는 Later |
| NG-8 | **채용 공고 자동 수집·크롤링, URL 본문 fetch** | 서버는 외부 URL을 가져오지 않는다. 사용자가 본문을 붙여넣는다 |
| NG-9 | 팀·다중 사용자 협업, 사용자 간 데이터 공유 | DEC-01 |
| NG-10 | 공개 가입, 불특정 다수 서비스 | allowlist (FR-01) |
| NG-11 | 연속 학습일(streak), 순위, 배지 수집 같은 게임화 | 원칙 "guilt UI 금지" (`02` §1) |
| NG-12 | 이메일·Web Push 알림 (MVP) | 캘린더 구독으로 대체 (FR-20) |
| NG-13 | 네이티브 Android/iOS 앱 (MVP) | DEC-18 |
| NG-14 | 나이·성별 등 개인 속성을 계산에 사용 | §3.4 |

---

## 3. 사용자 · 페르소나

### 3.1 사용자 수 전제 (DEC-01)

- 사용자는 **소유자 1명 + 초대 최대 2명**이다. backend allowlist(`devpilot.security.allowed-emails`/`allowed-subjects`)로만 접근을 허용한다.
- 사용자 간 데이터 공유, 조회, 비교 기능은 없다. 모든 데이터는 `user_id`로 격리한다(I-15).
- `UserRole.ADMIN`은 운영 작업용이다. MVP에 ADMIN 전용 화면은 없다.

### 3.2 Persona A — Experienced Transition (`ExperienceProfile.EXPERIENCED_TRANSITION`)

| 항목 | 내용 |
|---|---|
| 경력 | 2020-02 입사 경력자. Java/Android/Spring legacy, 운영, 사용자 대응 경험 |
| 부족한 증거 | 현대 Java, Spring Boot, JPA, 테스트, DB 설계, Docker/Cloud |
| 목표 | 2027-04 이전 Java 백엔드 이직 |
| 주 사용 패턴 | 평일 퇴근 후 30~60분(데스크톱), 출퇴근 5분 복습(모바일 PWA), 주말 프로젝트 코드 리뷰 |
| 제품에 기대하는 것 | 이미 아는 기초를 반복하지 않기(진단 FR-15), 기한 대비 무엇을 버릴지 결정(FR-05), 실무 문제 인지력의 증거(FR-12, FR-18) |

### 3.3 Persona B — Developer Starter (`ExperienceProfile.DEVELOPER_STARTER`)

| 항목 | 내용 |
|---|---|
| 경력 | 2025-03 입사. 사용자 대응 위주, 실제 개발 경험 부족 |
| 목표 | Java/Web/DB/Spring 기초에서 실제 개발 직무 수준으로 성장 |
| 주 사용 패턴 | 짧고 자주. 모바일 복습 비중이 높음 |
| 제품에 기대하는 것 | 매일 할 일 1개(FR-07), 막혔을 때 답이 아니라 단계적 힌트(FR-10), 기초 개념의 반복 회상(FR-11) |

### 3.4 속성 사용 규칙

- **나이는 수집하지 않고, skill 계산·planner·Job Radar 어디에도 쓰지 않는다.**
- `experienceProfile`, `careerStartDate`는 AI 프롬프트 맥락과 표시용으로만 쓴다. 결정적 규칙(`06`)의 입력이 아니다.
- 이메일은 allowlist 비교에만 쓰고 DB에 저장하지 않는다(`app_user`에 email 컬럼 없음).

---

## 4. 핵심 원칙

원문 10개 원칙을 유지하고, v2에서 **강제 지점**을 붙였다. 원칙이 충돌하면 번호가 작은 원칙이 우선한다.

| # | 원칙 | 의미 | 강제 지점 |
|---|---|---|---|
| 1 | **Deadline first** | 이직 목표일이 학습 완성도보다 우선한다 | budget/risk(`06` §3~4), risk ≥ HIGH면 LATER 제외·MUST 가중(`06` §5.2, §5.5) |
| 2 | **One important thing today** | 하루 화면은 핵심 과업 하나를 중심으로 구성한다 | 활성 main task 1개(I-04), Today 첫 화면(`02` §1) |
| 3 | **Do not replace thinking** | AI는 답을 대신 쓰지 않고 사용자가 먼저 생각하게 한다 | self-explanation 선행(HL-2), coach self-review 선행(FR-12), finding에 수정 코드 없음(AC-06), 코드 노출 가드(HL-8) |
| 4 | **Evidence over self-rating** | 실력은 자기평가보다 풀이·설명·코드·재현 가능한 결과로 갱신한다 | 자기평가 상한 3·planning level 분리(`06` §7.5), 레벨 변경은 규칙 엔진만(I-12) |
| 5 | **Memory is database** | 장기 사용자 상태는 LLM 대화가 아니라 DB에 저장한다 | AI 대화 미저장(`03` §11), 모든 판단은 `learning_event` payload 기반(`04` §6) |
| 6 | **Verified when possible** | 도구·검수 근거를 AI 판단보다 우선하고, 근거 수준을 숨기지 않는다 | `VerificationGuard`(`06` §10), DB CHECK(I-07, I-08), 배지 상시 표시(FR-14) |
| 7 | **Adaptive repetition** | 틀리거나 도움을 많이 쓴 항목은 더 짧은 간격으로 다시 낸다 | 최종 등급 조정(`06` §6.1), 복습 카드 자동 생성(`06` §8.3) |
| 8 | **Learning from real code** | 실제 사이드 프로젝트 코드와 diff에서 학습 포인트를 찾는다 | Project Coach(FR-12), PROJECT_TASK(`06` §5.3) |
| 9 | **No IDE reinvention** | IDE를 대체하지 않는다. 붙여넣기로 연결한다 | NG-1, NG-7 |
| 10 | **Privacy by default** | 회사 코드·비밀정보는 보내지 않고, 개인 코드도 전송 전 최소화·마스킹한다 | 동의 체크·secret masking·private key 차단(I-14), 원문 30일 보존(DEC-16), export/삭제(FR-23) |

---

## 5. 제품 루프

```text
 Career Goal · Deadline (FR-03)
        │
        ▼
 Plan version · Skill target (FR-04) ◀──────────────┐
        │                                            │
        ▼                                            │
 Study budget · Deadline risk (FR-05)                │
        │                                            │
        ▼                                            │
 Today: main task 1개 + 복습 (FR-07)                 │
        │                                            │
        ├──▶ Review (FR-11) ─────────────┐           │
        ├──▶ Training (FR-09)            │           │
        │      self-explain → Hint Ladder (FR-10)    │
        │      → 제출 → 비동기 평가                  │
        └──▶ Project Coach (FR-12)       │           │
               self-review → 분석 → 응답 → hint → close
                                         │           │
                                         ▼           │
                              Learning Event (append-only, `04` §6)
                                         │           │
              ┌──────────────────────────┼───────────┤
              ▼                          ▼           │
   Review schedule (FR-11)   Skill state 갱신 (FR-06)│
   Thinking pattern (FR-13)  Evidence 후보 (FR-18)   │
              │                          │           │
              └────────────┬─────────────┘           │
                           ▼                         │
            Weekly review · Dashboard (FR-16, FR-17) │
                           │                         │
                           └── risk 상승 → Replan ───┘
```

| 단계 | 사용자가 하는 일 | 시스템이 하는 일 | AI 필요 |
|---|---|---|---|
| 목표·계획 | 날짜, 시간, 카테고리 자기평가 입력 | 템플릿 plan, seed 카드 배정 | 없음 |
| Today | 가능 시간·컨디션 선택 | planner 점수, 이유 템플릿 | 없음 |
| 복습 | 기억해서 답하고 자기평가 | 최종 등급 조정, 다음 due | 선택(REVIEW_EVALUATE) |
| Training | 먼저 설명 → 풀이 제출 | 평가, outcome, 복습 카드 | 평가·4단계 이상 hint |
| Coach | 먼저 우려점 작성 → 질문에 응답 | finding 질문, discoveredBy 판정 | 분석·피드백·hint |
| 기록 | — | learning event → skill state, thinking pattern | 없음 |
| 조정 | 주간 회고, replan 결정 | 지표, risk, defer/축소 제안 | 없음 |

---

## 6. 성공 지표

- 계산식은 `06-learning-engine-rules.md` §12가 유일한 기준이다. 결과는 정수(bp, milli)다.
- 측정 기간: **S2 종료 후 8주 = 2026-10-26 ~ 2026-12-20** (plan-day 기준 ISO week 8개). 주간 값은 `weekly_review.metrics_json`(`04` §5.7)에서 읽는다.
- 지표는 사용자별로 본다. 사용자 간 비교·합산 화면은 만들지 않는다.
- 목표 미달은 제품 개선 신호다. 사용자에게 "목표 미달" 문구로 보여주지 않는다(`02` §9).

| 지표 | 정의 (`06` §12) | 측정 시작 | 초기 목표 (8주) |
|---|---|---|---|
| 주간 완료 세션 수 | `completedSessions` (주간) | 2026-10-26 | **주 4회 이상**을 8주 중 6주 이상 |
| 주간 학습 시간 | `studyMinutes` (주간) | 2026-10-26 | 참고 지표. 완료율 `completionRateBp`(`06` §3.3, 28일) **≥ 6000** |
| Recall 성공률 | `recallSuccessRateBp` | 2026-10-26 | 3주차부터 주간 **≥ 7000** |
| 독립 해결률 | `independentSolveRateBp` | S3 시작(2026-10-26) | 8주차 28일 값 **≥ 4000** (분모 5 이상일 때 판정) |
| 평균 hint 단계 | `averageHintLevelMilli` | S3 시작 | **하락 추세**: 7~8주차 평균 < 3~4주차 평균, 8주차 값 **≤ 2000** |
| 스스로 발견한 위험 | `selfFoundRiskCount` | S4 종료(2026-12-07) | 2주마다 **1개 이상** |
| Deadline risk | `riskLevel`, `ratioBp` (주 마지막 snapshot) | S5 종료(2026-12-21) | 매주 **MEDIUM 이하** 또는 replan으로 MEDIUM 이하 복귀 |
| 승인된 evidence | `acceptedEvidenceCount` | S6 | 2027-01-04까지 누적 **3개 이상** (8주 범위 밖, 추적만) |
| 약한 thinking 축 | `weakThinkingAxes` | S4 종료 | 목표 없음. 상위 3개 축이 Today/Coach 맥락에 반영되는지 확인 |
| JD 요구사항 준비 비율 | `requirementCoverageBp` | S7 | 목표 없음. **사용자 화면에 퍼센트로 표시하지 않는다**(NG-6). 내부 추적만 |

제품 건강 확인(지표 외):
- Today를 생성한 plan-day 수 ≥ 주 5일 (`daily_plan` 수)
- AI 월 비용 ≤ USD 3 (NFR-01)

---

## 7. 범위 (Sprint별)

Sprint 기간은 `11-development-roadmap.md`와 같다. S2 종료 다음 날(2026-10-26)부터 실사용한다.

| Sprint | 기간 | 목표 | FR (해당 Sprint에 완성 또는 시작하는 부분) | 주요 AC |
|---|---|---|---|---|
| S0 | 2026-09-17 ~ 09-27 | Bootstrap, walking skeleton, 배포, spike | FR-01(로그인 왕복, `GET /me` 401→200) | — |
| S1 | 09-28 ~ 10-11 | Identity · Onboarding · Goal · Plan · seed v0 | FR-01(allowlist, JIT), FR-02, FR-03, FR-04(milestone 편집, 최소 replan 저장), FR-06(조회, 자기평가 반영), FR-24 | AC-01, AC-11(온보딩), AC-18, AC-24 |
| S2 | 10-12 ~ 10-25 | Today · Session · Review(AI 없음) · Dashboard 최소 · PWA | FR-07, FR-08, FR-11(due, 답변, 스케줄, 수동 카드), FR-16(최소), FR-20, FR-21 | AC-02, AC-05, AC-10, AC-17 |
| S3 | 10-26 ~ 11-15 | AI Platform · Training · Skill updater | FR-06(규칙 갱신, 이력), FR-09, FR-10(challenge), FR-11(evaluate, variant), FR-14(guard 기반), FR-15, FR-22 | AC-04, AC-09, AC-11(진단), AC-12, AC-13, AC-16, AC-23 |
| S4 | 11-16 ~ 12-06 | Project Coach · evals v1 | FR-10(coach finding), FR-12, FR-13(기록), FR-14(finding 배지) | AC-06, AC-07, AC-14, AC-19, AC-12·AC-23 재검증 |
| S5 | 12-07 ~ 12-20 | Replan · Budget/Risk · Weekly review · Dashboard 완성 | FR-05, FR-13(추세), FR-16(완성), FR-17 | AC-03, AC-21(weekly) |
| S6 | 12-21 ~ 2027-01-04 | Evidence · Export · 계정 삭제 · 백업 · 하드닝 | FR-18, FR-23 | AC-08 재검증, AC-15, AC-20, AC-21(evidence) |
| S7 | 2027-01-05 ~ 01-25 | Job Radar | FR-19 | AC-22 |
| Later | 2027-02 ~ | 확장 | Android 앱, FSRS, code runner, IDE plugin, 데모 모드, 공휴일 반영, 다크 모드, 이메일·Push 알림 | — |

규칙:
- 각 Sprint 끝에 **배포된 환경에서** 해당 AC를 확인한다.
- Sprint에 아직 없는 기능의 화면 진입점은 숨긴다(`02` §2.4 feature flag). "준비 중" 화면을 만들지 않는다.
- NFR은 S0부터 적용한다. 측정 방식은 §9에 있다.

---

## 8. 기능 요구사항

표기:
- **관련 API**는 base `/api/v1` 생략. 인증이 필요한 모든 `POST`는 `Idempotency-Key` 필수(`03` §5.4, 예외: `POST /plans/{planId}/replan/preview`).
- **관련 화면**의 SCR ID는 `02-user-scenarios-and-ux.md` §3에서 정의한다.
- **우선순위**: MUST = 해당 Sprint 종료 조건, SHOULD = 일정이 밀리면 다음 Sprint로 넘길 수 있음.
- 입력 상한은 `05-api-spec.md`가 서버 기준이며, 클라이언트는 `02` §3.2 표로 같은 값을 미리 검사한다.

### FR-01 인증·접근 제어 (GitHub OAuth, allowlist, JIT 사용자 생성)

**설명** — 로그인하면 backend가 JWT를 검증한 뒤 allowlist에 있는 사용자만 첫 요청 시 `app_user`로 생성한다. 로그인 방식은 `devpilot.security.auth-mode`가 정한다: **`devtoken`(기본, 운영 포함)** 은 이메일을 입력하면 backend가 서명한 토큰을 발급하고(tailnet 전용, ADR-033), `supabase`(Later)는 GitHub OAuth를 쓴다(DEC-08).

**사용자 스토리** — As a 소유자, I want 내가 초대한 사람만 로그인해 쓰게 하고 싶다, so that 외부인이 AI 비용을 쓰거나 데이터에 접근하지 못한다.

**규칙**
- 로그인 수단은 GitHub OAuth 하나다. 비밀번호·이메일 매직링크 로그인은 제공하지 않는다.
- backend는 JWT를 JWKS로 검증한다(서명, `iss`, `aud=authenticated`, `exp`/`nbf`, clock skew 60초 — `03` §4.2). 실패는 `401 AUTHENTICATION_REQUIRED`이며 세부 사유를 응답에 넣지 않는다.
- 사용자 프로비저닝은 `03` §4.3 순서를 따른다: `sub`로 조회 → 없으면 allowlist(이메일 소문자·trim 비교 또는 `sub`) 확인 → `INSERT … ON CONFLICT DO NOTHING` → 재조회.
- allowlist에 없으면 `403 USER_NOT_ALLOWED`이고 `app_user`를 만들지 않는다(AC-18). 이미 생성된 사용자도 allowlist에서 빠지면 다음 요청부터 403이다.
- 생성 시 기본값: `displayName` = 이메일 `@` 앞부분(없으면 `사용자`), `timezone=Asia/Seoul`, `dayStartHour=4`, `weekdayStudyMinutes=45`, `weekendStudyMinutes=240`, `role=USER`.
- `status=DELETION_REQUESTED` 사용자는 `GET /me`, `DELETE /me`만 호출할 수 있고 그 외 API는 `403 FORBIDDEN`이다(`03` §4.1, `05-api-spec.md` §1.4.2).
- 다른 사용자의 리소스와 존재하지 않는 리소스는 똑같이 404다(`03` §4.4, I-15).
- 인증된 `/api/v1/**` 요청은 사용자당 분당 120회로 제한한다(`RateLimitFilter`, 초과 시 `429 RATE_LIMITED` + `Retry-After`, `05-api-spec.md` §1.4.3).
- 로그아웃은 클라이언트가 저장한 토큰을 버리는 것이다. backend에 로그아웃 API는 없다.
- 사용자는 최대 3명(DEC-01)이다. allowlist 변경은 환경변수 수정과 재기동으로 한다.

**관련 API** — `GET /me`, `POST /api/v1/dev/token`(devtoken 모드). Supabase 모드의 OAuth redirect·token refresh는 backend API가 아니다
**관련 화면** — SCR-LOGIN, SCR-AUTH-CALLBACK, SCR-NOT-ALLOWED
**AC** — AC-08, AC-18 · **Sprint** — S0(로그인 왕복), S1(allowlist, JIT) · **우선순위** — MUST

### FR-02 온보딩 (목표, 시간, 카테고리 자기평가 13개, 계획 템플릿, seed 카드 배정)

**설명** — 최초 로그인 사용자가 4단계, 5분 이내로 목표·시간·현재 수준을 입력하면 한 번의 요청으로 career goal, 활성 plan v1, skill 자기평가, seed 복습 카드를 만든다.

**사용자 스토리** — As a 처음 온 사용자, I want 몇 가지만 답하면 바로 계획과 오늘 할 일을 받고 싶다, so that 첫날부터 설정에 시간을 쓰지 않고 학습을 시작한다.

**규칙**
- 단계: ① 목표 ② 시간 ③ 현재 수준 → 제출 → ④ 생성된 계획 확인. ①~③은 클라이언트에만 보관하고, ③에서 `POST /onboarding` 1회로 제출한다. 계획 미리보기 API는 없다.
- 입력 항목:

| 단계 | 필드 | 필수 | 제약 |
|---|---|---|---|
| ① | `experienceProfile` | Y | `EXPERIENCED_TRANSITION`, `DEVELOPER_STARTER`, `OTHER` |
| ① | `displayName` | Y | 1~100자, 기본값 = `GET /me`의 `displayName` |
| ① | `careerStartDate` | N | 1970-01-01 ~ 오늘 |
| ① | `careerGoal.targetRole` | Y | `JAVA_BACKEND` 고정 |
| ① | `careerGoal.applicationStartDate` | N | 오늘 − 1년 ~ `targetCompletionDate` |
| ① | `careerGoal.targetCompletionDate` | Y | 오늘(plan-day) 다음 날 ~ 3년 이내 |
| ② | `weekdayStudyMinutes`, `weekendStudyMinutes` | Y | 0~720, 기본 45 / 240 |
| ② | `dayStartHour` | Y | 0~6, 기본 4 |
| ② | `timezone` | Y | IANA ID, 기본 브라우저 값(없으면 `Asia/Seoul`) |
| ③ | `selfAssessments[]` (`category`, `level`) | Y | 클라이언트는 `SkillCategory` 13개를 모두 보낸다(기본 0). 화면 선택지는 0~4(`UNKNOWN`~`PRACTICAL`), 서버 허용은 ≤ 13개·category 중복 금지·level 0~5 |
| ③ | `careerGoal.focusSkillCodes` | N | 최대 10개, 중복 없음, 활성 catalog code |
| — | `useTemplate` | Y | 클라이언트는 항상 `true` |

- 처리는 **한 트랜잭션**이다: `app_user` 갱신(`onboarding_completed_at`) → `career_goal` → 카테고리 자기평가를 role target이 있는 활성 non-root skill마다 그 category 값으로 `self_assessed_level`에 전파(`SelfAssessmentPropagation`, `self_assessment_active=true`, root skill 제외, `05-api-spec.md` §4.1 5단계) → plan 템플릿으로 활성 plan v1과 milestone 생성, `role_skill_target` 전체를 `plan_skill_target`으로 복사(`06` §11.3) → seed 카드를 사용자 `review_item`으로 복사하고 하루 5장씩 due 분산(`06` §6.3, `04` §9) → 오늘 날짜 `plan_progress_snapshot` upsert. 처리 순서의 기준은 `05-api-spec.md` §4.1이다.
- 자기평가는 planning level에만 반영되고 상한은 3이다(`06` §7.5). evidence level은 0에서 시작한다.
- 응답은 `201`이고 `user`, `careerGoal`, `activePlan`(최신 risk 포함), `assignedSeedCardCount`, `suggestedDiagnostics`(S3 이전 `[]`)를 포함한다.
- 이미 완료한 사용자가 다시 제출하면 `409 ONBOARDING_ALREADY_COMPLETED`다.
- 온보딩 전에 허용되는 API: `GET /me`, `PATCH /me`, `POST /onboarding`, `GET /skills/tree`, `GET /me/export`, `DELETE /me`. 그 외 사용자 데이터 API는 `409 ONBOARDING_REQUIRED`다(AC-11).
- 나이, 성별, 회사명은 묻지 않는다.

**관련 API** — `POST /onboarding`, `GET /skills/tree?role=JAVA_BACKEND`, `GET /me`
**관련 화면** — SCR-ONBOARDING (1~4단계)
**AC** — AC-11 · **Sprint** — S1 · **우선순위** — MUST

### FR-03 커리어 목표 관리

**설명** — 사용자는 목표 직무, 지원 시작일, 이직 완료 목표일, 집중 skill을 조회·수정한다.

**사용자 스토리** — As a 이직 준비자, I want 사정이 바뀌면 목표 날짜를 고치고 싶다, so that 계획과 위험 계산이 현실을 따라간다.

**규칙**
- 사용자당 career goal은 1개다(I-01). `GET /career-goal`에서 없으면 `404 CAREER_GOAL_NOT_FOUND`(온보딩 완료 사용자에게는 발생하지 않는다).
- `PUT /career-goal`은 전체 교체이며 `version`이 필수다. 불일치면 `409 CONCURRENT_MODIFICATION`.
- 검증: `targetRole=JAVA_BACKEND`, `targetCompletionDate`는 오늘(plan-day)+1일 ~ +3년, `applicationStartDate`는 null 또는 오늘−1년 ~ `targetCompletionDate`(DB CHECK), `focusSkillCodes` 최대 10개·중복 없음·활성 catalog code.
- `PUT`은 기존 목표만 교체한다. 목표가 없으면 `404 CAREER_GOAL_NOT_FOUND`이고 새로 만들지 않는다(생성은 온보딩).
- 날짜가 바뀌면 goal은 즉시 저장하고 활성 plan의 `replan_recommended=true`로 표시한다. **자동으로 replan하지 않는다**(`06` §11.1).
- budget horizon은 `applicationStartDate`가 오늘 이후면 그 날짜, 아니면 `targetCompletionDate`다(`06` §3.1).
- focus skill은 planner의 `projectNeed` factor다(`06` §5.4).

**관련 API** — `GET /career-goal`, `PUT /career-goal`
**관련 화면** — SCR-CAREER-GOAL, SCR-PLAN
**AC** — AC-01 · **Sprint** — S1 · **우선순위** — MUST

### FR-04 학습 계획·milestone·계획 버전

**설명** — 활성 plan은 milestone(기간, priority, 관련 skill)과 계획별 skill 목표(`plan_skill_target`)를 가진다. 구조를 바꾸면 새 plan version을 만들고 이전 version은 조회만 가능하다.

**사용자 스토리** — As a 사용자, I want 월별 milestone을 보고 진행 상태를 바꾸고, 구조를 바꿀 때는 이전 계획을 남기고 싶다, so that 계획이 어떻게 바뀌어 왔는지 설명할 수 있다.

**규칙**
- 사용자당 `ACTIVE` plan은 1개다(I-02). `SUPERSEDED` plan은 읽기 전용이다. 수정 시도는 `409 PLAN_NOT_ACTIVE`.
- 변경 분류(`06` §11.1):
  - in-place `PATCH`: milestone `status`, `description`, `sortOrder` (+ `version`)
  - 새 version(`POST /plans/{planId}/replan`): milestone 추가·삭제, 날짜·priority·skill 구성 변경, skill target defer/축소
- replan 저장 순서는 `06` §11.2다(기존 plan `SUPERSEDED` → **flush** → 새 plan INSERT). 동시 replan 2건 중 1건만 성공한다(AC-24).
- milestone 제약: 최대 24개, `title` 1~200자, `description` ≤ 2000자, 날짜 오늘−1년 ~ 오늘+3년, `startDate ≤ endDate`, `skillCodes` 최대 30개·활성 catalog code, `sortOrder` 0~10000.
- replan commit의 `reason`은 **필수** 1~1000자(`learning_plan.change_reason`). preview에서는 선택이다.
- milestone ID는 새 version에서 새 UUID다. 과거 `daily_plan`, `learning_task`는 이전 plan/milestone ID를 유지한다.
- `POST /plans`는 활성 plan이 없을 때만 템플릿으로 생성한다. 있으면 `409 ACTIVE_PLAN_EXISTS`.
- version 이력은 `GET /plans?cursor=`로 최신순 조회한다.
- S1에는 replan을 **미리보기 없이** 저장만 한다(milestone 구조 편집용, `acceptedDeferrals`·`acceptedTargetReductions`·`restoredDeferrals`는 빈 배열). S5에서 미리보기·제안·defer 복원을 붙인다(FR-05).

**관련 API** — `GET /plans/active`, `GET /plans?cursor=`, `GET /plans/{planId}`, `POST /plans`, `PATCH /plans/{planId}/milestones/{milestoneId}`, `POST /plans/{planId}/replan`
**관련 화면** — SCR-PLAN, SCR-REPLAN, SCR-PLAN-HISTORY, SCR-PLAN-VERSION, SCR-ONBOARDING(4단계)
**AC** — AC-01, AC-24 · **Sprint** — S1 · **우선순위** — MUST

### FR-05 Deadline-aware replanning (budget, risk, defer/축소 제안)

**설명** — 남은 가능 시간(study budget)과 MUST 목표에 필요한 시간을 비교해 deadline risk를 계산하고, 계획 변경 시 SHOULD defer와 MUST 목표 축소를 **제안**한다. 적용은 사용자가 고른다.

**사용자 스토리** — As a 기한이 정해진 사용자, I want 지금 속도로 목표일까지 무엇이 가능한지와 무엇을 미뤄야 하는지 알고 싶다, so that 모든 것을 하려다 전부 놓치지 않는다.

**규칙**
- budget: nominal → 28일 완료율 → effective (`06` §3). 완료율 기록이 14일 미만이면 7000bp.
- required minutes와 risk 4단계(`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`)는 `06` §4.2~4.3. `deferred=true`인 target과 `LATER`는 제외한다.
- 제안 규칙은 `06` §4.4다. **risk ≤ MEDIUM이면 제안하지 않는다.** 제안은 저장하지 않고 자동 적용하지 않는다.
- `POST /plans/{planId}/replan/preview`는 편집안 기준 budget/risk, `deferSuggestions`, `mustTargetReductionSuggestions`, `riskAfterSuggestions`를 반환하고 아무것도 저장하지 않는다(IK 선택).
- preview 요청도 `acceptedDeferrals`, `acceptedTargetReductions`, `restoredDeferrals`를 적용한 상태로 계산한다(`05-api-spec.md` §7.7). 클라이언트는 제안 선택을 바꾸면 preview를 다시 호출해 선택 반영 후 risk를 보여준다.
- commit(`POST /plans/{planId}/replan`)은 사용자가 체크한 `acceptedDeferrals`, `acceptedTargetReductions`만 적용한다(`06` §11.2 7단계). "3 미만으로 낮추지 않는다"는 제안 생성 규칙이다(`06` §4.4). commit은 `newTarget` 0~5를 받고 현재 target보다 낮아야 한다(아니면 `TARGET_NOT_REDUCED`).
- 이미 미룬 기술은 `restoredDeferrals`로 다시 포함할 수 있다(`deferred=false`, `adjustment=USER_EDITED`, `06` §11.2 7단계). 같은 skill을 defer와 복원에 함께 넣으면 `400 VALIDATION_FAILED`다.
- `ProgressSnapshotJob`이 매일 사용자 `dayStartHour`에 snapshot을 upsert한다(`03` §6). replan commit 직후(`06` §11.2 9단계)와 온보딩 직후(`05-api-spec.md` §4.1)에도 upsert한다.
- risk는 Today(`daily_plan.deadline_risk`), Plan, Dashboard에 같은 배지로 표시한다. `ratioBp`는 "필요 시간 ÷ 가능 시간"으로 표시한다(합격 확률이 아니다).
- risk ≥ HIGH면 planner가 MUST를 가중하고 LATER를 후보에서 뺀다(`06` §5.2, §5.5).

**관련 API** — `GET /plans/active/budget`, `POST /plans/{planId}/replan/preview`, `POST /plans/{planId}/replan`, `GET /plans/active`
**관련 화면** — SCR-PLAN, SCR-REPLAN, SCR-DASHBOARD, SCR-TODAY
**AC** — AC-03 · **Sprint** — S5 · **우선순위** — MUST

### FR-06 Skill state (4축, 증거 기반 갱신, 변경 이력)

**설명** — skill마다 KNOWLEDGE, IMPLEMENTATION, EXPLANATION, DEBUGGING 4축 레벨(0~5)을 가진다. 레벨은 learning event에 대한 결정적 규칙으로만 바뀌고, 모든 변경은 근거와 함께 이력으로 남는다.

**사용자 스토리** — As a 사용자, I want 내 실력이 왜 이 레벨인지 근거를 보고 싶다, so that 자기평가가 아니라 실제로 한 일로 성장을 확인한다.

**규칙**
- 레벨 의미: `SkillLevel` 0 `UNKNOWN`, 1 `SEEN`, 2 `GUIDED`, 3 `INDEPENDENT_BASIC`, 4 `PRACTICAL`, 5 `TRANSFERABLE`.
- 세 값을 구분해 저장·표시한다: **evidence level**(규칙 결과), **self-assessed level**(온보딩), **planning level**(`06` §7.5, planner·budget 입력).
- 갱신은 `LearningEventRecorded` 동기 처리, 최근 60일 무효화되지 않은 이벤트 payload만 사용, 축당 한 번에 1단계, 24시간 cooldown이다(`06` §7.1~7.3).
- 진단 통과는 예외 규칙이다(`06` §7.4, FR-15).
- 모든 변경은 `skill_state_change(axis, from, to, rule_code, evidence_event_ids)`를 남긴다(I-12). 이력은 최신순 cursor로 조회한다.
- **사용자가 레벨을 직접 수정하는 API는 없다.** 이의가 있으면 학습 활동으로 증거를 만든다.
- AI는 레벨이나 점수를 출력하지 않는다. AI 결과는 rubric `met` 판정까지이고 계산은 서버가 한다(`06` §8).
- 목표 레벨은 활성 plan의 `plan_skill_target`이다.

**관련 API** — `GET /skills/tree?role=JAVA_BACKEND`, `GET /skills/me`, `GET /skills/{skillId}/history?cursor=`
**관련 화면** — SCR-SKILL-TREE, SCR-SKILL-DETAIL, SCR-DASHBOARD
**AC** — AC-09 · **Sprint** — S1(조회·자기평가), S3(규칙 갱신·이력) · **우선순위** — MUST

### FR-07 Today 계획 (planner, 재생성, task 상태)

**설명** — 사용자가 오늘 가능 시간과 컨디션을 고르면 결정적 planner가 main task 1개와 복습 task(있으면)를 만들고 이유를 1~3개 보여준다.

**사용자 스토리** — As a 퇴근한 사용자, I want 시간과 컨디션만 고르면 오늘 할 가장 중요한 일 하나를 받고 싶다, so that 무엇을 할지 고민하는 데 에너지를 쓰지 않는다.

**규칙**
- 입력: `availableMinutes` 5~720, `energyLevel` `LOW|NORMAL|HIGH`, `force`(기본 false).
- "오늘"은 plan-day다(`06` §2). plan-day당 `daily_plan` 1개(I-03), 활성 main task(PLANNED/IN_PROGRESS) 1개(I-04).
- 후보·task 제안·factor·modifier·동점 처리는 `06` §5.2~5.5, 시간 배분은 `06` §5.6이다. AI를 쓰지 않는다.
- due 복습이 있고 배분된 `reviewMinutes > 0`이면 `REVIEW` task 1개(`is_main=false`, `sort_order=0`)를 만든다. 가능 시간이 짧아 `reviewMinutes = 0`이면(예: 5분, `06` §5.6) 만들지 않고 `reviewTask = null`이다. 일일 복습 상한은 20장(복귀 모드 10장).
- 이유는 `ReasonTemplates` 규칙으로 **최소 1개, 최대 3개**다(`06` §5.8, AC-02). 문구는 템플릿 그대로다.
- `score_breakdown`은 저장하지만 MVP 화면에는 표시하지 않는다.
- 재생성은 `06` §5.9 표를 따른다: main `IN_PROGRESS`에서 `force=false`면 `409 TODAY_ALREADY_STARTED`, main `COMPLETED`에서 `force=false`면 `409 TODAY_ALREADY_COMPLETED`.
- task 상태 전이는 `04` §4.1이다. 표에 없는 전이는 `409 INVALID_STATE_TRANSITION`.
- 오늘 plan이 없으면 `GET /today`는 `404 TODAY_NOT_GENERATED`이고 클라이언트는 입력 화면을 보여준다.
- 활성 plan이 없으면 `POST /today/generate`는 `404 PLAN_NOT_FOUND`다.
- 후보 skill이 하나도 없으면(모든 목표 달성 등) main task를 만들지 않는다. due 복습이 있으면 REVIEW task만 만들고 `mainTask`는 `null`이다(`06` §5.2). 화면은 계획 조정을 안내한다.
- `aiStatus=DISABLED`이면 planner는 `CHALLENGE` task를 제안하지 않는다(평가가 AI에 의존, `06` §5.3).
- task 상태와 학습 세션(FR-08)은 별개 리소스다. 클라이언트가 둘 다 갱신한다(`02` §4.2).

**관련 API** — `POST /today/generate`, `GET /today`, `PATCH /today/tasks/{taskId}`
**관련 화면** — SCR-TODAY
**AC** — AC-02, AC-17 · **Sprint** — S2 · **우선순위** — MUST

### FR-08 학습 세션 기록

**설명** — 사용자가 과제를 시작·완료·중단한 시각과 실제 학습 시간, 짧은 회고를 기록한다. 완료율(budget)과 지표의 원천이다.

**사용자 스토리** — As a 사용자, I want 실제로 공부한 시간을 간단히 남기고 싶다, so that 계획이 내 실제 속도에 맞춰진다.

**규칙**
- 사용자당 `IN_PROGRESS` 세션은 1개다(I-05). 새 세션을 시작하면 서버가 기존 세션을 `ABANDONED`로 닫는다. main task "시작" 시 클라이언트는 진행 중 세션의 `learningTaskId`가 이 task와 다르면(세션이 없는 경우 포함) 새 세션을 시작한다(서버가 기존 세션을 닫는다, `02` §4.2). 복습 세션은 진행 중 세션이 있으면 새로 시작하지 않는다(`02` §4.3).
- 시작: `learningTaskId`(선택). `plan_date`는 시작 시각의 plan-day다.
- 완료: `actualMinutes` 0~720이면서 `⌈경과 분 × 1.5⌉` 이하(필수, `05-api-spec.md` §9.2), `selfReflection`(선택, ≤ 5000자). 완료한 세션은 수정하지 않는다.
- 이벤트: `SESSION_STARTED`, `SESSION_COMPLETED`(`04` §6). task의 skill이 있으면 `skill_id`를 채운다.
- 완료율은 COMPLETED 세션의 `actual_minutes`만 합산한다(`06` §3.3).
- 목록은 `from`/`to`(plan date)와 cursor로 조회한다.

**관련 API** — `POST /learning-sessions`, `POST /learning-sessions/{sessionId}/complete`, `POST /learning-sessions/{sessionId}/abandon`, `GET /learning-sessions?from=&to=&cursor=`
**관련 화면** — SCR-TODAY(완료 시트), SCR-REVIEW-SESSION, SCR-TRAINING-ATTEMPT, SCR-DASHBOARD
**AC** — AC-02 · **Sprint** — S2 · **우선순위** — MUST

### FR-09 Training challenge (생성, attempt, 제출, 비동기 평가)

**설명** — skill별 난이도 문제(seed 또는 AI 생성)를 풀면서 먼저 접근을 설명하고, 답안·코드를 제출하면 AI가 rubric 충족 여부를 비동기로 판정하고 서버가 coverage와 outcome을 계산한다.

**사용자 스토리** — As a 사용자, I want 실무형 문제를 스스로 먼저 풀어 보고 무엇이 빠졌는지 확인하고 싶다, so that 문법 암기가 아니라 적용·판단 능력이 는다.

**규칙**
- 난이도 1~5 의미: L1 기본 사용, L2 작은 변형, L3 여러 개념 조합, L4 실무형 시나리오, L5 트레이드오프·디버깅·설계.
- 목록(`GET /challenges`)은 `VALIDATED`이고 seed 공용이거나 본인 소유인 문제만 반환한다. `purpose`로 `PRACTICE`/`DIAGNOSTIC`을 거른다.
- 생성(`POST /challenges/generate`: `skillId`(UUID), `difficulty` 1~5, `targetMinutes` 5~180)은 `202`, `CHALLENGE_GENERATE` 비동기다. 실패·거절 시 재시도 API 없이 새로 요청한다. 결과는 `ChallengeValidationService`의 결정적 검증(I-09, rubric weight 합 10000 — I-10)을 통과하면 `VALIDATED`, 아니면 `REJECTED`다. 1~3단계 hint를 함께 생성해 저장한다.
- attempt 시작은 `VALIDATED` challenge에서만 가능하다(`04` §4.2). 같은 challenge에 `STARTED`/`SUBMITTED` attempt가 있으면 `409 INVALID_STATE_TRANSITION`이고, 클라이언트는 `GET /challenges/{challengeId}`의 `activeAttemptId`(STARTED/SUBMITTED/EVALUATED 최신 1개)로 기존 attempt를 연다. `activeAttemptId`가 null이거나 그 attempt가 `EVALUATED`일 때만 새로 시작할 수 있다.
- **제출 전에 self-explanation(텍스트 1~5000자) 또는 명시적 건너뛰기**가 있어야 한다. 없으면 `409 SELF_EXPLANATION_REQUIRED`. 한 번 기록하면 바꾸지 않는다. 이벤트 `SELF_EXPLANATION_SUBMITTED`/`SKIPPED`.
- 제출: `answerText`(≤ 5000자)와 `code`(UTF-8 20000 bytes 이하) 중 하나 이상, `language`(`CodeLanguage`, code가 있으면 필수). `202`를 반환하고 `CHALLENGE_EVALUATE`를 비동기로 실행한다.
- attempt당 제출은 최대 5회(`devpilot.training.max-submissions-per-attempt`). 초과는 `409 SUBMISSION_LIMIT_REACHED`. 평가 중(PENDING/RUNNING) 제출이 있으면 새 제출은 `409 EVALUATION_IN_PROGRESS`, 최신 제출이 평가 실패(`FAILED`)면 `409 INVALID_STATE_TRANSITION`이다(재평가만 가능).
- 평가 실패(`FAILED`)한 제출만 `POST …/submissions/{submissionNo}/retry`로 재평가한다. 그 외는 `409 AI_TASK_NOT_RETRYABLE`.
- coverage, evaluatedOutcome, attempt outcome은 서버가 계산한다(`06` §8.1~8.2). AI는 rubric `met`, `evidenceQuote`, `misconceptions`, `followUpQuestion`만 낸다(`04` §5.3).
- `GET /challenges/{challengeId}`는 본인 attempt 평가 완료 전에는 `rubric`, `expectedConcepts`를 제외한다.
- 평가 완료 후 outcome이 `FAILED`/`PARTIAL`이거나 `SOLVED_WITH_HINTS`이면서 maxHintLevel ≥ `PSEUDOCODE`면 skill마다 review item을 upsert한다(`06` §8.3). due는 다음 plan-day(`06` §6.3). attempt 응답의 `reviewScheduled`로 화면에 알린다.
- 포기(`POST …/abandon`)는 `04` §4.2 규칙을 따른다.
- **MVP는 코드를 실행하지 않는다**(NG-7). 평가는 AI rubric 판정뿐이다.
- AI 불가·차단이면 문제 보기, self-explanation, 사전 생성 hint(1~3단계)는 동작하고 제출·재평가·AI 생성은 `503 AI_UNAVAILABLE`/`429 AI_*`로 거절된다(AC-12). **자기 채점 같은 대체 평가 경로는 없다.** 클라이언트는 `aiStatus=DISABLED`면 제출 버튼을 미리 막는다.

**관련 API** — `GET /challenges?skillId=&purpose=&cursor=`, `POST /challenges/generate`, `GET /challenges/{challengeId}`, `POST /challenges/{challengeId}/attempts`, `GET /challenge-attempts/{attemptId}`, `POST /challenge-attempts/{attemptId}/self-explanation`, `POST /challenge-attempts/{attemptId}/submissions`, `POST /challenge-attempts/{attemptId}/submissions/{submissionNo}/retry`, `POST /challenge-attempts/{attemptId}/abandon`
**관련 화면** — SCR-TRAINING-LIST, SCR-CHALLENGE-DETAIL, SCR-TRAINING-ATTEMPT
**AC** — AC-04 · **Sprint** — S3 · **우선순위** — MUST

### FR-10 Hint Ladder

**설명** — 사용자가 요청할 때만 도움을 7단계(`SELF_EXPLAIN` 0 ~ `FULL_EXAMPLE` 6)로 늘린다. 공개한 최대 단계는 outcome, 복습 등급, skill 규칙에 반영된다.

**사용자 스토리** — As a 막힌 사용자, I want 답 전체가 아니라 다음 한 걸음만 힌트로 받고 싶다, so that 최대한 스스로 해결한 경험을 남긴다.

**규칙**
- 서버 정책은 `06` §9.1 HL-1~HL-8이 전부다. 요약:
  - HL-1 이미 공개한 단계 이하 요청은 AI 호출 없이 저장된 내용 반환
  - HL-2 challenge는 self-explanation(또는 skip), coach finding은 응답 또는 `skipSelfExplanation=true`가 선행 → 없으면 `409 SELF_EXPLANATION_REQUIRED`
  - HL-3 여러 단계를 한 번에 올릴 수 있고 건너뛴 단계는 기록
  - HL-4 `PSEUDOCODE` 이상은 `acknowledgeEvidenceImpact=true` 필요 → 없으면 `409 HINT_CONFIRMATION_REQUIRED`
  - HL-5 `FULL_EXAMPLE`은 challenge 제출 1회 이상 또는 `giveUp=true` → 아니면 `409 FULL_EXAMPLE_NOT_ALLOWED`
  - HL-6 challenge 1~3단계는 사전 생성 내용, 4단계 이상과 coach finding 전 단계는 `HINT_GENERATE`(동기, 20초)
  - HL-7 공개마다 `hint_disclosure` + `HINT_DISCLOSED` + `max_hint_level` 갱신
  - HL-8 `DIRECTION` 이하 AI hint에 코드가 있으면 가드가 거절
- **클라이언트는 다음 단계(현재 max + 1) 버튼만 활성화한다.** 서버는 건너뛰기를 허용하지만 UI는 제공하지 않는다(결정 비용 감소, `02` §6.2).
- `PSEUDOCODE` 이상은 확인 대화상자에서 영향("힌트로 해결로 기록, 복습 카드 생성 가능")을 보여준 뒤 요청한다.
- 영향: challenge outcome은 maxHintLevel ≤ `QUESTION_ONLY`일 때만 `SOLVED_INDEPENDENTLY`(`06` §8.2). 복습 등급 상한(`06` §6.1).
- 복습(review item)의 hint는 AI 없이 클라이언트가 처리한다: rubric 첫 항목 공개 = `CONCEPT_HINT`, 답하기 전 정답 보기 = `FULL_EXAMPLE`(`06` §6.1). 별도 API가 없다.
- 공개된 hint 내용은 attempt/finding 조회 응답에 포함되어 다시 볼 수 있다.

**관련 API** — `POST /challenge-attempts/{attemptId}/hints`, `POST /coach/reviews/{reviewId}/findings/{findingId}/hints`, `GET /challenge-attempts/{attemptId}`, `GET /coach/reviews/{reviewId}`
**관련 화면** — SCR-TRAINING-ATTEMPT, SCR-COACH-DETAIL, SCR-REVIEW-SESSION
**AC** — AC-16 · **Sprint** — S3(challenge), S4(coach finding) · **우선순위** — MUST

### FR-11 Memory review (due, 답변, 스케줄, 수동 카드, variant)

**설명** — seed·수동·challenge·coach에서 온 복습 카드를 plan-day마다 상한 안에서 출제하고, 답변·자기평가·hint·(선택) AI 채점으로 최종 등급과 다음 due를 정한다.

**사용자 스토리** — As a 출퇴근 중인 사용자, I want 휴대폰으로 5분 동안 카드 몇 장을 떠올려 답하고 싶다, so that 배운 내용을 잊기 전에 다시 꺼낸다.

**규칙**
- due 선택·정렬·상한은 `06` §6.5다. 상한 20장, 복귀 모드 10장.
- `GET /reviews/due`(`limit` 생략 = cap) 응답은 `cap`, `comebackMode`, `totalDueCount`와 카드별 `prompt`, `expectedAnswer`, `rubric`, `wasVariant`, `overdueDays`를 준다. **클라이언트가 답 확인 전까지 숨긴다.** reveal API는 없다.
- `variant_status=READY`면 variant 문항이 출제된다(`wasVariant=true`).
- 답변(`POST /reviews/{reviewItemId}/answer`, 동기): `answerText`(선택, ≤ 5000자. 비어 있으면 클라이언트는 `evaluate=false`로 보낸다 — 서버는 공백 답변 + `evaluate=true`를 AI 호출 없이 `NOT_EVALUATED`로 처리), `selfRating`(`AGAIN|HARD|GOOD|EASY`), `hintLevel`(`SELF_EXPLAIN|CONCEPT_HINT|FULL_EXAMPLE` 중 하나), `responseSeconds`(0~86400), `wasVariant`(due 응답 값 그대로), `evaluate`(S3부터, 기본 false).
- 답변 응답: `finalRating`, `adjustedBy`, `evaluatedOutcome`, `rubricResults`(평가 성공 시), `intervalBefore`/`intervalAfter`, `nextDueDate`, `evaluationSkippedReason`, `status`, `leechDetected`.
- 아직 due가 아니거나 `ACTIVE`가 아닌 카드에 답하면 `409 INVALID_STATE_TRANSITION`, `wasVariant`가 현재 variant 상태와 다르면 `409 CONCURRENT_MODIFICATION`이다(`05-api-spec.md` §11.3).
- 최종 등급은 `06` §6.1, 간격·due는 `06` §6.2(1~60일, horizon cap). 응답의 `adjustedBy`를 화면에 사유로 보여준다.
- `evaluate=true`면 `REVIEW_EVALUATE`(동기, 20초, 재시도 0)를 호출한다. **실패해도 답변은 `NOT_EVALUATED`로 저장**하고 `evaluationSkippedReason`을 준다(`03` §5.3). `answerText`가 비어 있으면 evaluate를 보내지 않는다.
- leech: 연속 실패 4회면 `SUSPENDED` + `LEECH_DETECTED`. 연속 실패 2회 이상이고 AI 사용 가능하면 variant를 비동기 생성한다(`06` §6.4).
- 수동 카드(`POST /review-items`): `skillCode`(필수), `conceptKey`(필수, `^[A-Z0-9_.:-]{3,150}$` — 클라이언트가 `MANUAL:{대문자 UUID v4}`로 만든다), `reviewType`(화면은 `RECALL|EXPLAIN|BUG_SPOT`만 제공), `prompt`(1~2000자), `expectedAnswer`(1~3000자), `rubric`(1~6개, 각 1~500자 — 첫 항목이 복습 힌트). 새로 만들면 `201`, 첫 due는 다음 plan-day(`06` §6.3). `CHOICE`는 보기 필드가 없어 수동 생성 화면에서 제외한다.
- 사용자·개념당 카드 1개(I-06). 같은 `concept_key`가 이미 있으면 새로 만들지 않고 기존 카드를 활성화해 `200`으로 반환한다(문항은 덮어쓰지 않음, `06` §6.3).
- 카드 관리(`PATCH /review-items/{reviewItemId}`): `status`(`ACTIVE`/`SUSPENDED`/`ARCHIVED`, 전이 `04` §4.5), `prompt`(1~2000자), `expectedAnswer`(1~3000자), `version`. rubric은 바꾸지 않고, `ARCHIVED` 카드의 문항은 수정할 수 없다.
- 모든 답변은 `review_answer`에 append-only로 남고 `REVIEW_ANSWERED` 이벤트를 발행한다.

**관련 API** — `GET /reviews/due?limit=`, `POST /reviews/{reviewItemId}/answer`, `GET /review-items?skillId=&status=&cursor=`, `POST /review-items`, `PATCH /review-items/{reviewItemId}`
**관련 화면** — SCR-REVIEW-HOME, SCR-REVIEW-SESSION, SCR-REVIEW-ITEMS, SCR-REVIEW-ITEM-EDIT, SCR-TODAY
**AC** — AC-05, AC-10 · **Sprint** — S2(due, 답변, 스케줄, 수동 카드), S3(evaluate, variant) · **우선순위** — MUST

### FR-12 Project Coach (self-review, 분석, 응답 피드백, hint, close)

**설명** — 사용자가 개인 프로젝트 코드·diff·로그를 붙여넣고 **먼저 스스로 우려점을 적은 뒤** 분석을 요청한다. AI는 수정 코드 대신 finding별 학습 질문을 낸다. 사용자는 질문에 답하고, 필요하면 hint를 받고, 각 finding을 수정 완료/해당 없음으로 정리한 뒤 리뷰를 닫는다.

**사용자 스토리** — As a 사이드 프로젝트를 만드는 사용자, I want 내 코드의 위험을 AI가 알려주기 전에 내가 먼저 찾아보고 질문으로 확인받고 싶다, so that 다음 코드에서는 스스로 문제를 인지한다.

**규칙**
- 입력: `contentType`(`CODE|DIFF|LOG`), `language`(`CodeLanguage`, 선택), `content`(≤ 30000 bytes UTF-8, ≤ 1000줄 — `03` §9), `confidentialConsent=true`(필수), `userSelfReview`(선택, ≤ 5000자), `context`(필수: `projectType` 필수, `topic` ≤ 100자, `skillCodes` ≤ 10, `fileName` ≤ 200자 — `04` §5.5, `05-api-spec.md` §12.1). `selfReviewAxes`는 분석 시 서버가 채운다.
- 순서(`03` §5.3): 크기·동의 검증(400/413) → **secret masking**(`content`와 `userSelfReview` 모두. private key 블록이면 `422 SECRET_DETECTED_BLOCKED`, 저장·AI 호출 없음) → 예산 확인(429) → 마스킹본 저장(`PENDING`) → `202 { id, status, maskedSecretCount }` → 비동기 `COACH_REVIEW`.
- self-review는 분석 **요청과 함께** 저장한다. 분석 결과를 본 뒤에는 self-review를 수정할 수 없다(H-04). 비어 있으면 어떤 finding도 `MENTIONED_UNPROMPTED`가 될 수 없다는 점을 제출 전에 알린다.
- finding은 최대 7개(`devpilot.coach.max-findings`)이고 `type`(`BUG|RISK|LEARNING_POINT`), `category`(`ThinkingAxis`), `summary`, `learningQuestion`, 위치(줄 범위), `verificationStatus`, `confidence`, `sourceType`, `sourceReference`, `mentionedByUser`를 가진다. **수정 코드 필드는 없다**(AC-06).
- 클라이언트는 `GET /coach/reviews/{reviewId}`를 2초 간격, 최대 3분 polling한다(`03` §5.3). `RUNNING`이 10분 넘게 멈추면 서버가 `FAILED(INTERRUPTED)`로 정리한다.
- 실패한 리뷰만 `POST …/retry`(202)로 다시 분석한다(`retryable=true`). `failureCode=CONFIDENTIAL_SUSPECTED`이거나 원문이 삭제된 리뷰는 재시도할 수 없고 새 요청을 안내한다.
- finding 응답(`POST …/responses`, 텍스트 1~5000자, 마스킹 적용·private key면 422)은 응답을 먼저 저장한 뒤 동기 `COACH_RESPONSE_FEEDBACK`을 호출해 `aiFeedback`, `userIdentifiedIssue`, `followUpQuestion`을 저장·반환한다(`CoachFindingView.followUpQuestion`, `feedbackAiMeta`로 언제든 다시 조회). **AI 실패·차단 시 응답만 저장**하고 `feedbackSkippedReason`을 반환한다(HTTP 오류 없음). 한 번 `userIdentifiedIssue=true`가 되면 유지된다. finding 상태는 `USER_RESPONDED`(재응답은 최신으로 덮어씀, `04` §4.3).
- hint는 FR-10(coach finding 전 단계 AI). 원문이 삭제된 뒤에는 새 단계를 생성할 수 없다(이미 공개한 단계는 볼 수 있다).
- `PATCH …/findings/{findingId}`로 `RESOLVED`(수정 완료) 또는 `DISMISSED`(해당 없음 = 오탐 신호)로 바꾼다. 되돌리지 않는다.
- `POST …/complete`로 리뷰를 닫는다. 이때 finding마다 `discoveredBy`를 확정하고(`06` §9.3) `COACH_FINDING_CLOSED`, thinking pattern observation, `COACH_REVIEW_COMPLETED`를 기록한다. OPEN finding이 남아 있어도 닫을 수 있다. `findingType ∈ {BUG, RISK}`, skill 있음, `discoveredBy ∈ {MISSED, FOUND_AFTER_HINT}`인 finding은 복습 카드가 된다(`06` §9.4, due 다음 plan-day). 응답은 `CoachReviewCompleteResponse{review, createdReviewItemCount, updatedReviewItemCount}`다.
- 닫힌 리뷰의 finding 응답·hint·상태 변경은 `409 REVIEW_ALREADY_CLOSED`다.
- 원문(`content`)은 30일 후 자동 purge(DEC-16, `04` §8), `DELETE /coach/reviews/{reviewId}/content`로 즉시 삭제한다(분석 중에는 불가). finding은 남는다.
- AI 불가·예산 초과면 분석 요청을 받지 않는다(`503 AI_UNAVAILABLE` / `429`). 기존 리뷰 조회·상태 변경·close는 동작한다.

**관련 API** — `POST /coach/reviews`, `GET /coach/reviews/{reviewId}`, `GET /coach/reviews?cursor=`, `POST /coach/reviews/{reviewId}/retry`, `POST /coach/reviews/{reviewId}/findings/{findingId}/responses`, `POST /coach/reviews/{reviewId}/findings/{findingId}/hints`, `PATCH /coach/reviews/{reviewId}/findings/{findingId}`, `POST /coach/reviews/{reviewId}/complete`, `DELETE /coach/reviews/{reviewId}/content`
**관련 화면** — SCR-COACH-LIST, SCR-COACH-NEW, SCR-COACH-DETAIL
**AC** — AC-06, AC-14, AC-19 · **Sprint** — S4 · **우선순위** — MUST

### FR-13 Thinking pattern 추적

**설명** — coach 리뷰에서 사용자가 각 관점(10개 `ThinkingAxis`)을 스스로 언급했는지, 질문·hint 후에 찾았는지, 놓쳤는지를 누적해 약한 축을 보여주고 코칭 맥락에 쓴다.

**사용자 스토리** — As a 사용자, I want 내가 자주 놓치는 관점(예: 자원 수명, 동시성)을 알고 싶다, so that 코드를 볼 때 그 관점을 의식적으로 확인한다.

**규칙**
- 축: `CORRECTNESS`, `NULL_BOUNDARY`, `RESOURCE_LIFECYCLE`, `EXCEPTION_STRATEGY`, `SECURITY`, `PERFORMANCE`, `CONCURRENCY`, `OBSERVABILITY`, `MAINTAINABILITY`, `TRANSACTION_DATA_CONSISTENCY` (10개).
- observation 기록 시점: 리뷰 close 시 finding마다 `discoveredBy`(`06` §9.3), 분석 완료 시 `incorrectClaims[]`마다 `INCORRECT_CLAIM`.
- MVP의 observation source는 `COACH_REVIEW`뿐이다. `CHALLENGE_ATTEMPT` source는 기록 규칙이 정의될 때까지 쓰지 않는다.
- `mentionedByUser`는 AI 분류다. 화면에 "AI 분류" 표시와 함께 보여준다. MVP에 이의 제기 API는 없다.
- 약한 축 `weakThinkingAxes`는 `06` §12(MISSED 비율 상위 3개, observation 3개 이상인 축만).
- 추세: `GET /thinking-patterns/trend?weeks=8`(주별·축별 observation 수).
- 사용처: coach 분석 컨텍스트(`03` §5.3), `D_DOWN_REPEATED_MISS` 하락 규칙(`06` §7.3), Dashboard·Weekly.

**관련 API** — `GET /thinking-patterns/trend?weeks=8`, `GET /dashboard`, `GET /weekly-reviews/{weekStartDate}`
**관련 화면** — SCR-COACH-DETAIL, SCR-DASHBOARD, SCR-WEEKLY-DETAIL
**AC** — AC-19 · **Sprint** — S4(기록), S5(추세·표시) · **우선순위** — MUST

### FR-14 Verification 표시와 가드

**설명** — AI가 낸 지적마다 근거 수준(`VerificationStatus`)과 확신도(`Confidence`)를 저장·표시하고, 서버가 근거 없는 높은 등급을 강등한다.

**사용자 스토리** — As a 사용자, I want AI 지적이 공식 문서 근거인지 AI 판단인지 구분해서 보고 싶다, so that AI 말을 그대로 믿지 않고 확인할 부분을 안다.

**규칙**
- 등급: `VERIFIED`(서버 도구 결과 또는 curated source), `SUPPORTED`(allowlist 공식 문서·보안 가이드), `AI_JUDGMENT`, `UNCERTAIN`. 정의와 강등 순서는 `06` §10.
- MVP에는 서버 도구 실행이 없으므로 `VERIFIED`는 `content/curated-sources.yaml`에 등록된 근거일 때만 가능하다.
- **서버는 `sourceReference` URL을 fetch하지 않는다.** 호스트 문자열만 allowlist와 비교한다.
- DB CHECK로 이중 방어한다(I-07, I-08).
- 화면: finding 카드에 verification 배지와 confidence 배지를 **항상** 텍스트로 표시한다(색만으로 구분 금지, NFR-08). `sourceType`이 `OFFICIAL_DOC`/`SECURITY_GUIDE`이고 https URL이면 외부 링크로 연다. 그 외 `sourceReference`는 일반 텍스트다.
- 가드 동작은 `ai_call_log.guard_actions`에 남는다(`04` §5.6). 사용자 화면에는 표시하지 않는다.

**관련 API** — `GET /coach/reviews/{reviewId}`
**관련 화면** — SCR-COACH-DETAIL
**AC** — AC-07 · **Sprint** — S3(guard), S4(finding 표시) · **우선순위** — MUST

### FR-15 진단 challenge

**설명** — 온보딩에서 자기평가 3 이상으로 답한 카테고리마다 짧은 진단 문제를 선택형으로 제안한다. 통과하면 evidence level을 올려 경력자가 기초 과제만 반복하지 않게 한다.

**사용자 스토리** — As a 경력 전환자, I want 이미 아는 영역은 짧은 문제로 증명하고 넘어가고 싶다, so that planner가 내 수준에 맞는 과제를 준다.

**규칙**
- `GET /diagnostics/suggestions`: 자기평가가 활성이고 값이 3 이상인 카테고리마다 `purpose=DIAGNOSTIC`인 seed `VALIDATED` challenge 1개를 제안한다(선택 규칙 `05-api-spec.md` §4.2). 진단 attempt를 한 번이라도 시작한 카테고리(상태 무관)는 제외한다.
- 진단은 **건너뛸 수 있다**. 건너뛰기는 서버에 저장하지 않고 클라이언트가 기기에 기억한다(`02` §3.5 SCR-DIAGNOSTICS).
- 풀이 흐름은 FR-09와 같다(self-explanation → 제출 → 비동기 평가).
- 판정(`06` §7.4): `evaluatedOutcome=CORRECT`이고 maxHintLevel ≤ `QUESTION_ONLY`면 `DIAGNOSTIC_PASSED` → KNOWLEDGE, IMPLEMENTATION = `max(현재, min(claimedLevel, 3))` (cooldown·1단계 제한 없음). 그 외 평가 완료는 `DIAGNOSTIC_FAILED` → 레벨 유지, `self_assessment_active=false`.
- `claimedLevel`은 평가 시점 해당 skill의 `self_assessed_level`이다.
- 진단 challenge는 planner의 task 제안에 쓰지 않는다(`06` §5.3은 `PRACTICE`만).

**관련 API** — `GET /diagnostics/suggestions`, `POST /challenges/{challengeId}/attempts`, FR-09 attempt API
**관련 화면** — SCR-TODAY(제안 카드), SCR-DIAGNOSTICS, SCR-TRAINING-ATTEMPT
**AC** — AC-11 · **Sprint** — S3 · **우선순위** — SHOULD

### FR-16 Dashboard

**설명** — 오늘 상태, 이번 주 학습, 계획 위험, skill·thinking 약점을 한 화면에 읽기 전용으로 모은다.

**사용자 스토리** — As a 사용자, I want 이번 주에 얼마나 했고 기한 대비 어디쯤인지 한눈에 보고 싶다, so that 다음 주 계획을 조정할지 판단한다.

**규칙**
- `GET /dashboard` 하나로 집계한다(읽기 전용, AI 없음, p95 < 1000ms).
- S2 최소 구성(`05-api-spec.md` §13.1): 오늘 요약(main task 제목·유형·상태·예상 시간, 복습 task 상태), 오늘 due 복습 수, 이번 ISO week(월요일~오늘) 완료 세션 수·학습 시간, `aiStatus`, `replanRecommended`.
- S5 완성 구성: 위 항목 + 최근 snapshot 8개의 risk 추세, milestone 타임라인과 오늘 위치·horizon, 카테고리별 평균 planning 레벨 대비 평균 목표 레벨, 최근 28 plan-day `weakThinkingAxes`.
- 학습 방식 지표(`independentSolveRateBp`, `averageHintLevelMilli`, `recallSuccessRateBp`, `selfFoundRiskCount`)는 Dashboard가 아니라 weekly review(FR-17)에서 보여준다.
- **연속 학습일(streak), 학습하지 않은 날 수, 사용자 간 비교를 표시하지 않는다**(NG-11).
- 지표 값이 null(분모 0)이면 "기록이 더 필요해요"로 표시한다.

**관련 API** — `GET /dashboard`
**관련 화면** — SCR-DASHBOARD
**AC** — AC-02 · **Sprint** — S2(최소), S5(완성) · **우선순위** — MUST

### FR-17 Weekly review·지표

**설명** — 매주 월요일 plan-day 시작 시 지난주 지표를 스냅샷으로 만들고, 사용자는 짧은 회고를 남긴다.

**사용자 스토리** — As a 사용자, I want 한 주를 숫자와 내 말로 돌아보고 싶다, so that 다음 주에 무엇을 바꿀지 정한다.

**규칙**
- `WeeklyReviewJob`이 사용자 로컬 월요일 `dayStartHour`에 지난 ISO week(월~일, plan-day 기준)의 지표를 계산해 `weekly_review`를 만든다(`03` §6). 이미 있으면 다시 만들지 않는다.
- 지표 필드는 `04` §5.7, 계산식은 `06` §12다. 생성 후 `metrics_json`은 바뀌지 않는다.
- 회고(`PUT /weekly-reviews/{weekStartDate}/reflection`): `reflection` 0~5000자, `version` 필수.
- 목록은 최신 주부터 cursor. 첫 주는 온보딩 다음 월요일에 생긴다.
- AI를 쓰지 않는다. 회고 문구 제안도 하지 않는다.
- thinking pattern 추세(최근 8주)를 같은 화면에 보여준다.

**관련 API** — `GET /weekly-reviews?cursor=`, `GET /weekly-reviews/{weekStartDate}`, `PUT /weekly-reviews/{weekStartDate}/reflection`, `GET /thinking-patterns/trend?weeks=8`
**관련 화면** — SCR-WEEKLY-LIST, SCR-WEEKLY-DETAIL, SCR-DASHBOARD
**AC** — AC-21 · **Sprint** — S5 · **우선순위** — SHOULD

### FR-18 Evidence (후보, AI 초안, 승인, STAR export)

**설명** — 실제로 해결한 학습·코드 기록을 이력서·면접용 증거로 만든다. 사용자가 직접 쓰거나 learning event에서 AI 초안을 받고, 수정 후 승인한 것만 export한다.

**사용자 스토리** — As a 지원을 앞둔 사용자, I want 공부하며 해결한 문제를 STAR 형식으로 정리해 두고 싶다, so that 이력서와 면접에서 구체적인 사례로 말한다.

**규칙**
- 상태: `CANDIDATE → ACCEPTED | REJECTED`, `REJECTED → CANDIDATE`(복원). `ACCEPTED`는 되돌리지 않고 수정만 허용한다(`04` §4.7). 복원은 `PATCH /evidence/{evidenceId}`의 `status=CANDIDATE`다.
- 수동 작성(`POST /evidence`): `title` 1~200자, `problem`/`analysis`/`action`/`result` 각 0~3000자, `skillCode`(선택), `referenceLinks` 0~10개(https, 각 ≤ 500자), `interviewTopics` 0~10개(각 1~200자).
- AI 초안(`POST /evidence/drafts`, `sourceLearningEventId`): `202`, `EVIDENCE_DRAFT` 비동기. 결과는 `ai_draft_json`에 원본으로 두고 편집 필드에 복사한다. 사용자가 편집해도 AI 원본은 바뀌지 않는다(`04` §5.8).
- 초안 source는 본인의 무효화되지 않은 learning event면 된다(`05-api-spec.md` §14.5). 화면은 skill 레벨 변경 이력의 근거 이벤트 중 `CHALLENGE_EVALUATED`, `COACH_FINDING_CLOSED`, `COACH_REVIEW_COMPLETED`에만 초안 버튼을 둔다(`02` §3.10 SCR-SKILL-DETAIL). 문제 풀이·코드 리뷰 결과 화면의 "증거로 남기기"는 `AttemptView.evidenceSourceEventId` / `CoachReviewView.evidenceSourceEventId`가 있으면 그 값으로 초안을 요청하고, null이거나 AI 불가일 때만 제목·기술을 채운 수동 작성으로 연결한다. 초안 생성 실패는 재시도 API 없이 새로 요청한다.
- 편집은 `PATCH /evidence/{evidenceId}`(+`version`). 초안 생성 중에는 편집·승인·거절이 `409 INVALID_STATE_TRANSITION`이다.
- 승인(`POST …/accept`)은 `title`과 `problem`, `action`, `result`가 비어 있지 않아야 한다. 승인 시 `EVIDENCE_ACCEPTED` 이벤트 → skill `evidence_count`, `I4_PRODUCTION_LIKE` 규칙 입력(`06` §7.2).
- export(`GET /evidence/export?format=markdown`)는 `ACCEPTED`만 STAR Markdown(제목, 상황·문제, 분석, 행동, 결과, 관련 skill, 링크, 면접 주제)으로 반환한다.
- 외부 서비스(이력서 사이트 등)로 자동 게시하지 않는다.

**관련 API** — `GET /evidence?status=&cursor=`, `GET /evidence/{evidenceId}`, `POST /evidence`, `POST /evidence/drafts`, `PATCH /evidence/{evidenceId}`, `POST /evidence/{evidenceId}/accept`, `POST /evidence/{evidenceId}/reject`, `GET /evidence/export?format=markdown`
**관련 화면** — SCR-EVIDENCE-LIST, SCR-EVIDENCE-DETAIL, SCR-TRAINING-ATTEMPT(초안 진입), SCR-COACH-DETAIL(초안 진입)
**AC** — AC-21 · **Sprint** — S6 · **우선순위** — SHOULD

### FR-19 Job Radar (JD 붙여넣기 분석, 확률·점수 없음)

**설명** — 사용자가 채용 공고 본문을 붙여넣으면 AI가 요구사항을 추출하고, 서버가 catalog skill과 현재 skill state·accepted evidence로 요구사항별 준비 상태를 분류한다.

**사용자 스토리** — As a 지원 중인 사용자, I want 공고의 요구사항 중 무엇이 준비됐고 무엇을 보완해야 하는지 알고 싶다, so that 남은 시간에 공부할 것을 고른다.

**규칙**
- 입력: `title` 1~200자(필수), `company` ≤ 200자, `sourceUrl` ≤ 2000자(http/https URL, 선택), `jobDescription`(필수, UTF-8 20000 bytes 이하 — 초과 시 `413 CONTENT_TOO_LARGE`).
- **서버는 `sourceUrl`을 fetch하지 않는다.** 기록용 링크일 뿐이다(NG-8, AC-22). 자동 수집·크롤링은 없다.
- `POST /jobs`는 `202`, `JOB_EXTRACT` 비동기다. 요구사항마다 `rawText`, `requirementType`(`REQUIRED|PREFERRED`), catalog에 있는 `skillCode`(없으면 null)를 저장한다.
- `fitCategory`(`READY|STRETCH|LATER`)와 연결 evidence는 **서버의 `JobFitClassifier`가 evidence level로 계산**한다(`06` §13). AI가 정하지 않는다. skill이 매칭되지 않은 요구사항은 `fitCategory=null`("분류 불가")이다. 분류는 분석 시점에 고정된다.
- **응답과 화면 어디에도 합격 확률, 점수, 퍼센트, 순위가 없다**(NG-6). 화면은 분류별 개수와 목록만 보여준다.
- JD 본문은 180일 후 purge(`04` §8). 요구사항 분석 결과는 남는다. `DELETE /jobs/{jobId}`로 전체 삭제한다.

**관련 API** — `POST /jobs`, `GET /jobs/{jobId}`, `GET /jobs?cursor=`, `DELETE /jobs/{jobId}`
**관련 화면** — SCR-JOBS-LIST, SCR-JOB-NEW, SCR-JOB-DETAIL
**AC** — AC-22 · **Sprint** — S7 · **우선순위** — SHOULD

### FR-20 캘린더 구독 (ICS)

**설명** — 사용자의 캘린더 앱이 구독할 비밀 URL을 발급해 매일 학습 일정을 캘린더에 표시한다. 푸시 인프라 없이 캘린더 알림으로 학습 시작을 돕는다.

**사용자 스토리** — As a 퇴근 후 공부를 자주 잊는 사용자, I want 내 캘린더에 오늘의 학습이 떠 있기를 원한다, so that 캘린더 알림을 보고 앱을 연다.

**규칙**
- `POST /me/calendar-token`은 256bit 랜덤 토큰을 새로 만들고 `SHA-256` 해시만 저장한다. 이전 토큰은 즉시 무효다. **구독 URL(`feedUrl`)은 이 응답에서만 한 번 준다.** 같은 `Idempotency-Key`의 재생 응답은 `feedUrl=null`이므로(`03` §5.4) 화면은 새 링크를 다시 만들라고 안내한다.
- 구독 여부는 `GET /me`의 `calendarSubscribed`로 표시한다.
- `GET /calendar/{token}.ics`는 Bearer 인증 없이 토큰 해시로 조회한다. 일치하지 않으면 404. 로그에서 토큰 경로는 마스킹한다(`03` §5.5). 토큰당 시간당 60회를 넘으면 `429 RATE_LIMITED`다.
- 피드 내용(`05-api-spec.md` §3.6): 오늘 plan-day부터 7 plan-day의 **종일(all-day) 일정** 1개씩.
  - 오늘, main task 있음: `오늘의 핵심: {title} ({estimatedMinutes}분)`
  - 오늘, 계획·main task 없음: `DevPilot 오늘 계획 만들기`
  - 내일 ~ 6일 후: `DevPilot 학습`
- 피드에 자기 회고, 답변, 코드, 점수, risk를 넣지 않는다.
- 알림 시각은 사용자가 캘린더 앱에서 정한다(DevPilot에 알림 시각 설정은 없다).
- 토큰 폐기만 하는 API는 없다. 재발급으로 이전 링크를 끊는다. 계정 삭제 요청 시 토큰은 즉시 지워진다.

**관련 API** — `POST /me/calendar-token`, `GET /calendar/{token}.ics`
**관련 화면** — SCR-SETTINGS(캘린더 구독 섹션)
**AC** — — (API 테스트로 검증) · **Sprint** — S2 · **우선순위** — SHOULD

### FR-21 복귀 모드

**설명** — 며칠 쉬고 돌아온 사용자에게 밀린 양을 들이밀지 않고, 복습 상한을 줄이고 쉬운 과제로 다시 시작하게 한다.

**사용자 스토리** — As a 바빠서 며칠 못 한 사용자, I want 부담 없이 다시 시작하고 싶다, so that 죄책감 때문에 앱을 피하지 않는다.

**규칙**
- 판정: `comebackMode = (최근 3 plan-day에 COMPLETED 세션 없음) && (그 이전에 COMPLETED 세션 ≥ 1)` (`06` §5.5, `ComebackModePolicy`). 첫 사용자는 복귀 모드가 아니다.
- 효과: 복습 상한 10장(`06` §5.6), task 난이도 ≤ 2(`06` §5.3), `COMEBACK_HARD_TASK` modifier(`06` §5.5), 이유 `COMEBACK_EASY_START`(`06` §5.8).
- `daily_plan.comeback_mode`에 저장하고 `GET /today`에 포함한다.
- 화면: Today 상단에 복귀 안내 배너 1줄(`02` §4.14). **쉰 날 수, 밀린 카드 수, "연속 기록이 끊겼어요" 같은 문구를 보여주지 않는다.**
- 복귀 모드는 사용자가 끄거나 켤 수 없다. 완료 세션이 생기면 다음 plan-day부터 자연스럽게 해제된다.

**관련 API** — `POST /today/generate`, `GET /today`
**관련 화면** — SCR-TODAY
**AC** — AC-02 · **Sprint** — S2 · **우선순위** — SHOULD

### FR-22 AI 사용량·예산 표시와 차단

**설명** — AI 호출 수·비용을 기록하고 한도에 가까워지면 경고, 초과하면 AI 기능만 막는다. 사용자는 현재 AI 상태와 사용량을 볼 수 있다.

**사용자 스토리** — As a 비용을 직접 내는 소유자, I want AI 비용이 예산을 넘지 않게 자동으로 막히길 원한다, so that 예상하지 못한 청구가 생기지 않는다.

**규칙**
- 한도(DEC-06, `03` §9): 서비스 전체 월 예산 USD 3, 사용자당 일일 호출 60회, 사용자당 동시 실행 2개.
- `AiBudgetGuard`는 AI 호출 전에 확인한다. 초과 시 공급자를 호출하지 않고 `ai_call_log.status=BUDGET_BLOCKED`를 남긴다.
  - 월 예산 초과 → `429 AI_MONTHLY_BUDGET_EXCEEDED`
  - 일일 호출 초과 → `429 AI_DAILY_LIMIT_EXCEEDED`
  - 동시 실행 초과 → `429 AI_CONCURRENCY_LIMIT`
- 비동기 작업의 예산 확인은 요청 시점(저장 전)에 한다(`03` §5.3). 확인 후 실행 시점에 초과되면 작업은 `FAILED(AI_BUDGET_EXCEEDED)`다.
- `GET /me`의 `aiStatus`: provider가 `disabled`이거나 월 비용 ≥ 예산이면 `DISABLED`, 공급자 선불 잔액이 소진되면 `BALANCE_EXHAUSTED`(ADR-035), 월 비용 ≥ 80%(`budget-warning-ratio`)면 `BUDGET_WARNING`, 그 외 `ENABLED`. 클라이언트는 `BALANCE_EXHAUSTED`를 `DISABLED`와 같게 다루고 이유 문구만 다르게 보여 준다. 일일 호출 한도 도달은 `aiStatus`에 반영하지 않는다. `aiUsage` = `todayCalls`, `dailyCallLimit`, `monthCostUsd`(서비스 전체, 문자열 소수 2자리), `monthlyBudgetUsd`(`05-api-spec.md` §1.9.1).
- 월 경계는 Asia/Seoul 기준 달력 월(NFR-01), 일일 경계는 사용자 plan-day다. 429 응답에는 `Retry-After`가 있다. 비용 계산은 `17-ai-integration.md`, 단가는 설정값(`03` §9)을 따른다.
- **AI 차단은 비-AI 기능에 영향을 주지 않는다**(NFR-03, AC-12): Today, 복습(자기평가), 계획, skill 조회, 이력, 수동 카드, 수동 evidence.
- 클라이언트는 `DISABLED`일 때 AI 진입 버튼을 비활성화하고 이유를 보여준다. `BUDGET_WARNING`은 AI 진입점과 설정에 경고를 표시한다(`02` §6.5).
- 공급자에 콘솔 하드 캡이 없으므로 **선불 잔액을 소액으로 유지**하는 것이 외부 상한이다. 앱 예산(기본 USD 3)이 먼저 차단하고, 잔액이 임계값 미만이면 `aiStatus = BALANCE_EXHAUSTED`로 AI를 멈춘다(ADR-035, NFR-01).

**관련 API** — `GET /me` (`aiStatus`, `aiUsage`), 모든 AI 유발 API의 429/503 응답
**관련 화면** — SCR-SETTINGS, AI 진입 화면 전체(SCR-TRAINING-LIST, SCR-TRAINING-ATTEMPT, SCR-COACH-NEW, SCR-COACH-DETAIL, SCR-REVIEW-SESSION, SCR-EVIDENCE-DETAIL, SCR-JOB-NEW)
**AC** — AC-13 · **Sprint** — S3 · **우선순위** — MUST

### FR-23 데이터 export·계정 삭제

**설명** — 사용자는 자기 데이터를 JSON으로 내려받고, 최근 재로그인을 확인한 뒤 계정과 모든 학습 데이터를 삭제한다.

**사용자 스토리** — As a 사용자, I want 내 기록을 가져가거나 완전히 지울 수 있기를 원한다, so that 내 데이터를 내가 통제한다.

**규칙**
- `GET /me/export`: 사용자 소유 데이터 전체를 JSON 1개로 반환한다 — 프로필, career goal, 모든 plan version(milestone, skill target, snapshot), skill state·변경 이력, 세션, learning event, daily plan·task, 소유 challenge·attempt·submission, hint disclosure, review item·answer, coach review(purge 전 content 포함)·finding·observation, evidence, weekly review, job posting(purge 전 JD 포함)·requirement.
- export 제외: `ai_call_log`, `idempotency_record`, `calendar_token_hash`, seed catalog, 다른 사용자 데이터. 감사 이벤트 `DATA_EXPORTED`를 남긴다. 형식·정렬은 `05-api-spec.md` §3.3이다.
- `DELETE /me`: 최근 인증 시각 `authTime` = JWT `amr[].timestamp` 최댓값(`amr`이 없을 때만 `iat`)이 **5분 이내**여야 한다(`devpilot.security.account-deletion-max-token-age`, `03` §4.2, `05-api-spec.md` §3.4). 아니면 `403 RECENT_LOGIN_REQUIRED`. 클라이언트 카운트다운도 같은 기준을 쓴다.
- 성공 시 `202`. `status=DELETION_REQUESTED`가 되고 캘린더 토큰이 지워진다. 이후 `GET /me`, `DELETE /me` 외 API는 `403 FORBIDDEN`이다. `AccountDeletionJob`(5분 주기)이 `app_user`를 삭제해 cascade로 지우고 `ai_call_log.user_id`는 null이 된다(`04` §8, `03` §6).
- 운영자는 삭제된 계정을 **allowlist에서도 제거**한다. 남겨 두면 다시 로그인할 때 새 사용자가 생긴다(`05-api-spec.md` §3.4). Supabase 모드(Later)에서는 Auth 사용자도 대시보드에서 수동 삭제한다(DEC-11). 화면에서 이 사실을 알린다.
- 백업 속 데이터는 백업 보관 기간(일간 14개, 월간 6개) 만료 시 사라진다(`04` §8). 화면에서 알린다.
- 삭제 요청은 취소할 수 없다.

**관련 API** — `GET /me/export`, `DELETE /me`
**관련 화면** — SCR-SETTINGS, SCR-ACCOUNT-DELETE
**AC** — AC-15 · **Sprint** — S6 · **우선순위** — MUST

### FR-24 사용자 설정 (timezone, 하루 시작 시각, 학습 시간)

**설명** — 사용자는 표시 이름, timezone, 하루 시작 시각, 평일·주말 학습 가능 시간을 바꾼다. 이 값은 plan-day 계산, budget, Today 기본값에 쓰인다.

**사용자 스토리** — As a 자정 넘어 공부하는 사용자, I want 새벽 공부가 전날 기록으로 남기를 원한다, so that 하루 계획과 기록이 내 생활 리듬과 맞는다.

**규칙**
- `PATCH /me`: `displayName` 1~100자, `timezone` IANA ID(서버가 `ZoneId`로 검증), `dayStartHour` 0~6, `weekdayStudyMinutes`/`weekendStudyMinutes` 0~720, `version` 필수. null 필드는 변경하지 않는다. `experienceProfile`, `careerStartDate`는 이 API로 바꾸지 않는다.
- plan-day 계산은 `06` §2. 변경은 **다음 요청부터 즉시** 적용된다. 이미 저장된 `daily_plan`, 세션, 이벤트의 `plan_date`는 다시 계산하지 않는다.
- timezone·dayStartHour를 바꾸면 "오늘"이 앞뒤로 이동할 수 있다. 화면에서 변경 전에 이 점을 알린다.
- 학습 시간 변경은 다음 budget 계산(snapshot, preview)부터 반영된다.
- 클라이언트는 날짜·시각을 **기기 timezone이 아니라 `GET /me`의 `timezone`으로** 표시하고, 오늘 plan-day는 `GET /me`의 `today`를 쓴다(NFR-09).
- 이메일, GitHub 계정 정보는 DevPilot에서 수정하지 않는다.

**관련 API** — `GET /me`, `PATCH /me`
**관련 화면** — SCR-SETTINGS, SCR-ONBOARDING(2단계)
**AC** — AC-17 · **Sprint** — S1 · **우선순위** — MUST

---

## 9. 비기능 요구사항

| ID | 요구사항 | 측정 가능한 기준 | 측정·강제 방법 | AC |
|---|---|---|---|---|
| NFR-01 | **비용**: 추가 인프라 비용 0, AI 월 USD 3 이하 | ① 서버·Tailscale은 이미 쓰던 것이라 추가 비용이 없고 도메인은 쓰지 않는다(ADR-031) ② 운영 AI 비용은 앱의 서비스 전체 월 예산 **USD 3**(DEC-06, Asia/Seoul 기준 달력 월)로 제한한다: `ai_call_log.cost_micro_usd` 월 합계 ≤ 예산 ③ 80% 도달 시 `BUDGET_WARNING`, 100%면 AI 차단 ④ 외부 상한은 **선불 잔액**뿐이다(콘솔 하드 캡 없음) — 잔액 < `min-balance-usd`이면 `BALANCE_EXHAUSTED`(ADR-035) | `AiBudgetGuard`, `AiBalanceCheckJob`, 일일 요약 로그(`03` §8) | AC-13 |
| NFR-02 | **성능** | ① AI를 호출하지 않는 API의 서버 p95 < 1000ms (사용자 1명 기준 데이터: 이벤트 5,000행, 복습 카드 500장에서 k6 50 req) ② 동기 AI(`HINT_GENERATE`, `REVIEW_EVALUATE`, `COACH_RESPONSE_FEEDBACK`) 서버 타임아웃 20s ③ 비동기 AI 작업 요청~완료 ≤ 180s(operation 타임아웃) ④ 캐시된 재방문 시 Today 데이터 표시 ≤ 3s (Chrome Android, Lighthouse "Fast 4G" 프로필) | Micrometer 지표, k6 스크립트(S2), Lighthouse(S2) | — |
| NFR-03 | **가용성**: 단일 인스턴스 best effort, AI 장애 시 핵심 기능 유지 | ① SLA 없음. 외부 uptime monitor 5분 간격, 월 가용성 ≥ 99%를 추적 목표로 둔다 ② AI provider `disabled`/5xx에서 Today 생성, 복습 답변, 계획 조회·수정, 이력 조회가 모두 2xx ③ RPO ≤ 24h(일간 백업), RTO ≤ 4h(VM 재구축) | provider=disabled 통합 테스트, `10-deployment-and-operations.md` runbook | AC-12 |
| NFR-04 | **보안**: OWASP Top 10 대응, 사용자 격리 | ① 모든 사용자 소유 리소스 API에서 타 사용자 토큰 → 404 (endpoint 목록 기반 파라미터화 테스트 100% 통과) ② allowlist 밖 사용자 403, row 미생성 ③ 오류 응답에 stack trace·SQL·클래스명 0건 ④ 요청 body > 64KB는 413 ⑤ 서비스는 tailnet 안에서만 접근 가능하고 공개 인터넷에 노출하지 않는다(ADR-031). Supabase 도입 시 Data API로 `devpilot` 스키마 조회 불가(DEC-15) ⑥ 저장소 secret·서버 주소·이메일 0건(gitleaks — DEC-04) ⑦ 인증 POST에 `Idempotency-Key` 없으면 400 | Security 테스트, CI 스캔, `07-security-and-privacy.md` | AC-08, AC-18, AC-20, AC-23 |
| NFR-05 | **개인정보**: 최소 수집, 보존기간, export/삭제, 마스킹 | ① 수집 항목에 나이·성별·이메일 원문 저장 없음 ② coach content 30일, JD 180일, ai_call_log 180일, idempotency 24h 후 삭제(`04` §8) ③ 저장·AI 전송 전 secret masking, private key 차단(I-14) ④ export에 타 사용자 데이터 0건, 삭제 후 사용자 row 0건 ⑤ 로그에 코드·프롬프트·응답 원문·이메일·Authorization 0건 | purge job 테스트, AC-14/15 테스트, 로그 필드 검사 | AC-14, AC-15 |
| NFR-06 | **관측성**: structured log, traceId, 감사 이벤트 | ① prod 로그 100% JSON, 모든 요청 로그에 `traceId`, 인증 요청에 `userRef` ② 모든 응답에 `X-Trace-Id` 헤더 ③ 감사 이벤트(`07-security-and-privacy.md` §6.3) 누락 0건 ④ 스케줄 job마다 시작·건수·소요시간 INFO 1줄, 실패 시 `JOB_FAILED` WARN ⑤ 화면 오류 상세에 `traceId` 표시 | `03` §8, 통합 테스트, `02` §3.3 | — |
| NFR-07 | **유지보수성**: 자동 품질 게이트, 문서·코드 일치, 결정적 규칙 | ① PR마다 format, Checkstyle, PMD, SpotBugs, ArchUnit, 테스트, `flutter analyze`, `flutter test` 통과 전 merge 불가 ② `06`의 test vector 100% `@ParameterizedTest`로 통과 ③ 규칙 계산에 부동소수점 0건(N-1) ④ enum 이름은 `04` §3과 1:1 ⑤ 가중치·임계값 하드코딩 0건(`03` §9) ⑥ API·DB·규칙 변경 PR은 관련 문서를 같은 PR에서 갱신 | CI, ArchUnit, 코드 리뷰 체크리스트 | — |
| NFR-08 | **접근성·반응형**: 360px~, 터치 44px, 색 외 표시 | ① 폭 360px에서 가로 스크롤 없음(모든 SCR) ② 터치 대상 ≥ 44×44 CSS px ③ 텍스트 대비 ≥ 4.5:1, 아이콘·경계 ≥ 3:1 (WCAG 2.1 AA) ④ 상태·등급·배지는 텍스트 라벨 포함(색만으로 구분 0건) ⑤ 데스크톱 복습은 키보드만으로 완료 가능 ⑥ 글자 크기 200%에서 핵심 버튼 가려짐 없음 ⑦ 한국어 IME 조합 입력·붙여넣기 정상(SP-1) | widget test, 수동 점검 체크리스트(`02` §7) | AC-10 |
| NFR-09 | **시간**: plan-day, UTC 저장 | ① instant는 UTC `timestamptz`, 사용자 날짜는 plan-day `date` ② 서버 시간 계산은 주입된 `Clock`만 사용(`LocalDate.now()` 직접 호출 0건, ArchUnit) ③ `06` §2 test vector 통과 ④ 클라이언트 표시는 `GET /me.timezone` 기준 | 단위·통합 테스트 | AC-17 |
| NFR-10 | **이식성**: linux/amd64 이미지, 설정 기반 AI 모델 | ① backend 컨테이너 이미지 `linux/amd64` 빌드·기동 성공(자체 서버 x86_64, ADR-031) ② AI 모델 ID·provider·단가·prompt 버전은 설정값(`devpilot.ai.*`)만 바꿔 교체(DEC-05) ③ 도메인 코드에서 공급자 HTTP 타입 import 0건(`integration.ai.deepseek` 제외, ArchUnit ARCH-03) ④ Flutter 코드는 web 전용 API를 `platform/` 어댑터에만 둔다(Android 확장 대비) | CI 이미지 빌드, ArchUnit | — |

---

## 10. 제약 · 가정

### 10.1 제약

| # | 제약 | 영향 |
|---|---|---|
| C-1 | **단일 backend 인스턴스**, 메시지 큐·캐시 서버 없음(`03` §1) | 스케줄 job은 분산 락 없이 동작. 비동기 AI는 in-process executor(core 2, queue 20) |
| C-2 | **사용자 ≤ 3명**(DEC-01) | 집계는 실시간 쿼리로 충분. 캐시 없음 |
| C-3 | **한국어 UI만** 제공. 식별자·기술 용어·enum은 영어 원문 | l10n 구조는 두되 `ko` 하나만 둔다(`02` §3.1) |
| C-4 | **자체 서버**: 공용 Linux 서버(2 vCPU, 가용 약 4.7GB)와 공용 PostgreSQL 16을 다른 서비스와 나눠 쓴다. 관리형 백업이 없고 tailnet 밖에서 접근할 수 없다 | 보존기간 정책(`04` §8), 자체 백업(일 1회 + 주 1회 로컬 pull), JVM 메모리 상한, 데이터 크기 관리 |
| C-5 | **AI 예산**: 월 USD 3, 일일 60회/사용자, 동시 2개(DEC-06), 모델 `deepseek-flash`(DEC-05), 외부 상한은 선불 잔액 | 비동기 우선, 사전 생성 hint, AI 불가 시 대체 동작 |
| C-6 | 웹 우선 PWA(DEC-18). 네이티브 앱·Push 알림 없음 | 알림은 캘린더 구독(FR-20) |
| C-7 | 대상 직무 `JAVA_BACKEND` 1개, skill catalog·템플릿은 저장소 YAML(`04` §9) | 직무 추가는 content 작업 + enum 확장 |
| C-8 | 로그인은 GitHub OAuth만(DEC-08) | 사용자는 GitHub 계정 필요 |
| C-9 | 지원 브라우저: Chrome·Edge 최신 2개 버전(데스크톱·Android), Safari 17 이상(iOS·macOS). 2026-09-17 기준, 구현 시 SP-1에서 확인 | 그 외 브라우저는 동작을 보장하지 않는다 |
| C-10 | 코드 실행 환경 없음(NG-7) | challenge 평가는 AI rubric 판정, `VERIFIED`는 curated source만 |

### 10.2 가정

| # | 가정 | 틀리면 |
|---|---|---|
| A-1 | seed 콘텐츠(skill 60~90개, 복습 카드, challenge, plan 템플릿)가 S1~S3에 준비된다 | planner·budget 품질 저하 → content 작업을 Sprint 최우선으로 올린다 |
| A-2 | 사용자는 하루 최소 5분은 앱을 연다 | 캘린더 구독·복귀 모드 효과를 S5 weekly 지표로 재평가 |
| A-3 | `06`의 가중치·임계값은 초기값이며 4주 사용 후 조정한다 | 설정값만 변경하고 test vector를 갱신한다 |
| A-4 | 사용자가 붙여넣는 코드는 개인 프로젝트 코드다(동의 체크) | `confidentialSuspected` 판정 시 분석하지 않는다 |
| A-5 | `deepseek-flash` 단가·파라미터는 2026-09-18에 실제 호출로 확인한 값이며(`17` §2), 응답 필드 일부는 구현 시 재확인한다 | 설정 갱신, `17` 먼저 수정 |
| A-6 | 구현은 AI 코딩 에이전트가 대부분 맡고, 사용자는 주 8~10시간 리뷰·핵심 규칙 구현을 한다 | S1 종료 시 속도를 보고 S3 이후 범위를 조정한다 |

---

## 11. 용어

용어 정의(plan-day, horizon, nominal/effective budget, planning level, evidence level, final rating, leech, assistance level, independent solve, self-review, discovered by 등)는 `15-glossary.md`가 기준이다. 이 문서에서 처음 나오는 용어도 그 문서의 정의를 따른다.
