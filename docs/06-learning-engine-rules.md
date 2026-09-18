# 06. Learning Engine Rules

> Status: Accepted (v2) · Last updated: 2026-09-18 · Related: ADR-008, ADR-009, ADR-017, ADR-018, `04-domain-model-and-db.md`
>
> Planner, study budget, deadline risk, 복습 스케줄, skill 레벨 갱신, attempt 판정, Hint Ladder, verification guard, 계획 버전, 지표의 **결정적 규칙**이다. 이 문서의 모든 규칙은 AI 없이 동작한다.
>
> - 숫자(가중치, 임계값, 간격)는 **초기 기본값**이다. 코드에 하드코딩하지 않고 `devpilot.*` 설정으로 둔다(`03-system-architecture.md` §9). 4주 사용 후 조정한다.
> - 규칙을 구현하는 클래스는 Spring/JPA에 의존하지 않는 순수 Java다. 이름은 `03` §3.2를 따른다.
> - **Test vectors는 그대로 `@ParameterizedTest` 케이스로 옮긴다.** 모든 vector를 통과해야 완료다.

---

## 1. 수치 규약 (결정성)

| 규약 | 내용 |
|---|---|
| N-1 | **부동소수점(`double`, `float`)을 규칙 계산에 쓰지 않는다.** 정수(`long`)만 쓴다 |
| N-2 | 비율은 basis point(bp): `1.0 = 10_000` |
| N-3 | 점수와 factor는 micro: `1.0 = 1_000_000` |
| N-4 | 나눗셈은 명시한 함수만 쓴다: `floorDiv(a, b)`, `ceilDiv(a, b)`, `roundHalfUpDiv(a, b) = floorDiv(2a + b, 2b)` (a, b ≥ 0) |
| N-5 | 곱셈 modifier 적용: `score = floorDiv(score × multiplierBp, 10_000)` |
| N-6 | 설정의 소수 값(예: `0.25`)은 기동 시 bp/micro 정수로 변환한다. 변환 결과가 정수가 아니면 기동 실패 |
| N-7 | 오버플로 방지를 위해 중간값은 `long`, 곱셈은 `Math.multiplyExact` |

---

## 2. Plan-day (날짜 경계)

```text
planDate(now, zone, dayStartHour)  = now.atZone(zone).toLocalDateTime().minusHours(dayStartHour).toLocalDate()   # 벽시계 기준
planDayStart(date, zone, dayStartHour) = date.atTime(dayStartHour, 0).atZone(zone).toInstant()
```

- 모든 "오늘"은 plan-day다. 서버는 주입된 `Clock`만 사용한다.
- **벽시계 기준**이다: 현지 시각이 `dayStartHour`시 이전이면 전날이다. DST가 있는 timezone에서도 이 정의를 따른다(instant 기준 `ZonedDateTime.minusHours`를 쓰지 않는다). `planDayStart`에서 현지 시각이 DST로 건너뛰어 존재하지 않으면 `atZone`의 기본 규칙(뒤로 밀림)을 따른다.
- `daysBetween(a, b)` = `ChronoUnit.DAYS.between(a, b)` (LocalDate 기준)

**Test vectors** (`Asia/Seoul`, dayStartHour=4)

| now (KST) | planDate | planDayStart(planDate) (UTC) |
|---|---|---|
| 2026-10-05 23:30 | 2026-10-05 | 2026-10-04T19:00:00Z |
| 2026-10-06 00:40 | 2026-10-05 | 2026-10-04T19:00:00Z |
| 2026-10-06 03:59 | 2026-10-05 | 2026-10-04T19:00:00Z |
| 2026-10-06 04:00 | 2026-10-06 | 2026-10-05T19:00:00Z |

DST vector (`America/New_York`, dayStartHour=4, 2026-03-08 02:00 EST→03:00 EDT 전환일): now = 2026-03-08T08:30:00Z (현지 04:30 EDT) → planDate **2026-03-08** (instant 기준으로 계산하면 03-07이 되므로 구분된다)

---

## 3. Study Budget (`StudyBudgetCalculator`)

### 3.1 Horizon

```text
horizonDate = (applicationStartDate != null && applicationStartDate > today) ? applicationStartDate
                                                                             : targetCompletionDate
```

### 3.2 Nominal budget

```text
nominalMinutes = Σ_{d = today .. horizonDate − 1} (d is SAT/SUN ? weekendStudyMinutes : weekdayStudyMinutes)
horizonDate ≤ today → nominalMinutes = 0
```
오늘도 포함한다. 공휴일은 반영하지 않는다(Later).

### 3.3 Completion rate

```text
window = plan-day [today − 28, today − 1]
days   = window 안에서 daily_plan이 존재하는 plan-day 수
Σavail = 그 날들의 daily_plan.available_minutes 합
Σactual = window 안 COMPLETED learning_session.actual_minutes 합 (plan_date 기준)

if days < 14 or Σavail == 0 → completionRateBp = 7_000
else completionRateBp = clamp(floorDiv(Σactual × 10_000, Σavail), 3_000, 10_000)

effectiveMinutes = floorDiv(nominalMinutes × completionRateBp, 10_000)
```

**Test vectors**

| 조건 | 결과 |
|---|---|
| 평일 45 / 주말 240, today=2026-10-05(월), horizon=2026-10-12, 기록 없음 | nominal 705, rate 7000, effective **493** |
| nominal 90, 기록 없음 | effective **63** |
| days 20, Σavail 1500, Σactual 600 | rate **4000** |
| days 20, Σavail 1500, Σactual 1650 | rate **10000** (clamp) |
| days 20, Σavail 1500, Σactual 300 | rate **3000** (clamp, 원값 2000) |
| days 13, Σavail 1000, Σactual 1000 | rate **7000** (기록 부족) |
| horizon = today | nominal 0, effective 0 |

---

## 4. Required Minutes · Deadline Risk (`DeadlineRiskEvaluator`)

### 4.1 대상

- 활성 plan의 `plan_skill_target` 중 `deferred=false`이고 skill이 `active=true`인 항목
- milestone의 단계(준비/지원)와 무관하게 모든 MUST 항목을 horizon(지원 시작일)까지의 필요 시간으로 계산한다. 지원을 시작할 때 이미 증거가 있어야 한다는 원칙 때문이다.
- `requiredMust`: priority=MUST 합계, `requiredShould`: priority=SHOULD 합계. LATER는 계산하지 않는다.

### 4.2 Skill별 필요 시간

```text
AXIS_COST_BP   = { KNOWLEDGE: 5_000, IMPLEMENTATION: 10_000, EXPLANATION: 4_000, DEBUGGING: 8_000 }
REVIEW_OVERHEAD_BP = 11_500

weightedGap = Σ_axis max(0, target_axis − planningLevel_axis) × AXIS_COST_BP[axis]
requiredMinutes(skill) = ceilDiv(weightedGap × minutesPerLevelStep × REVIEW_OVERHEAD_BP, 100_000_000)
```
`planningLevel`은 §7.5를 따른다.

**Test vectors**

| target (K,I,E,D) | planning (K,I,E,D) | step | weightedGap | required |
|---|---|---|---|---|
| (4,4,4,3) | (2,1,3,3) | 120 | 2×5000+3×10000+1×4000 = 44,000 | ceil(607.2) = **608** |
| (3,3,3,2) | (3,3,3,2) | 150 | 0 | **0** |
| (4,4,3,3) | (0,0,0,0) | 90 | 4×5000+4×10000+3×4000+3×8000 = 96,000 | ceil(993.6) = **994** |

### 4.3 Risk level

```text
if requiredMust == 0          → LOW
else if effective == 0        → CRITICAL
else if requiredMust × 10_000 ≤ effective × 8_000   → LOW
else if requiredMust × 10_000 ≤ effective × 10_000  → MEDIUM
else if requiredMust × 10_000 ≤ effective × 12_500  → HIGH
else                                                → CRITICAL

ratioBp (저장·표시용) = effective == 0 ? null : floorDiv(requiredMust × 10_000, effective)
```

**Test vectors**

| requiredMust | effective | risk | ratioBp |
|---|---|---|---|
| 400 | 500 | LOW | 8000 |
| 450 | 500 | MEDIUM | 9000 |
| 500 | 500 | MEDIUM | 10000 |
| 600 | 500 | HIGH | 12000 |
| 625 | 500 | HIGH | 12500 |
| 700 | 500 | CRITICAL | 14000 |
| 10 | 0 | CRITICAL | null |
| 0 | 0 | LOW | null |

### 4.4 Replan 제안 (`ReplanSuggestionPolicy`, 자동 적용 금지)

입력은 사용자가 편집 중인 milestone 목록과 현재 `plan_skill_target`이다. 출력은 제안 목록이며 저장하지 않는다.

1. 편집안 기준으로 risk를 계산한다(§4.3, MUST 기준).
2. risk ≤ MEDIUM이면 제안하지 않는다.
3. **MUST 목표 축소 제안 (먼저)**: `requiredMust > effective`인 동안 MUST 항목을 `(careerImportance ASC, skill.code ASC)` 순서로 돌면서, 각 skill에서 target과 planning의 차이가 가장 큰 축(동점이면 K, I, E, D 순)의 target을 1 낮추는 안을 하나씩 추가한다. 축소 후 `requiredMust'`가 `≤ effective`가 되거나, 모든 MUST 항목을 한 번씩 검토하면 멈춘다. 축소 후 target은 3 미만으로 내리지 않는다(이미 3 이하인 축은 건너뛴다).
4. **SHOULD defer 제안 (그다음)**: 3단계 적용 후의 `requiredMust'`를 기준으로, SHOULD 항목을 `(careerImportance ASC, requiredMinutes DESC, skill.code ASC)` 순서로 하나씩 defer 후보에 넣는다. `requiredMust' + 남은 requiredShould ≤ effective`가 되면 멈춘다. (SHOULD를 모두 빼도 조건을 만족하지 못하면 모두 제안)
5. 응답의 risk는 **§4.3의 계산값** 그대로다. `riskAfterSuggestions`는 3단계 축소를 모두 적용한 편집안의 재계산값이다(SHOULD는 risk 계산에 들어가지 않으므로 4단계는 영향이 없다).

> 순서를 MUST 축소 → SHOULD defer로 두는 이유: risk ≥ HIGH는 `requiredMust > effective`를 뜻하므로, SHOULD defer를 먼저 돌리면 종료 조건을 만족할 수 없어 항상 SHOULD 전부가 제안된다.

**Test vector 1**: effective 5000, MUST required 5900(risk HIGH). MUST 축소 2건으로 `requiredMust'` = 4900. SHOULD = [A(importance 0.40, 480분), B(0.40, 900분), C(0.70, 300분)] → 4900 + 1680 > 5000 → defer 제안 순서 **B, A, C** (C까지 빼야 4900 ≤ 5000). `riskAfterSuggestions` = ratio 9800bp → MEDIUM.
**Test vector 2**: 같은 조건에서 SHOULD = [A(0.40, 80분), B(0.40, 120분)] → 4900 + 200 > 5000 → B defer → 4900 + 80 ≤ 5000 → 멈춤. 제안은 **B만**.

---

## 5. Daily Planner (`PlannerScoring`, `TimeAllocator`, `ReasonTemplates`)

### 5.1 입력

`today`, `availableMinutes`(5~720), `energyLevel`, 활성 plan(milestones, skill targets), planning level, due review 목록, 최근 2 plan-day의 main task, 최근 3 plan-day 세션 기록, risk level.

### 5.2 후보 skill

합집합(중복 제거):
1. 오늘이 기간에 포함된 milestone의 `milestone_skill`
2. 시작일이 오늘 이후인 가장 가까운 milestone의 `milestone_skill`
3. due review가 있는 skill
4. `plan_skill_target`에서 priority MUST/SHOULD인 skill

제외:
- `deferred=true`
- `skill.active=false` (retire된 skill)
- risk ≥ HIGH이면 priority LATER
- 모든 축에서 `planningLevel ≥ target`이고 due review가 없는 skill
- `prerequisiteReadiness < 500_000`인 skill → 대신 **준비되지 않은 prerequisite 중 planning IMPLEMENTATION이 가장 낮은 skill**(동점이면 code ASC)을 후보에 추가

후보가 하나도 없으면(모든 목표 달성 등) main task를 만들지 않는다. due review가 있으면 REVIEW task만 만들고, 응답의 `mainTask`는 `null`이다.

### 5.3 Task 제안 (`TaskProposalPolicy`)

점수를 매기기 전에 후보 skill마다 main task 제안 1개를 만든다.

```text
d = clamp(planning IMPLEMENTATION + 1, 1, 5)
if comebackMode: d = min(d, 2)

1. AI 상태가 `DISABLED`가 아니고(평가가 AI에 의존하므로), 해당 skill에 VALIDATED challenge(PRACTICE, seed 또는 본인 소유)가 있고,
   최근 14 plan-day 안에 attempt하지 않았고 **해결(outcome ∈ {SOLVED_INDEPENDENTLY, SOLVED_WITH_HINTS})한 attempt가 없는** 문제가 difficulty d, 없으면 d−1(≥1) 순서로 있으면
   → CHALLENGE (estimated = challenge.estimated_minutes, difficulty = 찾은 문제의 difficulty)
   같은 difficulty에 여러 개면 seed_key ASC(null은 뒤), 그다음 ID ASC 첫 번째
2. else if planning KNOWLEDGE < 2   → READING  (estimated 25, difficulty 1)
3. else if projectNeed && energy != LOW → PROJECT_TASK (estimated 30, difficulty 3)
4. else                               → EXPLAIN  (estimated 15, difficulty 2)
```

task 제목 템플릿:

| TaskType | title | description |
|---|---|---|
| CHALLENGE | `{challenge.title}` | challenge scenario 요약 (앞 200자) |
| READING | `{skill.name} 핵심 개념 정리` | `skill.description` + "공식 문서를 읽고 핵심 3가지를 스스로 적어 보세요." |
| PROJECT_TASK | `프로젝트에서 {skill.name} 적용 지점 찾기` | "현재 프로젝트 코드에서 이 개념이 쓰이는(또는 필요한) 곳을 찾아 이유를 적어 보세요." |
| EXPLAIN | `{skill.name} 내 말로 설명하기` | `skill.description` + "5문장 이내로 설명하고 예시를 하나 드세요." |
| RECALL | `{skill.name} 5분 떠올리기` | "자료를 보지 않고 기억나는 내용을 적어 보세요." |
| REVIEW | `복습 {n}장` | — |

### 5.4 Factor (micro, 0 ~ 1_000_000)

| factor | 계산 |
|---|---|
| `careerImportance` | `plan_skill_target.career_importance × 1_000_000` (target 없으면 `300_000`) |
| `skillGap` | `Σtarget == 0 ? 0 : floorDiv(Σ_axis max(0, target − planning) × 1_000_000, Σ_axis target)` |
| `reviewUrgency` | due 없음 → 0 / 있음 → `min(1_000_000, 300_000 + 100_000 × maxOverdueDays)`, `overdueDays = daysBetween(planDate(due_at), today)` (≥0) |
| `milestoneUrgency` | 현재 milestone skill: `length = daysBetween(start, end) + 1`, `daysLeft = daysBetween(today, end)`, `max(200_000, 1_000_000 − floorDiv(daysLeft × 1_000_000, length))` / 다음 milestone skill: `100_000` / 그 외 0 (여러 milestone이면 최댓값) |
| `projectNeed` | career goal focus skill → `1_000_000`, 아니면 0 |
| `prerequisiteReadiness` | prerequisite 없음 → `1_000_000` / 있음 → `floorDiv(count(planning IMPLEMENTATION ≥ 2) × 1_000_000, count)` |

```text
WEIGHT_BP = { careerImportance: 2500, skillGap: 2000, reviewUrgency: 2000,
              milestoneUrgency: 1500, projectNeed: 1000, prerequisiteReadiness: 1000 }
baseScore = floorDiv(Σ factor × WEIGHT_BP, 10_000)
```

### 5.5 Modifier (이 순서로 적용)

| 순서 | 조건 | multiplierBp | modifier code |
|---|---|---|---|
| 1 | risk ≥ HIGH, priority=MUST | 12_000 | `RISK_HIGH_MUST` |
| 1 | risk ≥ HIGH, priority=SHOULD | 8_000 | `RISK_HIGH_SHOULD` |
| 2 | energy=LOW, 제안 estimated > 30 또는 difficulty ≥ 4 | 7_000 | `LOW_ENERGY_DEEP_TASK` |
| 2 | energy=HIGH, difficulty ≥ 3 | 11_000 | `HIGH_ENERGY_HARD_TASK` |
| 3a | 어제 main task가 같은 skill이고 상태가 IN_PROGRESS 또는 DEFERRED | 11_500 | `CONTINUATION` (3b 적용 안 함) |
| 3b | 어제와 그제 main task가 모두 같은 skill (상태 무관) | 6_000 | `FATIGUE_TWO_DAYS` |
| 3b | 어제 main task만 같은 skill | 8_000 | `FATIGUE_ONE_DAY` |
| 4 | comebackMode, difficulty ≥ 3 | 7_000 | `COMEBACK_HARD_TASK` |

`comebackMode = (최근 3 plan-day(today−3 ~ today−1)에 COMPLETED 세션 없음) && (그 이전에 COMPLETED 세션이 1개 이상 있음)`

**동점 처리:** `finalScore DESC → careerImportance DESC → last_practiced_at ASC (null 먼저) → skill.code ASC`

### 5.6 시간 배분

```text
cap = comebackMode ? 10 : 20                        # devpilot.review.max-per-day / comeback-max-per-day
dueCount = min(due review 수, cap)
reviewMinutes = dueCount == 0 ? 0
              : min( ceilDiv(dueCount × 3, 2), max(5, floorDiv(available × 2_500, 10_000)), available − 5 )
reviewMinutes = max(0, reviewMinutes)
mainBudget = available − reviewMinutes              # 항상 ≥ 5
limit = floorDiv(mainBudget × 11_000, 10_000)       # 초과 허용 10%

선택된 후보의 제안 estimated > limit 이면:
  CHALLENGE → 같은 skill에서 difficulty를 1씩 낮춰 estimated ≤ limit인 challenge 탐색
  없으면 EXPLAIN(15)이 limit 이하면 EXPLAIN, 아니면 RECALL(estimated = min(10, mainBudget))
mainBudget < 10 이면 제안과 무관하게 RECALL(estimated = mainBudget)
```

- 점수 계산 전에 시간 조정을 하지 않는다. 먼저 1위 후보를 고른 뒤 그 후보의 task만 조정한다.
- `reviewMinutes ≥ 1`이면 REVIEW task 1개를 만든다(`is_main=false`, `estimated=reviewMinutes`, `sort_order=0`). `reviewMinutes = 0`이면(예: available 5) due가 있어도 REVIEW task를 만들지 않는다(`learning_task.estimated_minutes`는 1 이상). main은 `sort_order=1`.

**Test vectors**

| available | due | comeback | reviewMinutes | mainBudget | limit |
|---|---|---|---|---|---|
| 30 | 3 | N | min(5, 7, 25) = **5** | 25 | 27 |
| 45 | 0 | N | **0** | 45 | 49 |
| 15 | 12 | N | min(18, 5, 10) = **5** | 10 | 11 |
| 5 | 4 | N | min(6, 5, 0) = **0** | 5 | 5 → RECALL 5 |
| 120 | 40 | N | dueCount 20 → min(30, 30, 115) = **30** | 90 | 99 |
| 60 | 40 | Y | dueCount 10 → min(15, 15, 55) = **15** | 45 | 49 |

### 5.7 Planner 점수 Test vectors

공통: risk LOW, energy NORMAL, today=2026-10-10.
- **A**: MUST, importance 0.90, skillGap 600_000, due 없음, 현재 milestone(2026-10-01~2026-10-20 → daysLeft 10, length 20 → milestoneUrgency 500_000), focus 아님, prerequisite 없음, 제안 EXPLAIN(15, d2)
- **B**: SHOULD, importance 0.50, skillGap 800_000, 2일 overdue review(reviewUrgency 500_000), milestone 밖, prerequisite 없음, 제안 CHALLENGE(20, d2)

| # | 조건 | A | B | 선택 |
|---|---|---|---|---|
| 1 | 기본 | 520_000 | 485_000 | **A** |
| 2 | risk HIGH | 624_000 | 388_000 | **A** |
| 3 | A가 어제·그제 main (둘 다 COMPLETED) | 312_000 | 485_000 | **B** |
| 4 | A가 어제 main, IN_PROGRESS | 598_000 | 485_000 | **A** |
| 5 | A가 어제 main만 COMPLETED | 416_000 | 485_000 | **B** |
| 6 | energy LOW, B 제안 CHALLENGE(40분, d2) | 520_000 | 339_500 | **A** |

### 5.8 Reason (`ReasonTemplates`)

1. `factor × WEIGHT_BP` 기여도가 큰 순서로 아래 조건을 만족하는 reason을 최대 3개 고른다.
2. modifier reason(`DEADLINE_RISK_MUST`, `CONTINUE_YESTERDAY`, `LOW_ENERGY_LIGHT_TASK`, `COMEBACK_EASY_START`)은 해당 modifier가 적용되면 추가한다. 전체는 최대 3개이고, modifier reason을 우선한다.
3. 조건을 만족하는 것이 하나도 없으면 기여도 1위 factor의 code를 조건 없이 넣는다(**최소 1개 보장**, AC-02).

| ReasonCode | 조건 | 문구 |
|---|---|---|
| `MILESTONE_CORE` | 현재 milestone skill | `{milestoneTitle} milestone 핵심 항목` |
| `MILESTONE_NEXT` | 다음 milestone skill | `다음 milestone({milestoneTitle}) 준비` |
| `HIGH_CAREER_IMPORTANCE` | careerImportance ≥ 700_000 | `목표 직무에서 중요도가 높은 기술` |
| `LARGE_SKILL_GAP` | skillGap ≥ 400_000 | `목표 수준과 차이가 큼 (구현 {planningImplementation}/{targetImplementation})` |
| `REVIEW_OVERDUE` | overdue ≥ 1일 | `복습이 {overdueDays}일 밀림` |
| `RECENT_RECALL_FAILURE` | 최근 7 plan-day 안에 해당 skill review AGAIN | `최근 복습에서 기억이 흔들림` |
| `PROJECT_FOCUS` | projectNeed | `현재 프로젝트에 필요` |
| `DEADLINE_RISK_MUST` | RISK_HIGH_MUST 적용 | `마감 위험이 높아 필수 항목 우선` |
| `CONTINUE_YESTERDAY` | CONTINUATION 적용 | `어제 하던 과제 이어하기` |
| `LOW_ENERGY_LIGHT_TASK` | energy=LOW이고 선택 task estimated ≤ 30 | `컨디션에 맞춘 가벼운 과제` |
| `COMEBACK_EASY_START` | comebackMode | `다시 시작하기 좋은 쉬운 과제` |

변수 값은 선택 시점에 `score_breakdown.reasonParams`에 저장한다(`04-domain-model-and-db.md` §5.1). `overdueDays`는 상한 없이 실제 값을 저장한다.

### 5.9 재생성 (`POST /today/generate`)

| 오늘 active main 상태 | force=false | force=true |
|---|---|---|
| daily_plan 없음 | 새로 생성 | 새로 생성 |
| main `PLANNED` 또는 `SKIPPED` (active main 없음 포함) | 같은 daily_plan의 PLANNED task 삭제 → **flush** → 새 task INSERT, `generation_count+1`, 입력값 갱신 | 동일 |
| main `IN_PROGRESS` | `409 TODAY_ALREADY_STARTED` | 기존 main `DEFERRED` → PLANNED 상태 REVIEW task 삭제 → flush → 새 main·REVIEW task INSERT (REVIEW task가 IN_PROGRESS/COMPLETED면 유지하고 새로 만들지 않음) |
| main `COMPLETED` (active main 없음) | `409 TODAY_ALREADY_COMPLETED` | 추가 main INSERT (COMPLETED 유지) |

행 판정 순서(한 daily_plan에 main task가 여러 개일 수 있으므로): `IN_PROGRESS` main이 하나라도 있으면 3행 → 없고 `COMPLETED` main이 하나라도 있으면 4행 → 그 외(PLANNED·SKIPPED·DEFERRED만 있거나 main 없음)는 2행.

---

## 6. Review Scheduling (`FinalRatingPolicy`, `RuleBasedV1Scheduler`, `DueReviewSelector`)

### 6.1 최종 등급

순서: `AGAIN(0) < HARD(1) < GOOD(2) < EASY(3)`

```text
final = selfRating; adjustedBy = []
if evaluatedOutcome == INCORRECT          → final = AGAIN;          adjustedBy += EVALUATED_INCORRECT
if evaluatedOutcome == PARTIAL && final > HARD → final = HARD;      adjustedBy += EVALUATED_PARTIAL
if hintLevel ≥ PSEUDOCODE && final > AGAIN   → final = AGAIN;       adjustedBy += HINT_CAP_AGAIN
if hintLevel ∈ {CONCEPT_HINT, DIRECTION} && final > HARD → final = HARD; adjustedBy += HINT_CAP_HARD
if hintLevel == QUESTION_ONLY && final > GOOD → final = GOOD;       adjustedBy += HINT_CAP_GOOD
```
실제로 등급을 낮춘 규칙만 `adjustedBy`에 넣는다.

복습 화면의 hint 기준(클라이언트가 `hintLevel`을 보고):
- 아무것도 보지 않고 답함 → `SELF_EXPLAIN`
- "힌트 보기"(rubric 첫 항목 공개) → `CONCEPT_HINT`
- 답을 쓰기 전에 정답 보기 → `FULL_EXAMPLE`

### 6.2 간격

```text
prev = review_item.interval_days
AGAIN → 1                                   successes = 0, failures += 1
HARD  → max(2, roundHalfUpDiv(prev × 12, 10))  successes = 0          (hard-strategy=FIXED_2이면 2)
GOOD  → max(2, prev × 2)                      successes += 1, failures = 0
EASY  → max(4, prev × 3)                      successes += 1, failures = 0

interval = clamp(interval, 1, 60)
if horizonDate > answeredPlanDate:
    interval = min(interval, max(1, daysBetween(answeredPlanDate, horizonDate) − 1))
due_at = planDayStart(answeredPlanDate + interval)
review_count += 1, last_result = final, last_reviewed_at = now
```

### 6.3 신규 항목의 첫 due

| 생성 경로 | due |
|---|---|
| 온보딩 seed 카드 복사 | priority(MUST→SHOULD→LATER), careerImportance DESC, conceptKey ASC로 정렬 후 `index`번째 카드 → `planDayStart(today + floorDiv(index, 5))` (하루 5장씩 분산) |
| 신규 seed 카드 (기존 사용자) | 기존 사용자의 마지막 due 이후부터 같은 방식으로 분산 |
| challenge 실패 / coach finding / 수동 생성 | `planDayStart(today + 1)` |
| 같은 `concept_key`가 이미 있음 | 새로 만들지 않는다. `status=ACTIVE`, `due_at = min(기존 due_at, planDayStart(today + 1))` |

### 6.4 Leech · Variant (답변 처리 직후)

```text
if failures ≥ 4 (suspend-after-failures):
    status = SUSPENDED; LEECH_DETECTED 이벤트
    (planner: 최근 1 plan-day 안에 해당 skill의 LEECH_DETECTED 이벤트가 있으면 §5.4 reviewUrgency = 1_000_000 — 복습 대신 학습 task 유도)
else if failures ≥ 2 and variant_status ∈ {NONE, FAILED} and AI 사용 가능:   # Later (아래)
    variant_status = PENDING → 커밋 후 REVIEW_VARIANT 비동기 생성
if 답변이 variant 출제분이었으면: variant 필드 비우고 variant_status = NONE
```
due 목록에서는 `variant_status=READY`이면 variant 문항을 출제한다(`wasVariant=true`).

`REVIEW_VARIANT` 생성(둘째 분기)은 **Later**다(2026-09-18 범위 축소). 그 전까지 `variant_status`는 항상 `NONE`, `wasVariant=false`이며 컬럼·필드는 그대로 둔다.

### 6.5 오늘의 due 선택

```text
대상: status=ACTIVE, skill.active=true, due_at < planDayStart(today + 1)   # 오늘 plan-day가 끝나기 전까지 due (내일 시작 시각은 제외)
정렬: overdueDays DESC → priority(MUST, SHOULD, LATER, 없음) → consecutive_failures DESC → due_at ASC → id ASC
상한: cap (§5.6)
```

### 6.6 Test vectors (horizon은 충분히 멀다고 가정. 마지막 행만 예외)

| prev | selfRating | evaluated | hint | final | adjustedBy | interval |
|---|---|---|---|---|---|---|
| 1 | GOOD | NOT_EVALUATED | SELF_EXPLAIN | GOOD | [] | 2 |
| 2 | GOOD | CORRECT | SELF_EXPLAIN | GOOD | [] | 4 |
| 4 | EASY | CORRECT | QUESTION_ONLY | GOOD | [HINT_CAP_GOOD] | 8 |
| 8 | EASY | PARTIAL | SELF_EXPLAIN | HARD | [EVALUATED_PARTIAL] | 10 |
| 1 | HARD | NOT_EVALUATED | SELF_EXPLAIN | HARD | [] | 2 |
| 30 | GOOD | CORRECT | PSEUDOCODE | AGAIN | [HINT_CAP_AGAIN] | 1 |
| 5 | GOOD | INCORRECT | SELF_EXPLAIN | AGAIN | [EVALUATED_INCORRECT] | 1 |
| 3 | HARD | CORRECT | DIRECTION | HARD | [] | 4 |
| 40 | EASY | CORRECT | SELF_EXPLAIN | EASY | [] | 60 (max) |
| 10 | GOOD | CORRECT | SELF_EXPLAIN | GOOD | [] | horizon까지 5일 → **4** |

---

## 7. Skill State Updater (`SkillStateUpdater`, `SkillLevelRules`)

### 7.1 실행

- 트리거: `LearningEventRecorded`(동기, 같은 트랜잭션). 이벤트의 `skill_id`가 null이면 무시한다.
- 입력: 해당 사용자·skill의 최근 60일(`rule-window-days`) **무효화되지 않은** 이벤트와 **payload만** 사용한다(`04` §6). 다른 테이블을 조회하지 않는다.
- 처리 순서:
  1. `DIAGNOSTIC_*` 이벤트면 §7.4를 적용하고 끝낸다.
  2. 축마다 **하락 규칙**(§7.3)을 먼저 확인한다. 적용되면 그 축의 상승 규칙은 건너뛴다.
  3. 축마다 **다음 레벨(현재+1) 상승 규칙 하나만** 확인한다.
  4. cooldown: 해당 축의 `*_changed_at`이 24시간 이내면 변경하지 않는다(하락, 상승 모두).
  5. 변경마다 `skill_state_change(axis, from, to, rule_code, evidence_event_ids)`를 기록한다. `evidence_event_ids`는 조건을 만족시킨 이벤트 ID다(최대 10개, 최신순).
- `last_practiced_at` = 이벤트 `occurred_at`(최댓값). `evidence_count` = 해당 skill의 `EVIDENCE_ACCEPTED` 수
- 해당 사용자·skill의 `user_skill_state` 행이 없으면(온보딩은 role target이 있는 skill에만 행을 만든다) 레벨 (0,0,0,0), `self_assessed_level=null`로 행을 만든 뒤 규칙을 적용한다.

"독립" = `hintLevel` 또는 `maxHintLevel` ≤ `QUESTION_ONLY`
"해결" = outcome ∈ {`SOLVED_INDEPENDENTLY`, `SOLVED_WITH_HINTS`}

### 7.2 상승 규칙 (현재 레벨 → 다음 레벨)

| rule_code | 축 | → | 조건 (최근 60일, 해당 skill) |
|---|---|---|---|
| `K1_ANY_EVENT` | KNOWLEDGE | 1 | 이벤트 1개 이상 |
| `K2_RECALL_GUIDED` | KNOWLEDGE | 2 | `REVIEW_ANSWERED` finalRating ≥ HARD 이고 hintLevel ≤ CONCEPT_HINT, 2개 이상 (힌트를 보고 떠올린 회상도 인정. §6.1에서 CONCEPT_HINT는 GOOD을 HARD로 깎으므로 GOOD 조건을 두면 K3와 같아진다) |
| `K3_RECALL_INDEPENDENT` | KNOWLEDGE | 3 | `REVIEW_ANSWERED` finalRating ≥ GOOD, 독립, **3개 이상**, 서로 다른 plan_date 2일 이상, 그중 가장 최근 것의 intervalBefore ≥ 4 |
| `K4_RECALL_LONG` | KNOWLEDGE | 4 | `REVIEW_ANSWERED` finalRating ≥ GOOD, 독립, intervalBefore ≥ 14, 2개 이상 |
| `K5_TRANSFER` | KNOWLEDGE | 5 | `CHALLENGE_EVALUATED` difficulty = 5, outcome = SOLVED_INDEPENDENTLY, 1개 이상 |
| `I1_ATTEMPTED` | IMPLEMENTATION | 1 | `CHALLENGE_SUBMITTED` 1개 이상 |
| `I2_SOLVED_GUIDED` | IMPLEMENTATION | 2 | `CHALLENGE_EVALUATED` 해결, maxHintLevel ≤ PARTIAL_CODE, 1개 이상 |
| `I3_SOLVED_INDEPENDENT` | IMPLEMENTATION | 3 | `CHALLENGE_EVALUATED` SOLVED_INDEPENDENTLY, difficulty ≥ 2, 3개 이상, 서로 다른 challengeId 2개 이상 |
| `I4_PRODUCTION_LIKE` | IMPLEMENTATION | 4 | `CHALLENGE_EVALUATED` 해결, difficulty ≥ 4, maxHintLevel ≤ CONCEPT_HINT, 1개 이상 **그리고** `EVIDENCE_ACCEPTED` 1개 이상 |
| `I5_TRANSFER` | IMPLEMENTATION | 5 | `CHALLENGE_EVALUATED` SOLVED_INDEPENDENTLY, difficulty = 5, 서로 다른 challengeId 2개 이상, 그중 1개 이상 isTransfer = true |
| `E1_ANY_EXPLANATION` | EXPLANATION | 1 | `SELF_EXPLANATION_SUBMITTED` 1개 이상, 또는 `REVIEW_ANSWERED` reviewType = EXPLAIN 1개 이상 |
| `E2_PARTIAL` | EXPLANATION | 2 | coverage ≥ 4000인 설명 증거 1개 이상 |
| `E3_COVERAGE` | EXPLANATION | 3 | coverage ≥ 7000, 독립, 설명 증거 2개 이상 |
| `E4_TRANSFER_QUESTION` | EXPLANATION | 4 | coverage ≥ 8000 설명 증거 1개 이상 **그리고** `REVIEW_ANSWERED` wasVariant = true, evaluatedOutcome = CORRECT 1개 이상 |
| `E5_TRADEOFF` | EXPLANATION | 5 | `CHALLENGE_EVALUATED` difficulty = 5, explanationCoverageBp ≥ 8000, 1개 이상 |
| `D1_ANY_REVIEW` | DEBUGGING | 1 | `COACH_REVIEW_COMPLETED` 또는 `COACH_FINDING_CLOSED` 1개 이상 |
| `D2_FOUND_WITH_HINT` | DEBUGGING | 2 | `COACH_FINDING_CLOSED` discoveredBy ∈ {FOUND_AFTER_HINT, MENTIONED_UNPROMPTED}, maxHintLevel ≤ DIRECTION, 1개 이상 |
| `D3_FOUND_UNPROMPTED` | DEBUGGING | 3 | `COACH_FINDING_CLOSED` discoveredBy = MENTIONED_UNPROMPTED, findingType ∈ {BUG, RISK}, 2개 이상 |
| `D4_REPEATED_UNPROMPTED` | DEBUGGING | 4 | D3 조건 이벤트 3개 이상, 서로 다른 coachReviewId 2개 이상, 그중 confidence = HIGH 1개 이상 |
| `D5_TRANSFER` | DEBUGGING | 5 | D3 조건 이벤트의 axis 종류가 3개 이상 |

**도달 가능 상한(Sprint별, 규칙이 아니라 사실):** S3까지는 D = 0(coach는 S4), I ≤ 3(I4는 `EVIDENCE_ACCEPTED`가 필요 → S6), E ≤ 3(E4는 variant 답변이 필요 → REVIEW_VARIANT가 Later이므로 그 전까지 불가), K·I·E의 5는 difficulty 5 challenge가 필요(seed는 최대 L4, AI 생성 L5는 S3부터). UI는 정체된 레벨 옆에 다음 레벨의 조건을 보여준다(`02-user-scenarios-and-ux.md` SCR-SKILLS).

**설명 증거와 coverage:**
- `CHALLENGE_EVALUATED`의 `explanationCoverageBp` (null이면 제외)
- `REVIEW_ANSWERED` 중 reviewType = EXPLAIN이고 `rubricCoverageBp`가 있는 것

### 7.3 하락 규칙

| rule_code | 조건 | 결과 |
|---|---|---|
| `K_DOWN_RECALL_FAIL` | KNOWLEDGE ≥ 3 이고, 해당 skill의 가장 최근 `REVIEW_ANSWERED` 2개가 모두 finalRating = AGAIN이며 둘 다 최근 14 plan-day 안 | KNOWLEDGE −1 (하한 2) |
| `I_DOWN_TRANSFER_FAIL` | IMPLEMENTATION ≥ 3 이고, 방금 기록된 이벤트가 `CHALLENGE_EVALUATED` isTransfer = true, outcome = FAILED | IMPLEMENTATION −1 (하한 2) |
| `D_DOWN_REPEATED_MISS` | DEBUGGING ≥ 2 이고, 같은 axis의 가장 최근 `COACH_FINDING_CLOSED` 3개가 모두 discoveredBy = MISSED | DEBUGGING −1 (하한 1) |

하락 규칙이 적용되면 `self_assessment_active = false`로 바꾼다.

### 7.4 진단 (예외 규칙)

- `DIAGNOSTIC_PASSED`: 해당 skill의 KNOWLEDGE, IMPLEMENTATION을 `max(현재, min(claimedLevel, 3))`으로 설정한다. rule_code `DIAG_PASSED`. **1단계 제한과 cooldown을 적용하지 않는다.**
- `DIAGNOSTIC_FAILED`: 레벨은 바꾸지 않고 `self_assessment_active = false`
- 판정: challenge purpose = DIAGNOSTIC, evaluatedOutcome = CORRECT, maxHintLevel ≤ QUESTION_ONLY → PASSED. 그 외 평가 완료 → FAILED
- 진단 challenge 제안 규칙(선택 순서)은 `05-api-spec.md` §4.2가 기준이다. challenge에 skill이 여러 개면, 그 category에 속한 challenge skill 중 `(priority MUST→SHOULD→LATER→없음, careerImportance DESC, skill.code ASC)`로 가장 앞선 skill의 값을 그 challenge의 정렬 키로 쓴다. `claimedLevel`은 평가 시점 해당 skill의 `self_assessed_level`이다.

### 7.5 Planning level (`PlanningLevelPolicy`)

```text
selfCap = min(self_assessed_level ?? 0, 3)
planningLevel_axis = self_assessment_active ? max(evidenceLevel_axis, selfCap) : evidenceLevel_axis
```
- 증거 레벨이 자기평가를 넘어서면 증거 레벨을 쓴다. 이벤트가 생겼다고 해서 자기평가 값이 사라지지 않는다.
- 부정적 증거(하락 규칙, 진단 실패)가 나오면 자기평가를 더 이상 쓰지 않는다.

### 7.6 Test vectors

| # | 현재 (K,I,E,D) | 60일 이벤트 요약 | 결과 |
|---|---|---|---|
| 1 | (0,0,0,0) | REVIEW_ANSWERED GOOD 1개 | K→1 (`K1_ANY_EVENT`) |
| 2 | (1,0,0,0) | REVIEW_ANSWERED HARD(hint CONCEPT_HINT, selfRating GOOD → §6.1 HINT_CAP_HARD)×2, 마지막 K 변경 30시간 전 | K→2 (`K2_RECALL_GUIDED`) |
| 3 | (1,0,0,0) | 위와 같음, 마지막 K 변경 10시간 전 | 변경 없음 (cooldown) |
| 4 | (2,0,0,0) | 독립 GOOD×3, plan_date 모두 같은 날 | 변경 없음 (서로 다른 날 2일 조건) |
| 5 | (2,0,0,0) | 독립 GOOD×3 (10/1, 10/3, 10/7), 10/7 것 intervalBefore 4 | K→3 |
| 6 | (0,0,0,0) | CHALLENGE_EVALUATED SOLVED_WITH_HINTS(maxHint PSEUDOCODE) | K→1, I 변경 없음 (I1은 CHALLENGE_SUBMITTED 필요) |
| 7 | (1,1,0,0) | CHALLENGE_EVALUATED SOLVED_WITH_HINTS(maxHint PSEUDOCODE) | I→2 |
| 8 | (1,2,0,0) | SOLVED_INDEPENDENTLY d2 ×3, challengeId 모두 같음 | 변경 없음 |
| 9 | (3,3,2,2) | REVIEW_ANSWERED AGAIN (10/10), AGAIN (10/12) — 최근 2개 | K→2 (`K_DOWN_RECALL_FAIL`), self_assessment_active=false |
| 10 | (1,1,0,0) | SELF_EXPLANATION_SUBMITTED | E→1 |
| 11 | (1,1,1,0) | CHALLENGE_EVALUATED outcome PARTIAL, explanationCoverageBp 4500 | E→2 (I는 해결이 아니므로 변경 없음) |
| 12 | (1,1,0,1) | COACH_FINDING_CLOSED MENTIONED_UNPROMPTED RISK ×2 | D→2 (한 단계만) |
| 13 | self 4, active, evidence (1,0,0,0) | — | planning = (3,3,3,3) |
| 14 | self 4, active=false, evidence (1,0,0,0) | — | planning = (1,0,0,0) |
| 15 | (1,1,0,0), claimed 3 | DIAGNOSTIC_PASSED | K→3, I→3 (`DIAG_PASSED`, cooldown 무시) |

---

## 8. Attempt 판정 (`RubricScorer`, `AttemptOutcomeCalculator`)

### 8.1 Coverage → evaluatedOutcome

```text
rubricCoverageBp      = Σ weightBp (met = true)                               # 전체 weight 합 = 10_000
explanationCoverageBp = Σ_EXPLANATION weight == 0 ? null
                      : floorDiv(Σ weightBp(met, axis = EXPLANATION) × 10_000, Σ weightBp(axis = EXPLANATION))

evaluatedOutcome = rubricCoverageBp ≥ 8_000 → CORRECT
                 | rubricCoverageBp ≥ 4_000 → PARTIAL
                 | else                     → INCORRECT
```
복습 rubric(가중치 없음): `weightBp = floorDiv(10_000, n)`이고, 나머지 `10_000 − weightBp × n`은 첫 항목에 더한다.

### 8.2 Attempt outcome

```text
latest = 가장 최근 COMPLETED submission
if attempt.status == ABANDONED and latest == null → ABANDONED
if latest.evaluatedOutcome == CORRECT and attempt.maxHintLevel ≤ QUESTION_ONLY → SOLVED_INDEPENDENTLY
if latest.evaluatedOutcome == CORRECT                                          → SOLVED_WITH_HINTS
if latest.evaluatedOutcome == PARTIAL                                          → PARTIAL
else                                                                           → FAILED
```

### 8.3 복습 항목 생성

평가 완료 후 `outcome ∈ {FAILED, PARTIAL}`이거나 (`SOLVED_WITH_HINTS`이고 maxHintLevel ≥ PSEUDOCODE)이면 challenge의 **각 skill마다** review item을 upsert한다(§6.3).

| 필드 | 값 |
|---|---|
| concept_key | `CHALLENGE:{challengeId}` (skill이 여러 개면 `CHALLENGE:{challengeId}:{skillCode}`) |
| review_type | `EXPLAIN` |
| prompt | evaluation `followUpQuestion`이 있으면 그 문장, 없으면 `"{title}" 문제의 핵심을 설명하세요: {expectedConcepts를 ", "로 연결}` |
| expected_answer | rubric criterion들을 `- ` 목록으로 연결 |
| rubric_json | rubric criterion(id, criterion) |
| origin / source_type | `AI_GENERATED` 또는 `SEED`(seed challenge) / `CHALLENGE_ATTEMPT` |

**Test vectors**

| rubric (weightBp, axis, met) | coverage | expl. coverage | outcome (maxHint) |
|---|---|---|---|
| (4000,I,T) (4000,E,T) (2000,I,F) | 8000 | 10000 | CORRECT → SOLVED_INDEPENDENTLY (QUESTION_ONLY) |
| (4000,I,T) (4000,E,F) (2000,I,T) | 6000 | 0 | PARTIAL → PARTIAL |
| (5000,I,F) (5000,I,T) | 5000 | null | PARTIAL |
| (3000,I,T) (3000,E,F) (4000,E,F) | 3000 | 0 | INCORRECT → FAILED |
| 전부 met | 10000 | — | CORRECT → SOLVED_WITH_HINTS (CONCEPT_HINT) |
| 복습 rubric 3개, met T,F,T | weight 3334/3333/3333 → 6667 | — | PARTIAL |

---

## 9. Hint Ladder (`HintLadderPolicy`, `HintService`)

### 9.1 정책

| ID | 규칙 |
|---|---|
| HL-1 | 순서는 `HintLevel` ordinal. 요청 단계 ≤ 현재 max이면 AI를 호출하지 않는다. **요청 단계 이하에서 저장된 가장 높은 단계의 내용**을 반환하고, 그런 저장 내용이 없으면(건너뛴 단계) **저장된 가장 낮은 단계의 내용**을 반환한다(`05-api-spec.md` §10.8 4단계) |
| HL-2 | 선행 조건: challenge는 `self_explanation` 또는 `self_explanation_skipped`, coach finding은 `user_response` 존재 또는 요청의 `skipSelfExplanation=true`(이벤트 기록). 없으면 `409 SELF_EXPLANATION_REQUIRED` |
| HL-3 | 여러 단계를 한 번에 올릴 수 있다. 요청 단계만 생성·저장하고, 건너뛴 단계는 `HINT_DISCLOSED.skippedLevels`에 기록한다 |
| HL-4 | `PSEUDOCODE` 이상 요청에 `acknowledgeEvidenceImpact=true`가 없으면 `409 HINT_CONFIRMATION_REQUIRED` |
| HL-5 | `FULL_EXAMPLE`은 제출 1회 이상(challenge) 또는 `giveUp=true`일 때만 허용. 아니면 `409 FULL_EXAMPLE_NOT_ALLOWED` |
| HL-6 | 내용 출처: challenge 1~3단계는 `challenge.hints_json`(SEED/PREGENERATED), 4단계 이상과 coach finding 전 단계는 `HINT_GENERATE`(AI) |
| HL-7 | 공개할 때마다 `hint_disclosure` 행 + `HINT_DISCLOSED` 이벤트 + 대상의 `max_hint_level` 갱신 |
| HL-8 | AI 생성 hint 중 `DIRECTION` 이하 단계에 코드 블록이나 코드 줄 3줄 이상이 있으면 가드가 거절한다(`17-ai-integration.md` §6) |

### 9.2 Test vectors

| 현재 max | 요청 | 조건 | 결과 |
|---|---|---|---|
| SELF_EXPLAIN | CONCEPT_HINT | self-explanation 없음 | 409 SELF_EXPLANATION_REQUIRED |
| SELF_EXPLAIN | CONCEPT_HINT | 제출됨 | CONCEPT_HINT 공개, skippedLevels=[QUESTION_ONLY] |
| CONCEPT_HINT | QUESTION_ONLY | — | 저장된 ≤ QUESTION_ONLY 없음 → CONCEPT_HINT 내용 반환 (AI 호출 0) |
| CONCEPT_HINT | PSEUDOCODE | ack 없음 | 409 HINT_CONFIRMATION_REQUIRED |
| CONCEPT_HINT | PSEUDOCODE | ack=true | AI 생성, max=PSEUDOCODE |
| DIRECTION | FULL_EXAMPLE | ack=true, 제출 0회, giveUp 없음 | 409 FULL_EXAMPLE_NOT_ALLOWED (HL-4 확인을 먼저 검사하므로 ack가 없으면 HINT_CONFIRMATION_REQUIRED) |

### 9.3 Coach finding의 `discovered_by` 확정 (review close 시)

```text
if finding.mentioned_by_user                     → MENTIONED_UNPROMPTED
else if finding.user_identified_issue == true    → FOUND_AFTER_HINT
else                                             → MISSED
```
- finding마다 `thinking_pattern_observation(axis = category, observation = discoveredBy)`와 `COACH_FINDING_CLOSED` 이벤트를 기록한다.
- 분석 결과의 `incorrectClaims[]`(axis)는 분석 완료 시점에 `INCORRECT_CLAIM` observation으로 기록한다.
- `user_identified_issue`는 `COACH_RESPONSE_FEEDBACK` 결과다. hint를 보지 않았더라도 응답으로 문제를 짚었으면 `FOUND_AFTER_HINT`로 본다. 질문 자체가 힌트이기 때문이다.
- HL-2에서 `skipSelfExplanation=true`로 hint를 요청하면 `SELF_EXPLANATION_SKIPPED` 이벤트(source_type `COACH_FINDING`)를 기록한다.

### 9.4 Coach finding → 복습 항목 (review close 시)

`findingType ∈ {BUG, RISK}`, `skill_id` 있음, `discoveredBy ∈ {MISSED, FOUND_AFTER_HINT}`인 finding마다 review item을 upsert한다(§6.3 규칙).

| 필드 | 값 |
|---|---|
| concept_key | `COACH:{skillCode}:{category}` |
| review_type | `EXPLAIN` |
| prompt | finding `learning_question` |
| expected_answer | finding `summary` (+ `ai_feedback`이 있으면 줄바꿈 후 추가) |
| rubric_json | `[{"id": "R1", "criterion": summary}]` |
| origin / source_type / source_id | `AI_GENERATED` / `COACH_FINDING` / finding id |
| due | 다음 plan-day 시작. 이미 있으면 `min(기존 due, 다음 plan-day 시작)` |

코드 원문은 30일 후 삭제되므로 복습 문항에 코드를 넣지 않는다.

---

## 10. Verification Guard (`VerificationGuard`)

| 최종 status | 허용 source_type | 부여 방법 |
|---|---|---|
| `VERIFIED` | `COMPILER`, `TEST_RESULT`, `CURATED_SOURCE` | **서버가 실행한 도구 결과**(MVP에는 없음) 또는 `content/curated-sources.yaml`에 등록된 근거 ID |
| `SUPPORTED` | `STATIC_ANALYSIS`, `OFFICIAL_DOC`, `SECURITY_GUIDE` | STATIC_ANALYSIS는 서버 도구 실행 결과만(MVP에는 없음). OFFICIAL_DOC, SECURITY_GUIDE는 `sourceReference` URL의 호스트가 allowlist에 있을 때 |
| `AI_JUDGMENT` | `AI_REASONING` | AI 판단 |
| `UNCERTAIN` | 모두 | 맥락 부족 |

AI 출력 파싱 직후 finding마다 순서대로 적용한다.

```text
1. source_type ∈ {COMPILER, TEST_RESULT, STATIC_ANALYSIS} (AI가 주장했지만 서버 도구 실행 기록이 없음)
     → source_type = AI_REASONING, status = (status == UNCERTAIN ? UNCERTAIN : AI_JUDGMENT), action DOWNGRADED_TOOL_CLAIM
2. source_type == CURATED_SOURCE이고 sourceReference가 curated ID 목록에 없음
     → source_type = AI_REASONING, status = AI_JUDGMENT, action DOWNGRADED_UNKNOWN_CURATED
3. status == VERIFIED이고 source_type != CURATED_SOURCE
     → status = AI_JUDGMENT (source_type이 OFFICIAL_DOC/SECURITY_GUIDE이고 규칙 4를 통과하면 SUPPORTED), action DOWNGRADED_VERIFIED
4. source_type ∈ {OFFICIAL_DOC, SECURITY_GUIDE}
     → sourceReference가 https URL이 아니거나(null, 문자열 설명, http 포함) 호스트가 allowlist(정확 일치 또는 하위 도메인)가 아니면
        source_type = AI_REASONING, status = (status == UNCERTAIN ? UNCERTAIN : AI_JUDGMENT), action DOWNGRADED_UNTRUSTED_SOURCE
5. status == SUPPORTED이고 source_type == AI_REASONING → status = AI_JUDGMENT, action DOWNGRADED_SUPPORTED_WITHOUT_SOURCE
```

- **서버는 URL을 fetch하지 않는다.** 호스트 문자열만 검사한다.
- allowlist (`devpilot.ai.trusted-source-hosts`): `docs.spring.io`, `spring.io`, `docs.oracle.com`, `openjdk.org`, `www.postgresql.org`, `owasp.org`, `cheatsheetseries.owasp.org`, `www.kisa.or.kr`, `supabase.com`, `dart.dev`, `docs.flutter.dev`, `api.flutter.dev`, `pmd.github.io`, `spotbugs.readthedocs.io`, `checkstyle.org`, `junit.org`, `hibernate.org`, `docs.jboss.org`, `developer.mozilla.org`, `www.rfc-editor.org`
- DB CHECK로 이중 방어한다(`schema.sql` coach_finding).

**Test vectors**

| AI 출력 (status, sourceType, reference) | 결과 |
|---|---|
| VERIFIED, AI_REASONING, — | AI_JUDGMENT, AI_REASONING |
| SUPPORTED, STATIC_ANALYSIS, "PMD CloseResource" | AI_JUDGMENT, AI_REASONING |
| SUPPORTED, OFFICIAL_DOC, `https://pmd.github.io/pmd/pmd_rules_java_errorprone.html#closeresource` | SUPPORTED, OFFICIAL_DOC |
| VERIFIED, OFFICIAL_DOC, `https://docs.spring.io/...` | SUPPORTED, OFFICIAL_DOC |
| SUPPORTED, OFFICIAL_DOC, `https://blog.example.com/...` | AI_JUDGMENT, AI_REASONING |
| UNCERTAIN, COMPILER, — | UNCERTAIN, AI_REASONING |
| SUPPORTED, AI_REASONING, — | AI_JUDGMENT, AI_REASONING |

---

## 11. Plan Versioning (`PlanCommandService`, `ReplanService`)

### 11.1 변경 분류

| 변경 | 처리 |
|---|---|
| milestone `status`, `description`, `sortOrder` | in-place PATCH (`version` 필수) |
| milestone 추가·삭제, 날짜·priority·skill 구성 변경, skill target defer/축소 | **새 plan version** (`POST /plans/{id}/replan`) |
| career goal 날짜 변경 | career goal 즉시 저장 + 활성 plan `replan_recommended = true` |

### 11.2 Replan 절차 (한 트랜잭션)

```text
1. 대상 plan 조회 (userId 조건, status = ACTIVE 아니면 409 PLAN_NOT_ACTIVE, version 불일치면 409 CONCURRENT_MODIFICATION)
2. 요청 검증: milestone 날짜 범위, skillCodes 존재, 최대 24개
3. old.status = SUPERSEDED, old.superseded_at = now
4. entityManager.flush()          ← partial unique index 때문에 반드시 새 plan INSERT 전에
5. new plan: plan_version = old.plan_version + 1, status = ACTIVE, supersedes_plan_id = old.id,
             title = old.title, change_reason = request.reason, replan_recommended = false
6. new milestones: 요청 목록으로 생성 (id가 있어도 새 UUID. 이전 id는 응답의 mapping으로 제공)
7. new plan_skill_target: old 목록 복사 후 적용
     - acceptedDeferrals의 skill → deferred = true, adjustment = DEFERRED
     - acceptedTargetReductions → 해당 축 target 변경, adjustment = TARGET_REDUCED
     - restoredDeferrals의 skill → deferred = false, adjustment = USER_EDITED (같은 skill이 acceptedDeferrals에도 있으면 400 VALIDATION_FAILED)
     - `role_skill_target`에는 있는데 이전 plan에 없는 skill(새 seed로 추가된 skill)은 role 기본값으로 추가한다(adjustment = ROLE_DEFAULT)
     - priority 변경·target 상향은 MVP 범위 밖이다(Later). 필요하면 content YAML의 role target을 바꾸고 새 plan을 만든다
8. PLAN_REPLANNED 이벤트
9. 새 plan 기준 risk 계산 → plan_progress_snapshot(today) upsert
```

- 과거 `daily_plan`, `learning_task`는 이전 plan/milestone ID를 그대로 참조한다.
### 11.3 최초 plan 생성 (온보딩, `POST /plans`)

- `role_skill_target` 전체를 `plan_skill_target`으로 복사한다(adjustment = ROLE_DEFAULT).
- milestone 날짜는 `19-content-spec.md`의 **계획 템플릿 배치 알고리즘**으로 계산한다. `useTemplate=false`이면 milestone 없이 plan만 만든다.
- plan title: 템플릿의 `planTitle`(예: `Java 백엔드 이직 준비`). `useTemplate=false`이면 같은 targetRole 템플릿의 `planTitle`을 제목으로만 쓴다

---

## 12. 지표 (`MetricsCalculator`)

기간: 기본 최근 28 plan-day. 주간: ISO week(월요일 시작, 사용자 plan-day 기준). 결과는 정수다.

| 지표 | 계산 | 단위 |
|---|---|---|
| `completedSessions` | COMPLETED learning_session 수 | 개 |
| `studyMinutes` | COMPLETED 세션 actual_minutes 합 | 분 |
| `independentSolveRateBp` | `floorDiv(SOLVED_INDEPENDENTLY 수 × 10_000, outcome ∉ {null, ABANDONED}인 attempt 수)`, 분모 0이면 null | bp |
| `averageHintLevelMilli` | `floorDiv(Σ ordinal(maxHintLevel) × 1000, n)` — 대상: 평가 완료 attempt, close된 finding, review_answer | 1/1000 |
| `recallSuccessRateBp` | `floorDiv(finalRating ∈ {GOOD, EASY} 수 × 10_000, review_answer 수)` | bp |
| `selfFoundRiskCount` | `COACH_FINDING_CLOSED` 중 discoveredBy = MENTIONED_UNPROMPTED, findingType ∈ {BUG, RISK} | 개 |
| `acceptedEvidenceCount` | status = ACCEPTED evidence 수 (기간 내 accepted_at) | 개 |
| `riskLevel`, `ratioBp` | 기간 마지막 snapshot | — |
| `weakThinkingAxes` | axis별 `MISSED` 비율(`MISSED / 전체 observation`) 상위 3개, observation 3개 이상인 axis만 | 목록 |
| `requirementCoverageBp` | 최근 분석 JD 5개의 REQUIRED 중 fit = READY 비율 | bp |

---

## 13. Job Fit 분류 (`JobFitClassifier`)

JD requirement마다 적용한다. 자기평가가 아니라 **증거 레벨**(evidence level)로 판단한다.

```text
if requirement.skill_id == null → fitCategory = null (UI: "분류 불가")
target_axis = 활성 plan의 plan_skill_target(해당 skill) 목표
            ?? role_skill_target 목표
            ?? (KNOWLEDGE 3, IMPLEMENTATION 3, EXPLANATION 3, DEBUGGING 2)
gap = max_axis( target_axis − evidenceLevel_axis )
fitCategory = gap ≤ 0 → READY
            | gap == 1 → STRETCH
            | gap ≥ 2 → LATER
matchedEvidenceIds = 해당 skill의 ACCEPTED evidence id (accepted_at DESC, 최대 3개)
```

- deferred 여부와 무관하게 target을 쓴다.
- 분류는 분석 완료 시점에 저장하고, 이후 레벨이 바뀌어도 자동으로 다시 계산하지 않는다(재분석은 새 job posting).

**Test vectors**

| target (K,I,E,D) | evidence (K,I,E,D) | gap | fit |
|---|---|---|---|
| (3,3,3,2) | (3,3,3,2) | 0 | READY |
| (4,4,4,3) | (4,3,4,3) | 1 | STRETCH |
| (4,4,4,3) | (2,4,4,3) | 2 | LATER |
| (3,3,3,2) | (5,5,5,5) | −2 → ≤0 | READY |
