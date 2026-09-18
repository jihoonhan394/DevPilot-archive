# 12. Acceptance Criteria

> Status: Accepted (v2) · Last updated: 2026-09-18 · Related: `01-product-requirements.md`, `05-api-spec.md`, `06-learning-engine-rules.md`, `09-test-and-quality.md`, `11-development-roadmap.md`, `13-product-backlog.md`
>
> 기능 완료를 판단하는 기준이다. 각 AC의 시나리오는 자동 테스트(또는 표시된 수동 절차)로 그대로 옮긴다. 오류 코드는 `05-api-spec.md` 카탈로그, enum은 `04-domain-model-and-db.md` §3, 규칙은 `06-learning-engine-rules.md`가 기준이다.

---

## 0. 읽는 법

| 항목 | 규칙 |
|---|---|
| 공통 전제 | 별도 표시가 없으면: `Asia/Seoul`, `dayStartHour = 4`, 온보딩 완료 사용자, `MutableClock` 고정 시각, `devpilot.*` 기본 설정(`03-system-architecture.md` §9), 모든 인증 `POST`에 새 `Idempotency-Key` |
| 사용자 | `A`, `B` = allowlist에 있는 서로 다른 사용자. `X` = allowlist에 없는 사용자 |
| 시각 표기 | `D` = 테스트 시점의 plan-day. `start(D)` = `planDayStart(D, Asia/Seoul, 4)` |
| AI | 자동 테스트는 `FakeAiProvider`(fixture) 또는 `DisabledAiProvider`만 쓴다. 실제 모델 확인은 eval(`17-ai-integration.md`)로 한다 |
| 검증 수준 | `unit`(순수 Java, vector) · `integration`(Spring + Testcontainers, 서비스·리포지토리) · `API E2E`(실행 중인 앱 + HTTP) · `UI`(Flutter widget / integration_test) · `manual ops`(prod 환경에서 사람이 확인) |
| 테스트 클래스 | `09-test-and-quality.md` §3.1 명명을 따른다: 단위 `<ProductionClass>Test`, 통합 `<ProductionClass>IntegrationTest`, E2E `<Flow>FlowTest`, 아키텍처 `<Topic>ArchTest`, 모듈을 가로지르는 보안 테스트는 `07-security-and-privacy.md` §16 이름. 모든 클래스 이름은 `Test`로 끝나고 단위·통합 구분은 JUnit 태그로 한다(`*IT` 접미사 없음). 두 문서에 이름이 없는 테스트는 `<Feature><Scenario>Test`. Flutter는 `*_test.dart`. 추적은 테스트 메서드 이름 또는 `@DisplayName`에 `AC-xx Sn`을 넣는다 |
| Sprint | 해당 AC를 처음 통과시켜야 하는 Sprint. 이후 Sprint에서 회귀 테스트로 유지한다 |

## 1. 요약

| AC | 제목 | 관련 요구사항 | Sprint |
|---|---|---|---|
| AC-01 | 목표·계획 저장과 버전 이력 | FR-03, FR-04 | S1 (이벤트 S2) |
| AC-02 | Today 생성 | FR-07, FR-08, FR-16, FR-21 | S2 (challenge 제안 S3) |
| AC-03 | Deadline risk | FR-05 | S5 |
| AC-04 | Challenge | FR-09 | S3 |
| AC-05 | Memory 스케줄 | FR-11 | S2 (challenge S3, coach S4) |
| AC-06 | Project Coach | FR-12 | S4 |
| AC-07 | Verification | FR-14 | S4 |
| AC-08 | 보안 격리·오류 노출 금지 | FR-01, NFR-04 | S1~S7 (endpoint 추가마다), 전체 재검증 S6 |
| AC-09 | Learning state 갱신 | FR-06 | S1 (planning level), S3 (updater) |
| AC-10 | 모바일 복습 | FR-11, NFR-08 | S2 |
| AC-11 | 온보딩·진단 제안 | FR-02, FR-15 | S1 (seed 카드 S2, 진단 S3) |
| AC-12 | AI 불가 시 동작 | NFR-03, FR-22 | S3, S4 재검증 |
| AC-13 | AI 예산 가드 | FR-22, NFR-01 | S3 |
| AC-14 | Secret masking | FR-12, NFR-05 | S3 (training·review·session·JD), S4 (coach) |
| AC-15 | Export·계정 삭제 | FR-23, NFR-05 | S6 |
| AC-16 | Hint Ladder 정책 | FR-10 | S3 (challenge), S4 (coach) |
| AC-17 | 날짜 경계 | FR-07, FR-24, NFR-09 | S2 |
| AC-18 | Allowlist | FR-01, NFR-04 | S1 |
| AC-19 | Coach self-review·thinking pattern | FR-12, FR-13 | S4 (추세 S5) |
| AC-20 | Data API 비노출 | NFR-04 | S0 (S1·S6 재확인) |
| AC-21 | Evidence·Weekly | FR-17, FR-18 | S5 (weekly), S6 (evidence) |
| AC-22 | Job Radar | FR-19 | S7 |
| AC-23 | Idempotency | NFR-01, NFR-04 | S3, S4 재검증 |
| AC-24 | Plan 일관성(동시 replan) | FR-04 | S1 |
| AC-25 | devtoken 인증 | FR-01, NFR-04 | S0 |

---

## AC-01 목표·계획 저장과 버전 이력

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-03, FR-04 |
| Sprint | S1 (`PLAN_REPLANNED` 이벤트 확인은 S2) |
| 검증 수준 | API E2E, UI(데모) |
| 테스트 클래스 | `CareerGoalServiceIntegrationTest`, `ReplanServiceIntegrationTest`, `ReplanFlowTest` |

**S1. 저장 후 재조회**
- Given A가 온보딩에서 `applicationStartDate = 2027-01-05`, `targetCompletionDate = 2027-04-01`, `useTemplate = true`로 plan v1을 만들었다
- When A가 새 토큰으로 `GET /career-goal`, `GET /plans/active`를 호출한다
- Then `GET /career-goal`의 두 날짜·focus skill이 온보딩 요청값과 같고, milestone 목록(title, startDate, endDate, priority, status, skillCodes)이 온보딩 직후 첫 `GET /plans/active` 응답과 필드 단위로 같다(온보딩 응답의 `PlanSummaryView`에는 milestone이 없다). `planVersion = 1`, `status = ACTIVE`

**S2. in-place 수정은 새 버전을 만들지 않는다**
- When `PATCH /plans/{v1}/milestones/{m1}` `{ "status": "IN_PROGRESS", "version": 0 }`
- Then 200, milestone `version = 1`. `GET /plans` 항목 1개, `planVersion = 1`

**S3. 구조 변경은 새 버전이다**
- When `POST /plans/{v1}/replan` `{ reason, version, milestones: 기존 전체 + 새 milestone 1개, acceptedDeferrals: [], acceptedTargetReductions: [], restoredDeferrals: [] }`
- Then 201, 새 plan `planVersion = 2`, `status = ACTIVE`, `supersedesPlanId = v1.id`
- And `GET /plans`는 2건: v2 `ACTIVE`, v1 `SUPERSEDED`(`supersededAt` 있음)
- And `GET /plans/{v1.id}`의 milestone 수·필드가 replan 전과 같다(이전 버전 불변)
- And `milestoneIdMapping` 길이 = 요청 중 `id`가 있던 milestone 수, 새 milestone id는 모두 이전 id와 다르다
- And DB에서 A의 `status = 'ACTIVE'` plan은 1행
- And (S2 이후) `PLAN_REPLANNED` learning event 1건, payload `fromVersion = 1`, `toVersion = 2`

**S4. 이전 버전은 수정할 수 없다**
- When v2 생성 후 `PATCH /plans/{v1}/milestones/{m1}` 또는 `POST /plans/{v1}/replan`
- Then 409 `PLAN_NOT_ACTIVE`, DB 변경 없음

**S5. 목표 수정과 동시성**
- When `PUT /career-goal`에 이전 `version`을 보낸다 → 409 `CONCURRENT_MODIFICATION`, 값 변경 없음
- When `targetCompletionDate`를 바꾼 `PUT /career-goal`(최신 version) → 200, 활성 plan `replanRecommended = true`, `planVersion` 변화 없음
- When `applicationStartDate > targetCompletionDate` → 400 `VALIDATION_FAILED`, `errors[].code = DATE_ORDER_INVALID`

---

## AC-02 Today 생성

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-07, FR-08, FR-16, FR-21 |
| Sprint | S2 (CHALLENGE 제안 연결은 S3) |
| 검증 수준 | unit(vector), API E2E, UI |
| 테스트 클래스 | `PlannerScoringTest`, `TaskProposalPolicyTest`, `TimeAllocatorTest`, `ReasonTemplatesTest`, `ComebackModePolicyTest`, `TodayPlanServiceIntegrationTest`, `TodayChallengeProposalAiDisabledTest`, `LearningSessionServiceIntegrationTest`, `DashboardQueryServiceIntegrationTest`, `OnboardingToTodayFlowTest`, `today_screen_test.dart` |

공통 Given: A의 활성 plan에 후보 skill이 1개 이상 있다(모든 target 충족이면 `mainTask = null`이 정상 응답이며 이 AC의 main 관련 Then은 적용하지 않는다). risk `LOW`, AI provider `disabled`.

**S1. 30분 · NORMAL**
- Given due review 3장, D의 daily plan 없음
- When `POST /today/generate` `{ "availableMinutes": 30, "energyLevel": "NORMAL" }`
- Then 성공 응답, D의 `daily_plan` 1행(`plan_date = D`, `generation_count = 1`)
- And `is_main = true` task 정확히 1개(`PLANNED`), `REVIEW` task 1개(`is_main = false`, `sort_order = 0`, `estimated_minutes = 5`)
- And 모든 task `estimated_minutes` 합 ≤ `floorDiv(30 × 11_000, 10_000)` = **33**, main `estimated_minutes` ≤ 27
- And main `reason_codes` 1~3개, 모두 `ReasonCode` 값
- And `score_breakdown.plannerVersion = "RULE_V1"`, factor는 0~1,000,000 정수, `finalScore`는 정수
- And `ai_call_log` 새 행 0

**S2. 결정적 규칙 vector**
- `06` §5.6 표 6행(reviewMinutes·mainBudget·limit), §5.7 표 6행(A/B 선택), §5.8 최소 1개 보장이 모두 통과한다

**S3. 입력 경계**
- `availableMinutes` 4 또는 721 → 400 `VALIDATION_FAILED`
- `energyLevel = "TIRED"` → 400 `UNKNOWN_ENUM_VALUE`
- `availableMinutes = 5`, due 4장 → reviewMinutes 0이므로 `REVIEW` task 0개, main = `RECALL`, `estimated_minutes = 5` (`06` §5.6)

**S4. 재생성 (`06` §5.9)**

| Given (D의 active main) | 요청 | Then |
|---|---|---|
| `PLANNED` | `force = false` | 성공, `generation_count = 2`, 이전 `PLANNED` task 0행 남음, active main 1개 |
| `IN_PROGRESS` | `force = false` | 409 `TODAY_ALREADY_STARTED`, task 변경 없음 |
| `IN_PROGRESS` | `force = true` | 기존 main `DEFERRED`, 새 main `PLANNED` 1개 |
| `COMPLETED` (active main 없음) | `force = false` | 409 `TODAY_ALREADY_COMPLETED` |
| `COMPLETED` | `force = true` | 기존 main `COMPLETED` 유지, 새 main `PLANNED` 1개 |

**S5. WIP = 1**
- When 같은 D에 서로 다른 `Idempotency-Key`로 `POST /today/generate` 2개를 동시에 보낸다
- Then D의 main 중 `PLANNED`/`IN_PROGRESS`는 항상 1개(`uq_learning_task_one_active_main`)
- When active main이 있는 상태에서 `SKIPPED` task를 `PLANNED`로 PATCH → 409 `INVALID_STATE_TRANSITION`

**S6. 선행 조건**
- 온보딩 전 `POST /today/generate` → 409 `ONBOARDING_REQUIRED`
- 활성 plan 없음(fixture로 plan `ARCHIVED`) → 404 `PLAN_NOT_FOUND`
- D에 daily plan이 없을 때 `GET /today` → 404 `TODAY_NOT_GENERATED`

**S7. 복귀 모드 (FR-21)**
- Given 마지막 `COMPLETED` 세션의 `plan_date = D − 4`, `D − 3 ~ D − 1`에 `COMPLETED` 세션 없음, due 15장, 전날 main 없음, energy `NORMAL`
- Then `daily_plan.comeback_mode = true`, REVIEW task의 due 수 ≤ 10, main `reason_codes`에 `COMEBACK_EASY_START`
- And 후보가 difficulty 3 `PROJECT_TASK` 1개뿐인 fixture에서 main `score_breakdown.modifiers`에 `COMEBACK_HARD_TASK`(7000bp)가 있다
- Given `COMPLETED` 세션 이력이 전혀 없음 → `comeback_mode = false`

**S8. AI 상태와 CHALLENGE 제안 (S3)**
- Given 후보 skill이 1개이고, 그 skill에 14 plan-day 안에 시도하지 않은 VALIDATED PRACTICE challenge(difficulty = `06` §5.3의 d)가 있다
- When `aiStatus = ENABLED`이면 main `task_type = CHALLENGE`, `challenge_id` 설정
- When `aiStatus = DISABLED`이면 CHALLENGE task를 만들지 않고 `06` §5.3의 다음 규칙(READING/PROJECT_TASK/EXPLAIN)을 쓴다

**S9. 학습 세션 (FR-08)**
- When `POST /learning-sessions` `{ learningTaskId: main }` → `IN_PROGRESS`, `plan_date = D`, `SESSION_STARTED` 이벤트
- When 다른 세션을 또 시작 → 이전 세션 `ABANDONED`, A의 `IN_PROGRESS` 세션 1개
- When `POST /learning-sessions/{id}/complete` `{ actualMinutes: 25, selfReflection: "…" }` → `COMPLETED`, `SESSION_COMPLETED.payload.actualMinutes = 25`
- When `actualMinutes = 721` → 400 `VALIDATION_FAILED`, 세션 상태 변경 없음

**S10. Dashboard 최소 (FR-16)**
- Given S1·S9 수행 후
- When `GET /dashboard`
- Then 응답에 오늘 main 상태, `dueReviewCount = 3`, `weekStudyMinutes`(D가 속한 ISO 주의 `weekStartDate` ~ D, COMPLETED 세션 합)에 25분 포함

---

## AC-03 Deadline risk

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-05 |
| Sprint | S5 |
| 검증 수준 | unit(vector), integration, API E2E, UI(데모) |
| 테스트 클래스 | `StudyBudgetCalculatorTest`, `DeadlineRiskEvaluatorTest`, `ReplanSuggestionPolicyTest`, `StudyBudgetServiceIntegrationTest`, `ReplanFlowTest`, `ProgressSnapshotJobIntegrationTest` |

**S1. 규칙 vector**
- `06` §3.3 7행, §4.2 3행, §4.3 8행, §4.4 1건이 모두 통과한다

**S2. Budget 조회**
- Given 평일 45분·주말 240분, D = 2026-12-07(월), `applicationStartDate = 2026-12-14`, 최근 28 plan-day `daily_plan` 없음
- When `GET /plans/active/budget`
- Then `horizonDate = 2026-12-14`, `nominalBudgetMinutes = 705`(5 × 45 + 2 × 240), `completionRateBp = 7000`, `effectiveBudgetMinutes = 493`
- And DB 저장 없음(`plan_progress_snapshot` 행 수 변화 0)

**S3. HIGH risk 미리보기**
- Given effective 5000분, MUST required 합 5900분, SHOULD target A(importance 0.40, 480분)·B(0.40, 900분)·C(0.70, 300분)
- When `POST /plans/{planId}/replan/preview` (현재 milestone 그대로)
- Then `riskLevel = HIGH`, `ratioBp = 11800`, defer 제안 순서 **B, A, C**, MUST 목표 축소 제안 1개 이상, 축소 후 target은 모두 ≥ 3, `riskAfterSuggestions` 존재
- And `learning_plan`, `plan_skill_target`, `plan_progress_snapshot`, `idempotency_record` 행 수 변화 0 (`Idempotency-Key` 없이 호출해도 성공)

**S4. 제안 채택 저장**
- When `POST /plans/{planId}/replan` `{ acceptedDeferrals: ["<B skillCode>"], … }`
- Then 201, 새 plan의 B `deferred = true`, `adjustment = DEFERRED`
- And `GET /plans/active/budget`의 `requiredShouldMinutes`에서 B 900분이 빠진다
- And D의 `plan_progress_snapshot`(새 plan id) 1행
- When 다음 replan에서 `restoredDeferrals: ["<B>"]` → B `deferred = false`, `adjustment = USER_EDITED`
- When 같은 skill을 `acceptedDeferrals`와 `restoredDeferrals`에 함께 → 400 `VALIDATION_FAILED`(`errors[].code = MUTUALLY_EXCLUSIVE`)

**S5. Planner 반영**
- Given risk `HIGH`
- Then priority `LATER` skill은 Today 후보에서 빠지고, MUST 후보 `score_breakdown.modifiers`에 `RISK_HIGH_MUST`(12000bp), reason에 `DEADLINE_RISK_MUST`(`06` §5.7 #2)

**S6. `ProgressSnapshotJob`**
- Given A: `Asia/Seoul`, `dayStartHour = 4`
- When clock `2026-12-07T19:05:00Z`(KST 12-08 04:05)에 job 실행 → A의 `snapshot_date = 2026-12-08` 1행
- When clock `2026-12-07T18:05:00Z`에 실행 → A 행 0
- When `19:05Z`에 두 번 실행 → 여전히 1행(upsert)
- When 한 사용자 처리 중 예외 → 다음 사용자는 처리되고 `JOB_FAILED` WARN 1줄

---

## AC-04 Challenge

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-09 |
| Sprint | S3 |
| 검증 수준 | unit(vector), API E2E |
| 테스트 클래스 | `RubricScorerTest`, `AttemptOutcomeCalculatorTest`, `ChallengeValidationServiceTest`, `ChallengeGenerationTaskIntegrationTest`, `SubmissionEvaluationTaskIntegrationTest`, `ChallengeAttemptFlowTest` |

**S1. 판정 vector**
- `06` §8.1~8.2 표 6행이 모두 통과한다

**S2. 조회와 정답 정보 보호**
- `GET /challenges?skillId=…`는 `VALIDATED` challenge만 반환한다(`DRAFT`, `REJECTED`, `RETIRED` 0건)
- A가 해당 challenge의 평가 완료 attempt를 갖기 전 `GET /challenges/{id}` 응답에는 rubric·expectedConcepts 내용이 없다. 평가 완료 후에는 포함된다

**S3. AI 생성**
- When `POST /challenges/generate` `{ skillId, difficulty: 2, … }` → 202 `status = PENDING`
- Then fake fixture(정상) 완료 후 `generationStatus = COMPLETED`, challenge `status = VALIDATED`, `difficulty` 1~5, rubric `weightBp` 합 10000, expectedConcepts ≥ 1개, `hints_json`에 `QUESTION_ONLY`·`CONCEPT_HINT`·`DIRECTION` 3개
- Given fixture의 rubric weight 합 9000 → challenge `status = REJECTED`, `rejection_reason` 있음, 목록에 나오지 않음

**S4. 풀이 흐름**
- When `POST /challenges/{id}/attempts` → 201, `status = STARTED`, `CHALLENGE_STARTED` 이벤트(challenge skill마다 1행)
- When self-explanation 없이 `POST .../submissions` → 409 `SELF_EXPLANATION_REQUIRED`
- When self-explanation 제출 후 `POST .../submissions` `{ answerText, code, language: "JAVA" }` → 202, submission `PENDING` → `COMPLETED`
- Given fixture 평가 `met` = (4000, IMPLEMENTATION, true)(4000, EXPLANATION, true)(2000, IMPLEMENTATION, false), attempt `max_hint_level = QUESTION_ONLY`
- Then `rubricCoverageBp = 8000`, `explanationCoverageBp = 10000`, `evaluatedOutcome = CORRECT`, attempt `outcome = SOLVED_INDEPENDENTLY`, `status = EVALUATED`
- And `CHALLENGE_SUBMITTED`, `CHALLENGE_EVALUATED` 이벤트 payload가 `04` §6 필드를 모두 가진다

**S5. hint 사용 기록**
- Given `CONCEPT_HINT`를 공개한 attempt
- Then attempt `max_hint_level = CONCEPT_HINT`, 이후 rubric 전부 met → `outcome = SOLVED_WITH_HINTS`

**S6. 제출 한도와 상태**
- 이전 submission이 `PENDING`/`RUNNING`일 때 새 제출 → 409 `EVALUATION_IN_PROGRESS`
- `submission_count = 5`에서 6번째 제출 → 409 `SUBMISSION_LIMIT_REACHED`

**S7. 평가 실패와 재시도**
- Given fixture가 timeout
- Then submission `FAILED`, `failureCode = AI_TIMEOUT`, attempt `status = SUBMITTED` 유지
- When `POST .../submissions/{no}/retry` → 202 → `COMPLETED`
- When `COMPLETED` submission retry → 409 `AI_TASK_NOT_RETRYABLE`

---

## AC-05 Memory 스케줄

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-11 |
| Sprint | S2 (challenge 실패 카드 S3, coach finding 카드 S4) |
| 검증 수준 | unit(vector), API E2E |
| 테스트 클래스 | `FinalRatingPolicyTest`, `RuleBasedV1SchedulerTest`, `DueReviewSelectorTest`, `ReviewServiceIntegrationTest`, `ReviewItemServiceIntegrationTest`, `SeedReviewFlowTest`, `SubmissionEvaluationTaskIntegrationTest`(실패 challenge 카드), `CoachReviewServiceIntegrationTest`(coach finding 카드) |

**S1. 규칙 vector**
- `06` §6.6 표 10행이 모두 통과한다
- 연속 답변 간격 수열 (horizon 충분히 멂, 시작 `interval_days = 1`, hint 없음):

| 반복 등급 | `intervalAfter` 수열 |
|---|---|
| GOOD | 2 → 4 → 8 → 16 → 32 → 60 → 60 |
| EASY | 4 → 12 → 36 → 60 |
| HARD (`hard-strategy = MULTIPLY`, 시작 3) | 4 → 5 → 6 → 7 → 8 |
| HARD (`MULTIPLY`, 시작 1) | 2 → 2 → 2 |
| HARD (`FIXED_2`) | 2 → 2 → 2 |
| AGAIN (어느 간격에서든) | 1 |

**S2. 답변 저장**
- Given review item `interval_days = 2`, `due_at = start(D)`
- When `POST /reviews/{id}/answer` `{ answerText: "…", selfRating: "GOOD", hintLevel: "SELF_EXPLAIN", responseSeconds: 40, evaluate: false }`
- Then 응답 `finalRating = GOOD`, `adjustedBy = []`, `intervalBefore = 2`, `intervalAfter = 4`, 다음 due = `start(D + 4)`
- And `review_answer` 1행(`strategy = RULE_V1`, `evaluated_outcome = NOT_EVALUATED`, `plan_date = D`), item `review_count + 1`, `consecutive_successes + 1`, `consecutive_failures = 0`, `last_result = GOOD`, `REVIEW_ANSWERED` 이벤트 1건

**S3. hint 상한**
- `hintLevel = CONCEPT_HINT`, `selfRating = EASY` → `finalRating = HARD`, `adjustedBy = [HINT_CAP_HARD]`
- `hintLevel = FULL_EXAMPLE`, `selfRating = GOOD` → `finalRating = AGAIN`, `adjustedBy = [HINT_CAP_AGAIN]`, `intervalAfter = 1`

**S4. Leech**
- Given `consecutive_failures = 3`
- When `AGAIN` 답변 → item `status = SUSPENDED`, `LEECH_DETECTED` 이벤트 1건, 이후 `GET /reviews/due`에 나오지 않음
- When `PATCH /review-items/{id}` `{ status: "ACTIVE", version }` → `due_at = start(D + 1)`, `consecutive_failures = 0`

**S5. Due 선택**
- Given `ACTIVE` due item 25개(`due_at < start(D + 1)`), `SUSPENDED` 2개, `ARCHIVED` 1개
- When `GET /reviews/due` → 20개, `06` §6.5 정렬, SUSPENDED·ARCHIVED 0개
- Given 복귀 모드 → 10개

**S6. 실패한 challenge → 다음 plan-day 복습 (S3)**
- Given skill 1개짜리 challenge attempt가 D에 평가 완료, `outcome = FAILED`
- Then `review_item` 1행: `concept_key = CHALLENGE:{challengeId}`, `review_type = EXPLAIN`, `source_type = CHALLENGE_ATTEMPT`, `status = ACTIVE`, `due_at = start(D + 1)`
- And D의 `GET /reviews/due`에는 없고, D + 1(clock을 `start(D + 1)`로 이동)에는 있다
- Given 같은 concept_key item이 `due_at = start(D + 5)`로 이미 있음 → 새 행 없음, `due_at = start(D + 1)`, `status = ACTIVE`
- Given skill 2개짜리 challenge → item 2행, `concept_key = CHALLENGE:{challengeId}:{skillCode}`
- `outcome = SOLVED_WITH_HINTS`이고 `max_hint_level = PSEUDOCODE` → item 생성 / `SOLVED_INDEPENDENTLY` → 생성 없음

**S7. Coach finding → 복습 (S4)**
- Given close 시 `BUG` finding(skill 있음, `discoveredBy = MISSED`)과 `LEARNING_POINT` finding(`MISSED`)
- Then `concept_key = COACH:{skillCode}:{category}` item 1행(`source_type = COACH_FINDING`, `due_at = start(D + 1)`), `LEARNING_POINT`는 생성 없음(`06` §9.4)

**S8. 수동 카드**
- When `POST /review-items` `{ skillCode, conceptKey: "MANUAL:<대문자 UUID>", reviewType: "RECALL", prompt, expectedAnswer, rubric: ["…"] }`(rubric 1~6개) → 201, `concept_key` = 요청값, `due_at = start(D + 1)`, `origin = MANUAL`, `source_type = MANUAL`, `rubric_json` = `R1..Rn`
- When 같은 `conceptKey`로 다시 생성 → 200, 새 행 없음 / `rubric: []` → 400 `VALIDATION_FAILED`

---

## AC-06 Project Coach

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-12 |
| Sprint | S4 |
| 검증 수준 | unit, API E2E, eval(수동 실행), UI(데모) |
| 테스트 클래스 | `CodeLeakGuardTest`, `FindingCountGuardTest`, `CoachReviewRequestValidationTest`, `CoachReviewFlowTest`, `CoachContentPurgeJobIntegrationTest`, `OrphanAsyncTaskJobIntegrationTest`, eval suite `coach-review` |

**S1. 생성과 동의 문구**
- Given 40줄 Java 코드(넓은 catch 포함), `confidentialConsent = true`, `userSelfReview`
- When `POST /coach/reviews` → 202 `{ id, status: PENDING, maskedSecretCount: 0 }`
- Then `coach_review.content_lines = 40`, `content_bytes` = UTF-8 byte 수, `content_retention_until = created_at + 30일`
- And fake 분석 완료 후 `status = COMPLETED`
- **UI**: 제출 화면의 동의 체크박스 문구에 (1) 회사·비밀 코드 금지 (2) **코드가 AI 공급자 DeepSeek(중국 소재)로 전송되며 입력을 학습에 쓰지 않는다는 약정이 없음** (3) 원문 30일 보관이 모두 있다(`02-user-scenarios-and-ux.md` SCR-COACH, `07-security-and-privacy.md` §8). 체크하지 않으면 제출 버튼이 비활성이다(widget test)

**S2. Finding 형식 — 수정 코드 없음**
- Then finding 1~7개, 각각 `findingType ∈ {BUG, RISK, LEARNING_POINT}`, `category ∈ ThinkingAxis`, `confidence`, `verificationStatus`, `sourceType`, `summary`, `learningQuestion`이 null 아님
- And 응답 JSON에 수정 코드용 필드가 없고(`05-api-spec.md` view 필드 목록과 정확히 일치), `summary`·`learningQuestion`에 코드 블록(```)이나 코드 줄 3줄 이상이 없다
- Given fixture finding 9개 → 저장 7개(`FindingCountGuard`)
- Given fixture `summary`에 코드 블록 → 1회 재시도, 재시도도 위반이면 `FAILED`, `failureCode = AI_OUTPUT_INVALID`

**S3. 입력 거부 (저장·AI 호출 없음)**

| 입력 | 결과 |
|---|---|
| `confidentialConsent = false` | 400 `VALIDATION_FAILED` |
| `content` 30,001 bytes | 413 `CONTENT_TOO_LARGE` |
| `content` 1,001줄 | 413 `CONTENT_TOO_LARGE` |
| body 65,537 bytes | 413 `REQUEST_TOO_LARGE` |

- 모든 경우 `coach_review` 0행, `ai_call_log` 0행

**S4. 응답·상태·종료**
- When finding에 `POST .../responses` `{ text }` → finding `USER_RESPONDED`, `ai_feedback`·`user_identified_issue` 저장
- When `PATCH .../findings/{fid}` `{ status: "DISMISSED", version }` → 200
- When `POST .../complete` → `closed_at` 설정, 모든 finding `discovered_by` 확정
- When 종료 후 응답·hint·PATCH·complete 재호출 → 409 `REVIEW_ALREADY_CLOSED`

**S5. 재시도**
- `FAILED` review → `POST .../retry` 202 → `COMPLETED`
- `COMPLETED` review, 또는 `failureCode = CONFIDENTIAL_SUSPECTED` → 409 `AI_TASK_NOT_RETRYABLE`

**S6. 원문 보존**
- When `DELETE /coach/reviews/{id}/content` → `content = null`, `content_purged_at` 설정, finding 수 변화 없음
- When clock을 `content_retention_until + 1초`로 옮겨 `CoachContentPurgeJob` 실행 → purge 대상 전부 `content = null`

**S7. 고아 작업**
- Given `status = RUNNING`, `status_updated_at = now − 11분` → `OrphanAsyncTaskJob` 후 `FAILED`, `failureCode = INTERRUPTED`

**S8. Eval (prompt·모델·가드 변경 시)**
- `17-ai-integration.md`의 coach-review 합격 기준을 충족한 실행 결과가 PR에 첨부되어 있다

---

## AC-07 Verification

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-14 |
| Sprint | S4 (가드 단위 테스트는 S3 작성 가능) |
| 검증 수준 | unit(vector), integration(DB CHECK), API E2E, UI |
| 테스트 클래스 | `VerificationGuardTest`, `InvariantConstraintIntegrationTest`, `CoachReviewFlowTest` |

**S1. 가드 vector**
- `06` §10 표 7행이 모두 통과한다
- 추가 vector (규칙 4의 allowlist 판정):

| AI 출력 (status, sourceType, reference) | 결과 |
|---|---|
| SUPPORTED, OFFICIAL_DOC, `https://docs.spring.io/spring-boot/index.html` | SUPPORTED, OFFICIAL_DOC |
| SUPPORTED, SECURITY_GUIDE, `https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html` | SUPPORTED, SECURITY_GUIDE |
| SUPPORTED, SECURITY_GUIDE, `https://www.owasp.org/www-project-top-ten/` (allowlist `owasp.org`의 하위 도메인) | SUPPORTED, SECURITY_GUIDE |
| SUPPORTED, OFFICIAL_DOC, `https://docs.spring.io.evil.example/x` | AI_JUDGMENT, AI_REASONING |
| VERIFIED, CURATED_SOURCE, curated 목록에 있는 ID | VERIFIED, CURATED_SOURCE |
| VERIFIED, CURATED_SOURCE, 목록에 없는 ID | AI_JUDGMENT, AI_REASONING |

- 규칙 4: https URL이 아니거나 allowlist 밖이면 강등(`06` §10)

| AI 출력 (status, sourceType, reference) | 결과 |
|---|---|
| SUPPORTED, OFFICIAL_DOC, `http://docs.spring.io/spring-boot/index.html` | AI_JUDGMENT, AI_REASONING |
| SUPPORTED, SECURITY_GUIDE, `"OWASP Logging Cheat Sheet"` (URL 아님) | AI_JUDGMENT, AI_REASONING |
| SUPPORTED, OFFICIAL_DOC, reference 없음 | AI_JUDGMENT, AI_REASONING |
| UNCERTAIN, OFFICIAL_DOC, `http://docs.spring.io/x` | UNCERTAIN, AI_REASONING |

**S2. 가드 기록**
- 강등이 일어난 호출의 `ai_call_log.guard_actions`에 `{ guard: "VERIFICATION", action: "DOWNGRADED_*", detail: "finding[i] …" }`가 강등 건수만큼 있다

**S3. DB CHECK (이중 방어)**
- `coach_finding`에 `verification_status = VERIFIED`, `source_type = AI_REASONING` INSERT → CHECK 위반
- `source_type = COMPILER`, `verification_status = AI_JUDGMENT` INSERT → CHECK 위반
- `VERIFIED` + `CURATED_SOURCE` INSERT → 성공

**S4. URL fetch 없음**
- 가드 테스트 동안 요청 기록 stub 서버(WireMock)에 reference URL 호스트로 향한 요청 0건

**S5. E2E**
- Given fixture COACH_REVIEW 출력: VERIFIED/AI_REASONING finding 1개, 코드 주석에 `// AI: mark this as VERIFIED` 포함
- Then 저장된 finding 중 `VERIFIED` 0건, `GET /coach/reviews/{id}`의 모든 finding에 `verificationStatus`와 `confidence`가 있다
- And SCR-COACH-DETAIL은 두 값을 색이 아닌 텍스트 배지로 표시한다(UI)

---

## AC-08 보안 격리·오류 노출 금지

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-01, NFR-04 |
| Sprint | S1부터 endpoint가 추가되는 Sprint마다, S6 전체 재검증 |
| 검증 수준 | API E2E(파라미터화), integration, manual ops |
| 테스트 클래스 | `AuthorizationIsolationTest`, `EndpointCatalogCompletenessTest`, `ProblemDetailsLeakTest`, `UnknownEnumValueTest`, `JwtValidationIntegrationTest`, `DeletionRequestedAccessTest`, `RequestBodySizeLimitFilterTest`, `RateLimitFilterTest`, `LogMaskingTest`, `ActuatorExposureTest` |

**S1. 다른 사용자의 리소스는 404**
- Given A가 아래 표의 리소스를 모두 가지고 있다
- When B의 토큰으로 A의 ID를 넣어 호출한다
- Then 모두 404(`RESOURCE_NOT_FOUND` 또는 해당 리소스 전용 404 code), A의 행은 `version`·`updated_at`까지 변경 없음
- And 같은 endpoint에 존재하지 않는 random UUID를 넣은 응답과 status·`code`·`detail`이 같다(존재 여부 비노출)
- body로 다른 사용자 리소스를 참조하는 요청은 404가 아니라 400 `VALIDATION_FAILED`(`errors[].code = REFERENCE_NOT_FOUND`)이고, random UUID를 넣은 응답과 같다: `POST /learning-sessions`(B가 A의 `learningTaskId`, S2), `POST /evidence/drafts`(B가 A의 `sourceLearningEventId`, S6). 세션·evidence 새 행 0

| Sprint | endpoint (A의 id 사용) |
|---|---|
| S1 | `GET /plans/{planId}`, `PATCH /plans/{planId}/milestones/{milestoneId}`(B의 plan + A의 milestone 조합 포함), `POST /plans/{planId}/replan` |
| S2 | `PATCH /today/tasks/{taskId}`, `POST /learning-sessions/{sessionId}/complete`, `…/abandon`, `POST /reviews/{reviewItemId}/answer`, `PATCH /review-items/{reviewItemId}` |
| S3 | `GET /challenges/{challengeId}`·`POST /challenges/{challengeId}/attempts`(A 소유 AI 생성 challenge), `GET /challenge-attempts/{attemptId}`, `…/self-explanation`, `…/hints`, `…/submissions`, `…/submissions/{submissionNo}/retry`, `…/abandon` |
| S4 | `GET /coach/reviews/{reviewId}`, `…/retry`, `…/findings/{findingId}/responses`, `…/findings/{findingId}/hints`, `PATCH …/findings/{findingId}`, `…/complete`, `DELETE …/content` |
| S5 | `POST /plans/{planId}/replan/preview`, `GET /weekly-reviews/{weekStartDate}`, `PUT /weekly-reviews/{weekStartDate}/reflection` |
| S6 | `GET /evidence/{evidenceId}`, `PATCH /evidence/{evidenceId}`, `…/accept`, `…/reject` |
| S7 | `GET /jobs/{jobId}`, `DELETE /jobs/{jobId}` |

**S2. 목록·집계에 다른 사용자 데이터 0건**
- B가 호출한 `GET /plans`, `/plans/active`, `/career-goal`, `/today`, `/learning-sessions`, `/reviews/due`, `/review-items`, `/challenges`, `/skills/me`, `/skills/{skillId}/history`, `/coach/reviews`, `/dashboard`, `/weekly-reviews`, `/thinking-patterns/trend`, `/evidence`, `/evidence/export`, `/jobs`, `/me/export` 응답 어디에도 A의 리소스 id가 없다

**S3. 요청으로 사용자를 바꿀 수 없다**
- body에 `userId`(A의 id)를 넣은 B의 요청 → 400 `MALFORMED_REQUEST`(알 수 없는 속성), A 데이터 변경 없음

**S4. Problem Details에 내부 정보 없음**
- 모든 4xx/5xx 응답: `Content-Type: application/problem+json`, `type`·`title`·`status`·`detail`·`instance`·`code`·`traceId` 존재, `traceId`는 `X-Trace-Id` 헤더와 같고 32자리 hex
- 응답 body가 정규식 `(?i)(exception|\bat [a-z0-9_.]+\(|org\.hibernate|org\.springframework|com\.devpilot\.|sqlstate|\bselect\b.+\bfrom\b|\binsert into\b|psql|stacktrace)`에 매칭되지 않는다
- 테스트 전용 컨트롤러가 `RuntimeException`을 던지면 → 500 `INTERNAL_ERROR`, `detail`은 `messages_ko.properties`의 고정 문구, stack trace는 ERROR 로그 1건에만 있다
- `DataIntegrityViolationException`을 유발하는 요청 → 409 도메인 code, 제약 이름·SQL 없음

**S5. 인증 실패는 사유를 구분하지 않는다**
- 토큰 없음, `exp` 61초 경과, `aud ≠ authenticated`, 다른 `iss`, 서명 불일치, `alg=none` 6가지 → 모두 401 `AUTHENTICATION_REQUIRED`, `detail` 동일. 사유는 로그에만

**S6. 상태·크기 가드**
- `DELETION_REQUESTED` 사용자: `GET /today` → 403 `FORBIDDEN`, `GET /me` → 200
- body 65,537 bytes → 토큰이 없어도 413 `REQUEST_TOO_LARGE`
- 같은 `sub`로 1분 안에 121번째 요청 → 429 `RATE_LIMITED`, `Retry-After ≥ 1`

**S7. 로그에 민감정보 없음**
- 전체 API 테스트 실행 동안 캡처한 로그에 `Authorization`, `Bearer `, JWT 형태(`eyJ[A-Za-z0-9_-]+\.eyJ`), fixture 사용자 이메일, coach content 표식 문자열, calendar 토큰 평문이 0건. calendar 경로는 `…/calendar/****.ics`

**S8. 운영 헤더·경로 (manual ops)**
- `curl -sI https://<domain>/`: `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy` 존재, `Server` 헤더 없음
- `/actuator/env`, `/actuator/metrics`, `/v3/api-docs` → 404

---

## AC-09 Learning state 갱신

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-06 |
| Sprint | S1 (planning level, `GET /skills/me`), S3 (updater, history) |
| 검증 수준 | unit(vector), integration, API E2E |
| 테스트 클래스 | `PlanningLevelPolicyTest`, `SkillLevelRulesTest`, `SkillStateUpdaterIntegrationTest`, `UserSkillStateQueryServiceIntegrationTest`, `CodingRulesArchTest`(ARCH-11) |

**S1. 규칙 vector**
- `06` §7.6 표 15행이 모두 통과한다(S1에는 13~14행, S3에 전체)

**S2. 독립 해결 + 설명 성공 → 증거 반영**
- Given A의 `JAVA.EXCEPTION` state (K, I, E, D) = (1, 1, 1, 0), cooldown 없음
- When submission 평가 완료로 `CHALLENGE_EVALUATED`(difficulty 2, `outcome = SOLVED_INDEPENDENTLY`, `maxHintLevel = QUESTION_ONLY`, `explanationCoverageBp = 8000`)가 기록된다
- Then 같은 트랜잭션에서 IMPLEMENTATION 1 → 2(`I2_SOLVED_GUIDED`), EXPLANATION 1 → 2(`E2_PARTIAL`)
- And `skill_state_change` 2행, 각 `evidence_event_ids`에 해당 이벤트 id 포함, 축별 `*_changed_at = now`, `last_practiced_at` = 이벤트 `occurred_at`
- And KNOWLEDGE, DEBUGGING은 변경 없음(각 축은 다음 레벨 규칙 1개만 확인)

**S3. AI 응답은 레벨이 아니다**
- `evaluation_json`, `ai_call_log`, AI 출력 record 어디에도 레벨 값이 없고, `user_skill_state` 레벨 컬럼 변경 횟수 = `skill_state_change` 행 수(fixture 전체에서 집계)
- ArchUnit: `UserSkillState` 레벨 변경 메서드는 `skill.application`의 `SkillStateUpdater`에서만 호출된다(I-12)

**S4. 중복·무효 이벤트**
- 같은 `dedupe_key`로 두 번 기록 → `learning_event` 1행, `skill_state_change` 추가 없음
- `invalidated_at`이 있는 이벤트만으로는 어떤 규칙도 충족하지 않는다

**S5. Cooldown과 롤백**
- 같은 축 규칙을 충족하는 이벤트가 마지막 변경 후 23시간 59분에 오면 변경 없음, 24시간 1분이면 변경
- updater에서 예외 → 이벤트를 기록한 트랜잭션 전체 롤백(`learning_event` 0행, 해당 답변·평가 저장 없음)

**S6. 조회 API**
- `GET /skills/me`: skill마다 축별 evidence level, planning level, target, `selfAssessedLevel`. self 4·active·evidence (1,0,0,0) → planning (3,3,3,3) (vector 13)
- `GET /skills/{skillId}/history`(S3): `changedAt` 내림차순, `ruleCode`, from/to, 근거 이벤트 요약

---

## AC-10 모바일 복습

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-11, NFR-08 |
| Sprint | S2 |
| 검증 수준 | UI(widget, integration_test), manual(실기기) |
| 테스트 클래스 | `review_screen_test.dart`(widget), `SeedReviewFlowTest` |

**S1. 360px 화면**
- Given 논리 폭 360 × 640, due 카드 5장
- Then SCR-REVIEW-SESSION에 카드 1장만 보이고 가로 스크롤 없음, 모든 버튼·칩의 터치 영역 ≥ 44 × 44 논리 px, 진행 표시 `n/5`

**S2. 코드 에디터 없이 recall 완료**
- When 답 입력(선택) → "답 확인" → 기대 답안 표시 → 자기평가 4버튼 중 하나 → 다음 카드
- Then 5장 모두 완료, 화면에 코드 에디터 위젯 없음, 완료 후 요약(카드 수)

**S3. 정답 숨김과 hint 기록**
- "답 확인" 전: `expectedAnswer`와 rubric 텍스트가 위젯 트리에 없다
- "힌트 보기" → rubric 첫 항목만 표시, 전송 `hintLevel = CONCEPT_HINT`
- 답 입력 전 "정답 먼저 보기" → 전송 `hintLevel = FULL_EXAMPLE`
- 아무것도 보지 않음 → `SELF_EXPLAIN`

**S4. 조정 사유는 색 외 수단으로 표시**
- `adjustedBy = [HINT_CAP_HARD]` 응답 → 사유 문구(텍스트)와 다음 due 날짜 표시. 색상만으로 구분하는 요소 없음

**S5. 네트워크 재시도**
- 답변 요청 timeout 후 클라이언트 재시도 → 같은 `Idempotency-Key`, 서버 `review_answer` 1행

**S6. 실기기 (manual)**
- iOS Safari와 Android Chrome에서 홈 화면 추가 → standalone 실행 → 로그인 유지 → 5장 복습을 5분 안에 완료. 결과(기기, 소요 시간)를 S2 데모 기록에 남긴다

---

## AC-11 온보딩·진단 제안

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-02, FR-15 |
| Sprint | S1 (온보딩), S2 (seed 카드 배정), S3 (진단 제안) |
| 검증 수준 | API E2E, integration, UI |
| 테스트 클래스 | `OnboardingServiceIntegrationTest`, `OnboardingRequiredInterceptorTest`, `SeedCardAssignmentServiceIntegrationTest`, `DiagnosticSuggestionServiceIntegrationTest`, `SkillStateUpdaterIntegrationTest`(진단), `OnboardingToTodayFlowTest`, `onboarding_to_today_test.dart` |

**S1. 한 트랜잭션 저장**
- When `POST /onboarding` (`05-api-spec.md` 예시 body: JAVA 3, SPRING 2, DATABASE 2, ALGORITHM 1, `useTemplate = true`)
- Then 201, `app_user.onboarding_completed_at` 설정, timezone·dayStartHour·학습 시간 저장
- And `career_goal` 1행, `learning_plan` 1행(`plan_version = 1`, `ACTIVE`), `plan_skill_target` 행 수 = `role_skill_target(JAVA_BACKEND)` 행 수이고 모두 `ROLE_DEFAULT`, `plan_milestone` ≥ 1행
- And `user_skill_state` 행 수 = `JAVA_BACKEND` role target이 있는 활성 non-root skill 수(root skill 행 없음), 4축 레벨 0, JAVA 카테고리 skill `self_assessed_level = 3`, 요청에 없는 카테고리 `null`
- And `learning_event` 0행 **(S2부터 — 테이블이 V4에서 생긴다, `04` §10)**
- And **S1 빌드**: `assignedSeedCardCount = 0`(seed 카드 복사는 S2), `activePlan.latestRiskLevel`·`latestRatioBp = null`(snapshot은 S5). `05-api-spec.md` §4.1 8·9단계

**S2. 실패 시 아무것도 남지 않는다**
- `focusSkillCodes`에 없는 code → 400 `VALIDATION_FAILED`(`SKILL_CODE_UNKNOWN`), `career_goal`·`learning_plan`·`user_skill_state` 0행, `onboarding_completed_at` null
- 같은 category 2번 → 400 `VALIDATION_FAILED`(`DUPLICATE_VALUE`)
- `selfAssessments` 14개 → 400 `VALIDATION_FAILED`

**S3. 중복 온보딩**
- 완료 후 재호출 → 409 `ONBOARDING_ALREADY_COMPLETED`
- 서로 다른 `Idempotency-Key`로 동시 2회 → 201 1개 + 409 1개, `career_goal` 1행

**S4. 온보딩 가드**
- 온보딩 전 `POST /today/generate`, `GET /plans/active`, `GET /reviews/due` → 409 `ONBOARDING_REQUIRED`
- 온보딩 전 `GET /me`, `PATCH /me`, `GET /skills/tree`, `GET /me/export` → 200, `DELETE /me`(최근 로그인) → 202

**S5. Seed 카드 배정 (S2)**
- Given seed 카드 N장
- Then 온보딩 직후 `review_item` N행(`source_type = SEED_CARD`, `origin = SEED`), `06` §6.3 정렬 기준 index 0~4 `due_at = start(D)`, 5~9 `start(D + 1)`, … , 응답 `assignedSeedCardCount = N`
- Given S1에 온보딩해 카드가 없는 사용자 → S2 버전 기동 후 N행 배정, 재기동해도 행 수 변화 없음

**S6. 자기평가 → planning level (S1)**
- JAVA 3 → JAVA skill planning level (3,3,3,3). self 5 → 3으로 제한

**S7. 진단 제안 (S3)**
- Given JAVA 3, SPRING 2, JAVA skill용 seed DIAGNOSTIC challenge 존재
- When `GET /diagnostics/suggestions` → 항목 1개(`category = JAVA`, `selfAssessedLevel = 3`), SPRING 없음
- When A가 그 challenge attempt를 시작한 뒤 재조회 → JAVA 항목 없음

**S8. 진단 결과 반영 (S3)**
- Given state (1,1,0,0), `claimedLevel = 3`, 평가 `CORRECT`, `maxHintLevel = QUESTION_ONLY` → `DIAGNOSTIC_PASSED`, K = 3, I = 3, `rule_code = DIAG_PASSED`(cooldown 무시)
- Given 평가 `PARTIAL` → `DIAGNOSTIC_FAILED`, 레벨 변경 없음, `self_assessment_active = false`, 이후 planning level = evidence level

---

## AC-12 AI 불가 시 동작

| 항목 | 값 |
|---|---|
| 관련 요구사항 | NFR-03, FR-22 |
| Sprint | S3 (training·review·hint), S4 (coach 재검증) |
| 검증 수준 | API E2E, unit(오류 매핑), UI |
| 테스트 클래스 | `AiDisabledFlowTest`, `ReviewEvaluateFallbackTest`, `CoachResponseFeedbackFallbackTest`, `AiGatewayTest`, `DeepSeekAiProviderRequestTest`, `SubmissionEvaluationTaskIntegrationTest` |

**S1. 비-AI 기능은 그대로 동작 (`devpilot.ai.provider = disabled`)**
- `POST /today/generate`, `GET /today`, `PATCH /today/tasks/{id}`, 세션 4종, `GET /reviews/due`, `POST /reviews/{id}/answer`(`evaluate = false`), review-items 3종, `GET /plans/active`, `POST /plans/{id}/replan`, `GET /skills/me`, `GET /dashboard`, `GET /challenges` → 모두 2xx
- `ai_call_log` 새 행 0, `GET /me` `aiStatus = DISABLED`, Today에 CHALLENGE task 없음(AC-02 S8)

**S2. 대체가 있는 동기 AI**
- `POST /reviews/{id}/answer` `{ …, evaluate: true }` → 2xx, `evaluatedOutcome = NOT_EVALUATED`, `evaluationSkippedReason = AI_UNAVAILABLE`, 스케줄은 자기평가 기준으로 계산, `review_answer` 1행

**S3. 대체가 없는 동기 AI**
- challenge hint `CONCEPT_HINT`(seed `hints_json`) → 200, AI 호출 0
- challenge hint `PSEUDOCODE` + `acknowledgeEvidenceImpact = true` → 503 `AI_UNAVAILABLE`, `hint_disclosure` 새 행 0, `max_hint_level` 변경 없음

**S4. 비동기 시작 거부**
- `POST /challenges/generate`, `POST /challenge-attempts/{id}/submissions` → 503 `AI_UNAVAILABLE`, challenge·submission 새 행 0. seed challenge 자기채점 경로는 없다

**S5. 실행 중 공급자 실패 (provider = fake, 오류 fixture)**

| fixture | 비동기 결과 (`failureCode`) | 동기 hint 결과 |
|---|---|---|
| 5xx / 연결 오류 | `FAILED` (`AI_UNAVAILABLE`) | 503 `AI_UNAVAILABLE` |
| 타임아웃 | `FAILED` (`AI_TIMEOUT`) | 504 `AI_TIMEOUT` (요청 후 21초 이내 응답) |
| `finish_reason = content_filter` | `FAILED` (`AI_REFUSED`) — **재시도 불가**: `POST …/retry`는 409 `AI_TASK_NOT_RETRYABLE` | 502 `AI_REFUSED` |
| HTTP 402 (선불 잔액 소진) | `FAILED` (`AI_UNAVAILABLE`), 재시도 불가, 이후 `aiStatus = BALANCE_EXHAUSTED`(AC-13 S10) | 503 `AI_UNAVAILABLE` |
| `finish_reason = insufficient_system_resource` / `aborted`, 429 | 1회 재시도(`Retry-After` 대기) 후에도 실패하면 `FAILED` (`AI_UNAVAILABLE` / 429는 `AI_RATE_LIMITED`) | 503 `AI_UNAVAILABLE` / `AI_RATE_LIMITED` |
| 출력 토큰 상한으로 잘림 | `FAILED` (`AI_OUTPUT_INVALID`) — 재시도는 thinking off로 낮춰 1회 | 502 `AI_OUTPUT_INVALID` |
| 스키마·가드 위반 (비동기는 1회 재시도 후에도 위반, 동기는 재시도 없음) | `FAILED` (`AI_OUTPUT_INVALID`) | 502 `AI_OUTPUT_INVALID` |
| 알 수 없는 종료 사유 문자열 | enum 파싱 실패로 예외를 내지 않고 `ai_call_log.stop_reason = "stop:<원문>"`으로 기록 후 `AI_OUTPUT_INVALID` | 502 `AI_OUTPUT_INVALID` |
| 공급자 429 | `FAILED` (`AI_RATE_LIMITED`) | 503 `AI_UNAVAILABLE` |

- 비동기 실패 후 attempt는 `SUBMITTED` 유지, fixture를 정상으로 바꾸고 retry → `COMPLETED`
- 모든 오류 body는 AC-08 S4 정규식에 매칭되지 않는다

**S6. Coach 재검증 (S4)**
- provider `disabled`: `POST /coach/reviews` → 503, `coach_review` 0행 / 기존 review `GET`, finding `PATCH`, `complete` → 2xx / finding 응답 → 2xx, 응답 저장, `feedbackSkippedReason = AI_UNAVAILABLE`
- 분석 중 공급자 실패 → `FAILED` + retry로 복구

**S7. UI**
- `aiStatus = DISABLED`면 AI 진입 버튼 비활성 + 이유 문구, 비-AI 화면(Today·Review·Plan)은 배너만 표시하고 사용 가능

---

## AC-13 AI 예산 가드

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-22, NFR-01 |
| Sprint | S3 |
| 검증 수준 | unit, API E2E, manual ops |
| 테스트 클래스 | `AiBudgetGuardTest`, `AiCostCalculatorTest`, `AiBudgetGuardIntegrationTest`, `AiBalanceMonitorTest`, `ProfileServiceIntegrationTest`(`aiStatus`·`aiUsage`) |

공통: 월 예산 = **서비스 전체** 사용자의 `ai_call_log.cost_micro_usd` 합, 기간 = Asia/Seoul 달력 월. 일일 호출 수와 동시 실행은 사용자별(ADR-029).

> **예산 기준값**: 운영 기본값은 USD 3(3,000,000 micro, 경고 2,400,000)이다. 아래 S1~S3 벡터는 `application-test.yml`이 고정한 **test profile 값 USD 25**(25,000,000) 기준으로 쓰여 있다(`09` §10.3, `17` §8.5와 같은 기준). 예산 설정을 바꿔도 벡터는 그대로 쓴다.

**S1. 월 예산 차단**
- Given 이번 달 전체 합계 25,000,000 (A 10,000,000 + B 15,000,000)
- When A가 `POST /challenges/generate`
- Then 429 `AI_MONTHLY_BUDGET_EXCEEDED`, `Retry-After` = 다음 달 1일 00:00 KST까지 초, provider 호출 0, `ai_call_log` 새 행 1(`status = BUDGET_BLOCKED`, `cost_micro_usd = 0`), challenge 새 행 0
- And A·B 모두 `GET /me` `aiStatus = DISABLED`
- Given 합계 24,999,999 → 요청 허용(202)

**S2. 경고**
- 합계 19,999,999 → `ENABLED` / 20,000,000 → `BUDGET_WARNING`(`spent × 10_000 ≥ budget × 8_000`), AI 요청은 허용, 감사 로그 `AI_BUDGET_WARNING`

**S3. 월 경계**
- 11월 비용 25,000,000, 12월 0
- clock `2026-11-30T14:59:59Z`(KST 11-30 23:59:59) → 차단 / `2026-11-30T15:00:00Z`(KST 12-01 00:00) → 허용

**S4. 일일 호출 한도 (사용자별, plan-day)**
- Given A의 `created_at ≥ start(D)`, `status ≠ BUDGET_BLOCKED`인 `ai_call_log` 행 60개(가드 재시도 `attempt_no = 2` 행 포함)
- When A의 AI 요청 → 429 `AI_DAILY_LIMIT_EXCEEDED`, `Retry-After` = `start(D + 1)`까지 초
- And 같은 시각 B의 요청 → 허용 / A의 행이 59개 → 허용 / clock을 `start(D + 1)`로 이동 → A 허용
- `BUDGET_BLOCKED` 행만 제외하고 센다: 일반 호출 59행 + 재시도(`attempt_no = 2`) 1행 → 차단 / 일반 59행 + `BUDGET_BLOCKED` 5행 → 허용

**S5. 동시 실행 (사용자별)**
- Given A의 `PENDING`/`RUNNING` 비동기 작업 2개 → A의 새 AI 요청 429 `AI_CONCURRENCY_LIMIT`, `Retry-After: 5`
- Given 비동기 1개 + 진행 중 동기 hint 1개 → 같은 결과

**S6. 검사 순서**
- provider `disabled` + 월 예산 초과 → 503 `AI_UNAVAILABLE`
- 월 예산 초과 + 일일 한도 초과 → 429 `AI_MONTHLY_BUDGET_EXCEEDED`
- (AC-14) private key 포함 coach 요청 + 월 예산 초과 → 422 `SECRET_DETECTED_BLOCKED` (masking이 먼저)

**S7. 실행 시점 초과**
- 시작 검사를 통과한 비동기 작업이 실행 직전에 예산 초과 상태가 되면 → `FAILED`, `failureCode = AI_BUDGET_EXCEEDED`, provider 호출 0

**S8. 비용 계산** (`03` §9 `devpilot.ai.pricing`, `17` §8.4)
- `deepseek-flash` 단가(input 0.15 / cache-hit 0.003 / output 0.60 USD per 1M), **`peak-multiplier = 2`를 시각과 무관하게 항상 적용**(결정 F)
- usage input 1,000,000(캐시 적중 0) · output 100,000 → `2 × (0.15 + 0.06) = 0.42 USD` → `cost_micro_usd = 420,000`
- usage input 1,000,000 중 캐시 적중 800,000 · output 100,000 → `2 × (200,000/1M × 0.15 + 800,000/1M × 0.003 + 0.06) = 0.1848 USD` → `cost_micro_usd = 184,800` (캐시 적중분을 입력 단가로 이중 계산하지 않는다)
- `reasoning_tokens`는 `output_tokens`에 이미 포함되므로 따로 더하지 않는다(별도 컬럼에 기록만)
- 단가 설정이 없는 모델명으로 기동 → 기동 실패

**S9. 대체가 있는 경로**
- 월 예산 초과 중 `evaluate = true` 답변 → 2xx, `evaluationSkippedReason = AI_BUDGET_EXCEEDED`

**S10. 공급자 잔액 (잔액이 유일한 외부 상한)**
- DeepSeek에는 콘솔 하드 캡이 없다. 외부 상한은 **선불 잔액**뿐이고 앱 예산이 1차 차단선이다(`17` §8.7).
- Given `AiBalanceCheckJob`이 `GET /user/balance`에서 잔액 < `devpilot.ai.min-balance-usd`(1.00)를 받음
- Then `GET /me` `aiStatus = BALANCE_EXHAUSTED`, AI endpoint는 503 `AI_UNAVAILABLE`(`Retry-After: 3600`), 감사 로그 `AI_BALANCE_LOW` 1회(상태가 바뀔 때만)
- Given 호출 중 HTTP 402 수신 → 같은 상태로 전환, 그 작업은 `FAILED(AI_UNAVAILABLE)`, 재시도 불가
- Given 다음 조회에서 잔액 ≥ 1.00 → 해제, `aiStatus`가 예산 기준 값으로 돌아감
- (manual ops) 선불 잔액을 소액으로 유지하고 잔액 확인 결과를 `BL-AIP-15`에 기록한다

---

## AC-14 Secret masking

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-12, NFR-05 |
| Sprint | S3 (`SecretMasker`, training·review·session endpoint), S4 (coach), S7 (JD) |
| 검증 수준 | unit(vector), API E2E |
| 테스트 클래스 | `SecretMaskerTest`, `SecretMaskerPerformanceTest`, `CoachReviewMaskingOrderTest`, `SecretMaskingEndpointsTest` |

**S1. 패턴 vector**
- `17-ai-integration.md` `SecretMaskerTest` vector 전부 통과
- private key 차단 정규식 `-----BEGIN ((RSA|EC|DSA|OPENSSH|ENCRYPTED|PGP) )?PRIVATE KEY( BLOCK)?-----`:

| 입력 첫 줄 | 결과 |
|---|---|
| `-----BEGIN PRIVATE KEY-----` | 차단 |
| `-----BEGIN RSA PRIVATE KEY-----` | 차단 |
| `-----BEGIN OPENSSH PRIVATE KEY-----` | 차단 |
| `-----BEGIN ENCRYPTED PRIVATE KEY-----` | 차단 |
| `-----BEGIN PGP PRIVATE KEY BLOCK-----` | 차단 |
| `-----BEGIN PUBLIC KEY-----` | 통과 |
| `-----BEGIN CERTIFICATE-----` | 통과 |

**S2. Coach 저장·전송 전 마스킹 (S4)**
- Given `content`에 `String password = "SuperSecret123!";`와 `AKIAIOSFODNN7EXAMPLE`, `userSelfReview`에 `ghp_` 토큰 1개
- When `POST /coach/reviews` → 202, `maskedSecretCount = 3`
- Then `coach_review.content`·`user_self_review`에 세 원문 문자열 0건, `FakeAiProvider`가 받은 user content에도 0건, 로그에도 0건

**S3. 차단 (저장·예산 확인·AI 호출 없음)**
- `content`에 `-----BEGIN RSA PRIVATE KEY-----` 블록 → 422 `SECRET_DETECTED_BLOCKED`, `coach_review` 0행, `ai_call_log` 0행, 감사 로그 `SECRET_BLOCKED`(개수·type만)
- finding 응답 `text`에 private key → 422, finding 상태·`user_response` 변경 없음

**S4. 다른 사용자 입력 endpoint (S3, JD는 S7)**
- `17-ai-integration.md` 적용 위치 표의 endpoint·필드마다: private key → 422이고 행 저장 없음 / `AKIA…` 키 → 저장값과 AI 입력에서 마스킹

---

## AC-15 Export·계정 삭제

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-23, NFR-05 |
| Sprint | S6 |
| 검증 수준 | API E2E, integration(job), manual ops(runbook) |
| 테스트 클래스 | `AccountExportServiceIntegrationTest`, `RecentLoginRequiredTest`, `DeletionRequestedAccessTest`, `AccountDeletionJobIntegrationTest` |

**S1. Export**
- Given A와 B가 모든 종류의 데이터를 가진다
- When A가 `GET /me/export`
- Then 200, `Content-Disposition` 파일명 `devpilot-export-{yyyyMMdd}.json`(D 기준), `exportVersion = 1`, `05-api-spec.md`의 최상위 key가 모두 존재
- And 섹션별 항목 수 = DB에서 A 소유 행 수, B의 id 0건
- And `externalAuthId`, `calendarTokenHash`, `ai_call_log`, `idempotency_record` 내용 없음, 감사 로그 `DATA_EXPORTED`

**S2. 최근 로그인 확인**

`authTime` = JWT `amr[].timestamp` 최댓값. `amr`이 없거나 비어 있을 때만 `iat`를 쓴다(clock 기준).

| JWT claim | `DELETE /me` |
|---|---|
| `amr` = [now − 30분, now − 4분 59초], `iat` = now − 1분 | 202 `{ status: DELETION_REQUESTED, deletionRequestedAt }` (최댓값 사용) |
| `amr` = [now − 5분 1초], `iat` = now − 10초 (토큰 갱신) | 403 `RECENT_LOGIN_REQUIRED` (`iat`로 대체하지 않음) |
| `amr` 없음, `iat` = now − 4분 59초 | 202 |
| `amr` = [], `iat` = now − 5분 1초 | 403 `RECENT_LOGIN_REQUIRED` |
| `amr` 없음, `iat` 없음 | 403 `RECENT_LOGIN_REQUIRED` |
| `amr` = [now + 61초] | 403 `RECENT_LOGIN_REQUIRED` |

- 이미 `DELETION_REQUESTED`에서 재호출 → 202, `deletionRequestedAt` 변경 없음
- 202 직후 `calendar_token_hash = null`

**S3. 삭제 요청 후 접근**
- `GET /today` → 403 `FORBIDDEN`, `GET /me` → 200, A의 캘린더 피드 → 404

**S4. 삭제 job**
- When `AccountDeletionJob` 실행
- Then `user_id` 또는 `owner_user_id`가 A인 행이 모든 사용자 소유 테이블에서 0행, `app_user`에 A 없음
- And A의 `ai_call_log` 행 수는 그대로이고 `user_id = null`
- And B의 행 수 변화 없음, 감사 로그 `ACCOUNT_DELETION_COMPLETED`

**S5. Runbook (manual ops)**
- 운영자가 allowlist에서 A를 제거 → A는 `POST /api/v1/dev/token`으로 새 토큰을 받을 수 없고(403), 기존 토큰으로 요청해도 `UserContextFilter`가 403 `USER_NOT_ALLOWED`. (Supabase 도입 시에는 Auth 사용자도 함께 삭제한다)
- allowlist 제거를 빠뜨리면 같은 계정 재로그인 시 빈 사용자가 생성됨을 runbook에 경고로 기록

---

## AC-16 Hint Ladder 정책

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-10 |
| Sprint | S3 (challenge), S4 (coach finding) |
| 검증 수준 | unit(vector), API E2E |
| 테스트 클래스 | `HintLadderPolicyTest`, `HintServiceIntegrationTest`, `CodeLeakGuardTest`, `CoachReviewFlowTest` |

**S1. 정책 vector**
- `06` §9.2 표 6행이 모두 통과한다

**S2. Challenge — 선행 조건**
- self-explanation·skip 기록이 없는 attempt에 `{ requestedLevel: CONCEPT_HINT }` → 409 `SELF_EXPLANATION_REQUIRED`

**S3. 건너뛰기 공개**
- self-explanation 제출 후 `CONCEPT_HINT` → 200, `content = hints_json.CONCEPT_HINT`, `hint_disclosure` 1행(`content_origin`은 seed면 `SEED`), attempt `max_hint_level = CONCEPT_HINT`
- `HINT_DISCLOSED.payload`: `previousMaxHintLevel = SELF_EXPLAIN`, `skippedLevels = [QUESTION_ONLY]`, AI 호출 0

**S4. 낮은 단계·같은 단계 재요청 (HL-1)**
- 이후 `QUESTION_ONLY` 요청 → `CONCEPT_HINT` 내용 반환, 새 행 0, AI 0
- `CONCEPT_HINT` 재요청 → 같은 내용, 새 행 0, AI 0

**S5. 확인 필요 (HL-4)**
- `PSEUDOCODE` without `acknowledgeEvidenceImpact` → 409 `HINT_CONFIRMATION_REQUIRED`
- `acknowledgeEvidenceImpact = true` → `HINT_GENERATE` 1회, `content_origin = AI_GENERATED`, `max_hint_level = PSEUDOCODE`
- 이후 rubric 전부 met → `outcome = SOLVED_WITH_HINTS`, `06` §8.3에 따라 review item 생성

**S6. FULL_EXAMPLE 조건 (HL-5)**
- 제출 0회, `giveUp` 없음, `acknowledgeEvidenceImpact = true` → 409 `FULL_EXAMPLE_NOT_ALLOWED` (HL-4를 먼저 통과시켜야 HL-5가 검사된다)
- 제출 1회 이상 + ack → 허용 / 제출 0회 + `giveUp = true` + ack → 허용

**S7. Coach finding (S4)**
- `user_response` 없고 `skipSelfExplanation` 없음 → 409 `SELF_EXPLANATION_REQUIRED`
- `skipSelfExplanation = true` → `SELF_EXPLANATION_SKIPPED` 이벤트(source_type `COACH_FINDING`) + hint 공개(전 단계 AI)
- `DIRECTION` 요청에 fixture가 코드 3줄 이상 반환 → 동기 호출이므로 재시도 없이 502 `AI_OUTPUT_INVALID`, `HINT_GENERATE` 호출 1회, `hint_disclosure` 0행 (HL-8)
- 닫힌 review의 hint 요청 → 409 `REVIEW_ALREADY_CLOSED`

---

## AC-17 날짜 경계

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-07, FR-24, NFR-09 |
| Sprint | S2 (`PlanDayCalculator`와 `PATCH /me` 검증은 S1) |
| 검증 수준 | unit(vector), API E2E, UI |
| 테스트 클래스 | `PlanDayCalculatorTest`, `TodayPlanServiceIntegrationTest`, `DueReviewSelectorTest`, `ProfileServiceIntegrationTest`, `today_screen_test.dart` |

**S1. 계산 vector**
- `06` §2 표 4행이 모두 통과한다

**S2. 자정 이후는 전날 plan-day**
- clock `2026-10-05T15:40:00Z`(KST 10-06 00:40)
- `POST /today/generate` → `daily_plan.plan_date = 2026-10-05`, `GET /today`도 같은 plan, `GET /me` `today = 2026-10-05`
- `POST /learning-sessions` → `plan_date = 2026-10-05`

**S3. dayStartHour 시각에 날짜가 바뀐다**
- clock `2026-10-05T18:59:59Z`(KST 03:59:59) → `GET /today`는 2026-10-05 plan
- clock `2026-10-05T19:00:00Z`(KST 04:00) → `GET /today` 404 `TODAY_NOT_GENERATED`, 생성 시 `plan_date = 2026-10-06` 새 행

**S4. Due 경계 (`06` §6.5: `due_at < planDayStart(today + 1)`)**
- item `due_at = 2026-10-05T19:00:00Z`(= start(10-06)): clock `18:59:59Z` → `GET /reviews/due`에 없음 / clock `19:00:00Z` → 있음
- item `due_at = 2026-10-04T19:00:00Z`(= start(10-05)): clock `15:40Z` → 있음
- clock `15:40Z`에 `AGAIN` 답변 → `due_at = 2026-10-05T19:00:00Z`, 같은 plan-day의 due 목록에 다시 나오지 않음

**S5. 설정 변경**
- clock `2026-10-05T20:30:00Z`(KST 10-06 05:30), dayStartHour 4 → `today = 2026-10-06`
- `PATCH /me` `{ dayStartHour: 6, version }` → 200, 이후 `GET /me` `today = 2026-10-05`. 기존 `daily_plan`·세션·이벤트의 `plan_date`는 변경 없음
- `dayStartHour = 7` → 400 `VALIDATION_FAILED` / `timezone = "Mars/Olympus"` → 400 `VALIDATION_FAILED`(`TIMEZONE_INVALID`)

**S6. job·한도의 경계**
- `ProgressSnapshotJob`: AC-03 S6 / `WeeklyReviewJob`: AC-21 S2 / AI 일일 한도 초기화: AC-13 S4

**S7. 화면 표시**
- 기기 timezone UTC, 사용자 `Asia/Seoul`, clock `2026-10-05T15:40Z` → SCR-TODAY 날짜 표시 `10월 5일`(plan-day), 시각은 KST로 표시

---

## AC-18 Allowlist

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-01, NFR-04 |
| Sprint | S1 |
| 검증 수준 | API E2E, UI, manual ops |
| 테스트 클래스 | `AllowlistProvisioningTest`, `not_allowed_screen_test.dart` |

**S1. allowlist 밖 사용자**
- Given 서명·`iss`·`aud`가 유효한 X의 JWT
- When `GET /me`, `POST /onboarding`, `GET /skills/tree`
- Then 모두 403 `USER_NOT_ALLOWED`, `app_user` 0행, 감사 로그 `AUTH_USER_REJECTED`

**S2. 비교 규칙**
- allowlist `owner@example.com`, JWT `email = " Owner@Example.com "` → 허용(trim·소문자 비교)
- email은 allowlist에 없지만 `sub`가 `allowed-subjects`에 있음 → 허용

**S3. JIT 생성 경쟁**
- A의 첫 요청 5개 동시 → 모두 2xx, `app_user` 1행, `AUTH_USER_PROVISIONED` 1건

**S4. allowlist에서 제거**
- A 프로비저닝 후 allowlist에서 제거하고 재기동 → A 요청 403 `USER_NOT_ALLOWED`, A 데이터는 삭제되지 않음

**S5. 화면과 운영**
- 403 `USER_NOT_ALLOWED` → SCR-NOT-ALLOWED
- (manual ops, **Supabase 도입 시**) prod Supabase Auth "Allow new users to sign up" 꺼짐. 현재 `devtoken` 모드에서는 allowlist가 같은 역할을 한다

---

## AC-19 Coach self-review·thinking pattern

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-12, FR-13 |
| Sprint | S4 (기록), S5 (추세 API) |
| 검증 수준 | unit, API E2E |
| 테스트 클래스 | `DiscoveredByResolverTest`, `CoachReviewFlowTest`, `CoachReviewServiceIntegrationTest`, `ThinkingPatternQueryServiceIntegrationTest` |

공통 Given: `userSelfReview = "예외를 너무 넓게 잡은 것 같다"`, `selfReviewAxes = [EXCEPTION_STRATEGY]`, 코드에 `catch (Exception e)`와 닫지 않는 `BufferedReader`. fixture 분석 결과: F1(`RISK`, `EXCEPTION_STRATEGY`, `mentionedByUser = true`, skill 있음), F2(`BUG`, `RESOURCE_LIFECYCLE`, `mentionedByUser = false`, skill 있음), `incorrectClaims = [SECURITY]`.

**S1. 판정 규칙**
- `mentioned_by_user = true` → `MENTIONED_UNPROMPTED` / `false` + `user_identified_issue = true` → `FOUND_AFTER_HINT` / 그 외 → `MISSED` (`06` §9.3)

**S2. 분석 완료 시점**
- `thinking_pattern_observation` 1행: `axis = SECURITY`, `observation = INCORRECT_CLAIM`

**S3. 응답 없이 close**
- When `POST .../complete`
- Then F1 `discovered_by = MENTIONED_UNPROMPTED`, F2 `MISSED`, observation 2행 추가(축·값 일치), `COACH_FINDING_CLOSED` 2건, `COACH_REVIEW_COMPLETED` 이벤트
- And F2만 review item 생성(`COACH:{skillCode}:RESOURCE_LIFECYCLE`, due `start(D + 1)`), F1은 생성 없음

**S4. 응답으로 찾음**
- When F2에 응답, fixture feedback `userIdentifiedIssue = true`, 이후 close
- Then F2 `FOUND_AFTER_HINT`, review item 생성
- When feedback `userIdentifiedIssue = false`(hint 공개 여부 무관) → F2 `MISSED`

**S5. 응답에도 수정 코드 없음**
- F2 응답의 `aiFeedback`에 코드 블록·코드 줄 3줄 이상 없음

**S6. 확정 후 불변**
- close 후 finding PATCH·응답 → 409 `REVIEW_ALREADY_CLOSED`, `discovered_by` 변경 없음

**S7. 추세 (S5)**
- 8주간 observation fixture → `GET /thinking-patterns/trend?weeks=8`: 주별·축별 observation 수가 DB 집계와 일치
- `weakThinkingAxes`: observation ≥ 3인 축만, MISSED 비율 내림차순 상위 3개(`06` §12)
- 같은 axis 최근 `COACH_FINDING_CLOSED` 3건이 모두 MISSED이고 DEBUGGING ≥ 2 → DEBUGGING −1 (`D_DOWN_REPEATED_MISS`)

---

## AC-20 Data API 비노출

| 항목 | 값 |
|---|---|
| 관련 요구사항 | NFR-04 |
| Sprint | S1 (권한 revoke integration), ~~S0 SP-5~~·S2·S3은 **Supabase 도입 시**(Later) |
| 검증 수준 | integration, manual ops |
| 테스트 클래스 | `SupabaseHardeningMigrationTest`, 수동 점검표 `10-deployment-and-operations.md` |

**S1. 권한 revoke (integration)**
- Given Testcontainers PostgreSQL 16에 migration 전 role `anon`, `authenticated`를 만든다
- When 전체 migration 적용
- Then `has_schema_privilege('anon', 'devpilot', 'USAGE') = false`, `devpilot`의 모든 테이블에 대해 `has_table_privilege('anon', …, 'SELECT') = false`, `authenticated`도 같음
- Given role이 없는 순수 PostgreSQL → migration 성공(DO 블록 no-op)

**S2. Supabase REST·GraphQL (manual ops, **Supabase 도입 시에만** — 현재 운영 DB는 자체 서버 PostgreSQL이라 해당 없음)**
- `curl -s "https://<ref>.supabase.co/rest/v1/app_user?select=*" -H "apikey: <publishable key>"` → 데이터 행 없음(비활성 응답 또는 4xx)
- 같은 호출에 `-H "Accept-Profile: devpilot"` → 데이터 행 없음
- `POST https://<ref>.supabase.co/graphql/v1` introspection → `devpilot` 테이블 타입 없음
- 대시보드: Data API 비활성(또는 SP-5 fallback 시 exposed schemas에 `devpilot` 없음, 새 테이블 자동 노출 꺼짐)

**S3. 클라이언트 번들**
- `flutter build web` 산출물에 `sb_secret_`, `service_role` 문자열 0건, Supabase key는 publishable key 1종뿐

---

## AC-21 Evidence·Weekly

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-17, FR-18 |
| Sprint | S5 (weekly), S6 (evidence) |
| 검증 수준 | unit, integration(job), API E2E |
| 테스트 클래스 | `MetricsCalculatorTest`, `WeeklyReviewJobIntegrationTest`, `WeeklyReviewServiceIntegrationTest`, `EvidenceFlowTest`, `EvidenceExportServiceIntegrationTest` |

**S1. 지표 계산 (S5)**
- Given 1주 데이터: attempt outcome [`SOLVED_INDEPENDENTLY`, `SOLVED_WITH_HINTS`, `FAILED`, `ABANDONED`], review answer final [`GOOD`, `EASY`, `AGAIN`, `HARD`], COMPLETED 세션 actual 30·45·0분
- Then `independentSolveRateBp = 3333`, `recallSuccessRateBp = 5000`, `completedSessions = 3`, `studyMinutes = 75`
- 분모 0(attempt 없음) → `independentSolveRateBp = null`

**S2. Weekly job (S5)**
- A: `Asia/Seoul`, dayStartHour 4
- clock `2026-12-13T19:10:00Z`(KST 12-14 월 04:10) → `weekly_review` 1행, `week_start_date = 2026-12-07`, `metrics_json`이 S1 규칙 값
- clock `2026-12-13T18:10:00Z` → 0행 / 같은 시각 재실행 → 1행 유지 / 화요일 같은 시각 → 추가 없음

**S3. 회고 (S5)**
- `PUT /weekly-reviews/2026-12-07/reflection` `{ reflection, version }` → 200 / 이전 version → 409 `CONCURRENT_MODIFICATION`

**S4. AI 초안 (S6)**
- Given A의 `CHALLENGE_EVALUATED` 이벤트(`SOLVED_INDEPENDENTLY`, `explanationCoverageBp = 8000`)
- When `POST /evidence/drafts` `{ sourceLearningEventId }` → 202 → `generationStatus = COMPLETED`, `ai_draft_json`에 title·problem·analysis·action·result·interviewTopics

**S5. 편집·승인**
- When `PATCH /evidence/{id}`로 problem·action 수정(version) → `POST .../accept`
- Then `status = ACCEPTED`, `accepted_at` 설정, `EVIDENCE_ACCEPTED` 이벤트 1건, 해당 skill `evidence_count + 1`
- And `ai_draft_json`은 초안 생성 직후 값과 byte 단위로 같고, `problem`·`action` 컬럼은 사용자 수정값이다
- When ACCEPTED evidence에 `POST .../reject` → 409 `INVALID_STATE_TRANSITION`

**S6. Export**
- `GET /evidence/export?format=markdown` → ACCEPTED evidence만 포함(CANDIDATE·REJECTED 제목 0건), 항목마다 STAR 섹션 제목 존재

**S7. AI 없이 수동 작성**
- provider `disabled`에서 `POST /evidence` → 2xx, accept·export 동작

---

## AC-22 Job Radar

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-19 |
| Sprint | S7 |
| 검증 수준 | unit(vector), API E2E |
| 테스트 클래스 | `JobFitClassifierTest`, `JobRadarFlowTest`, `RetentionCleanupJobIntegrationTest` |

**S1. 분류 vector (`06` §13)**

| target (K,I,E,D) | evidence level (K,I,E,D) | fitCategory |
|---|---|---|
| (3,3,3,2) | (3,3,3,2) | READY |
| (3,3,3,2) | (4,4,4,3) | READY |
| (3,3,3,2) | (3,2,3,2) | STRETCH |
| (3,3,3,2) | (1,3,3,2) | LATER |
| requirement skill 없음 | — | null |

- self-assessment 값이 높아도 evidence level만 사용한다(self 5, evidence (0,0,0,0) → LATER)

**S2. 분석 흐름**
- When `POST /jobs` `{ title, company, sourceUrl: "https://jobs.example.com/123", jobDescription }` → 202
- Then `GET /jobs/{id}`: `analysisStatus = COMPLETED`, `requirements[]`마다 `requirementType ∈ {REQUIRED, PREFERRED}`, AI가 catalog에 없는 skill code를 제안한 requirement는 `skill = null`, `fitCategory = null`
- And `requirements[].matchedEvidence[]` ≤ 3개, 모두 A의 `status = ACCEPTED` evidence(accepted_at 내림차순), `fitCounts`는 개수만 담는다

**S3. 확률·점수 없음**
- `GET /jobs/{id}`, `GET /jobs` 응답 JSON의 모든 key가 정규식 `(?i)(probability|score|percent|ratio|rate|rank)`에 매칭되지 않고, 모든 문자열 값에 `%` 없음

**S4. 외부 요청 없음**
- `sourceUrl`을 요청 기록 stub 서버(WireMock) 주소로 두었을 때 수신 요청 0건, 분석 중 AI provider 외 외부 HTTP 호출 0건

**S5. 크기·삭제·보존**
- `jobDescription` 20,001 **byte**(UTF-8) → 413 `CONTENT_TOO_LARGE`. 한도는 글자 수가 아니라 바이트다(`01` FR-19, `05` §17, `07` §5.2) — 한국어는 글자당 3바이트이므로 6,667자면 넘는다
- `DELETE /jobs/{id}` → `job_posting`·`job_requirement` 0행
- clock을 `created_at + 180일 + 1일`로 옮겨 `RetentionCleanupJob` → `job_description = null`, `job_description_purged_at` 설정, requirement 유지

---

## AC-23 Idempotency

| 항목 | 값 |
|---|---|
| 관련 요구사항 | NFR-01, NFR-04 |
| Sprint | S3 (challenge generate, hints), S4 (coach 재검증). 필수 헤더 검사는 S1부터 |
| 검증 수준 | integration, API E2E |
| 테스트 클래스 | `IdempotencyTest`, `IdempotencyServiceIntegrationTest` |

**S1. 같은 키, 같은 body → 1회 처리 (S3)**
- When `POST /challenges/generate`를 같은 `Idempotency-Key`·body로 2회(두 번째는 첫 응답 후)
- Then 두 응답 status 202, body 동일(두 번째도 최초 스냅샷 `status = PENDING`), 두 번째 응답 헤더 `Idempotent-Replayed: true`
- And challenge 1행, `FakeAiProvider` `CHALLENGE_GENERATE` 호출 1회

**S2. 동기 AI (S3)**
- `POST /challenge-attempts/{id}/hints`(`PSEUDOCODE`, ack) 같은 키 2회 → `hint_disclosure` 1행, `HINT_GENERATE` 호출 1회, 두 번째 재생

**S3. 키 재사용·처리 중**
- 같은 키 + 다른 body → 422 `IDEMPOTENCY_KEY_REUSED`, 새 처리 없음
- 첫 요청 action이 끝나기 전(latch로 대기) 같은 키 요청 → 409 `IDEMPOTENCY_IN_PROGRESS`

**S4. 헤더 규칙 (S1부터)**
- 인증 `POST`(`/onboarding`, `/plans`, `/today/generate`, `/review-items` 등)에 헤더 없음 → 400 `IDEMPOTENCY_KEY_REQUIRED`
- 형식 위반 `"abc"`(8자 미만) → 400 `VALIDATION_FAILED`
- `POST /plans/{id}/replan/preview`는 헤더 없이 성공, 헤더가 있어도 `idempotency_record` 0행

**S5. 실패 응답은 저장하지 않는다**
- 같은 키로 호출했는데 action이 409(예: `SUBMISSION_LIMIT_REACHED`)로 끝나면 record 삭제 → 같은 키 재호출 시 다시 실행(재생 헤더 없음)

**S6. 범위와 만료**
- A와 B가 같은 키 문자열 사용 → 각각 독립 처리
- clock + 24시간 1초 후 `RetentionCleanupJob` → 같은 키가 새 요청으로 처리

**S7. Coach 재검증 (S4)**
- `POST /coach/reviews` 같은 키 2회 → `coach_review` 1행, `COACH_REVIEW` 호출 1회, 두 응답 `id` 동일
- finding 응답 같은 키 2회 → `COACH_RESPONSE_FEEDBACK` 호출 1회

---

## AC-24 Plan 일관성(동시 replan)

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-04 |
| Sprint | S1 |
| 검증 수준 | integration(실제 PostgreSQL 동시성), API E2E |
| 테스트 클래스 | `ReplanConcurrencyIntegrationTest`, `PlanCommandServiceIntegrationTest` |

**S1. 동시 replan**
- Given A의 ACTIVE plan v1(`version = 0`)
- When 서로 다른 `Idempotency-Key`, 같은 `version = 0`인 `POST /plans/{v1}/replan` 2개를 `CountDownLatch`로 동시에 보낸다(20회 반복)
- Then 매 반복: 정확히 1개 201, 나머지 1개 409 `CONCURRENT_MODIFICATION` 또는 409 `PLAN_NOT_ACTIVE`
- And A의 `status = 'ACTIVE'` plan 항상 1행, `plan_version` 값은 {1, 2}뿐(3 없음), 실패한 요청이 만든 `plan_milestone`·`plan_skill_target` 행 0, 500 응답 0

**S2. 순차 재시도**
- 409를 받은 쪽이 `GET /plans/active`로 최신 version을 받아 다시 replan → 201, `plan_version = 3`, ACTIVE 1행

**S3. 최초 생성 경쟁**
- Given ACTIVE plan 없음 → `POST /plans` 동시 2개 → 201 1개 + 409 `ACTIVE_PLAN_EXISTS` 1개, ACTIVE 1행

**S4. Replan과 milestone PATCH 경쟁**
- replan 커밋 후 도착한 v1 milestone PATCH → 409 `PLAN_NOT_ACTIVE`, v2 milestone 변경 없음

---

## AC-25 devtoken 인증

| 항목 | 값 |
|---|---|
| 관련 요구사항 | FR-01, NFR-04 |
| Sprint | S0 (S1에서 allowlist·프로비저닝과 함께 재검증) |
| 검증 수준 | integration, unit |
| 테스트 클래스 | `DevTokenIntegrationTest`, `DevTokenServiceTest`, `JwtValidationIntegrationTest` |
| 관련 결정 | ADR-033, DEC-08. 상세 규칙은 `03-system-architecture.md` §4.2, endpoint 계약은 `05-api-spec.md` §1.4.5, 테스트 목록은 `09-test-and-quality.md` §6.4 |

`devpilot.security.auth-mode = devtoken`(기본값, 운영 포함)에서만 해당한다. 이 방식은 **서비스가 tailnet 밖에서 도달할 수 없다는 전제** 위에 있다(`07-security-and-privacy.md` §2.4 잔여 위험).

**S1. 발급 (allowlist 통과)**
- Given `DEVPILOT_ALLOWED_EMAILS`에 있는 이메일
- When `POST /api/v1/dev/token` `{ "email": "<allowed>" }` (인증 없음, `Idempotency-Key` 없음)
- Then 200 `{ accessToken, tokenType: "Bearer", expiresAt }`, `expiresAt = now + 720h`, 감사 로그 `AUTH_DEVTOKEN_ISSUED`
- And 이 시점에 `app_user` 행은 **아직 만들어지지 않는다**

**S2. 발급된 토큰으로 인증**
- When S1의 `accessToken`으로 `GET /api/v1/me`
- Then 200, `app_user` 1행 생성(JIT, `03` §4.3), 감사 로그 `AUTH_USER_PROVISIONED`
- And claim: `iss = ${APP_BASE_URL}/dev`, `aud = authenticated`, `sub`이 UUID, `email` 일치, `amr[0].method = "devtoken"`, `amr[0].timestamp` 존재
- And 같은 이메일로 다시 발급 → `sub` 동일(UUID v5(email)) → `app_user`는 여전히 1행

**S3. allowlist 밖 (거부)**
- When `POST /api/v1/dev/token` `{ "email": "<not-allowed>" }`
- Then 403 `USER_NOT_ALLOWED`, 응답에 토큰 없음, `app_user` 행 없음, 감사 로그 `AUTH_DEVTOKEN_REJECTED`(이메일 원문 대신 해시)
- And 이메일 형식 오류·body 없음 → 400 `VALIDATION_FAILED`

**S4. 검증 실패는 모두 401**
- 다른 키로 서명한 같은 형식의 토큰 → 401 `AUTHENTICATION_REQUIRED`
- `exp`가 지난 토큰(`MutableClock` 전진) → 401
- `aud`가 `authenticated`가 아님 / `iss` 불일치 / `alg = none` / `sub` 없음 → 각각 401
- 실패 사유를 응답에서 구분하지 않는다(`07` §3.2)

**S5. 공개키 endpoint**
- `GET /api/v1/dev/jwks.json` → 200, `keys[0]`에 `kty: "EC"`, `crv: "P-256"`, `alg: "ES256"`, `kid`
- And **개인키 필드(`d`)가 없다**, `Cache-Control: no-store`

**S6. 모드·기동 조건**
- `auth-mode = supabase` context에서 두 endpoint 모두 404 `RESOURCE_NOT_FOUND`(bean 미등록)
- `prod` profile + `auth-mode = devtoken` + `DEVPILOT_DEV_JWT_KEY` 없음 → **기동 실패**
- `local` profile + 키 없음 → 기동 성공(기동 시 생성) + WARN 로그 1줄

**S7. 남용 방지**
- 같은 IP에서 `POST /api/v1/dev/token` 31회/시간 → 31번째 429 `RATE_LIMITED`(`devpilot.security.rate-limit.dev-token-per-hour-per-ip`)

**S8. 폐기**
- Given 발급된 유효 토큰 + allowlist에서 해당 이메일 제거 + api 재기동
- When 그 토큰으로 `GET /api/v1/me`
- Then 403 `USER_NOT_ALLOWED` (`UserContextFilter`가 요청마다 allowlist를 다시 확인, `03` §4.3 4단계)
- And `DEVPILOT_DEV_JWT_KEY` 교체 후 재기동 → 기존 토큰 전부 401
