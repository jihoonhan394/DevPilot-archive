# 09. Test & Quality

> Status: Accepted (v2) · Last updated: 2026-09-18 · Related: ADR-019, NFR-02, NFR-07, AC-02, AC-05, AC-07, AC-08, AC-12, AC-13, AC-14, AC-15, AC-18, AC-20, AC-23, AC-24, `06-learning-engine-rules.md`, `08-coding-conventions.md`
>
> 이 문서는 **테스트 계층, 도구, 명명, fixture, test vector 적용 방법, 인증·격리·AI·E2E 테스트 목록, 품질 게이트 순서와 실패 기준**을 정의한다. 보안 테스트 목록은 `07-security-and-privacy.md` §16, AI eval은 `17-ai-integration.md` §12, 완료 기준은 `16-definition-of-ready-done.md`가 기준이다.

---

## 1. 테스트 전략

| 계층 | 범위 | 도구 | 위치 | 태그 / task | PR CI |
|---|---|---|---|---|---|
| Unit — 규칙 | `03` §3.2 규칙 클래스, `PlanDayCalculator`, `FixedPointMath`, 가드, `SecretMasker`, `CursorCodec` | JUnit Jupiter, AssertJ, `@ParameterizedTest` + vector 파일 | `backend/src/test/java` (패키지 mirror) | `unit` / `test` | 예 |
| Unit — application | 서비스의 분기·오류 변환 중 DB 없이 검증 가능한 부분 | JUnit, AssertJ, Mockito(경계 port만) | 같음 | `unit` / `test` | 예 |
| Architecture | `08-coding-conventions.md` §11.6 ARCH-01~21 + 테스트 코드 규칙 | ArchUnit | `com.devpilot.architecture` | `unit` / `test` | 예 |
| Web slice | controller 검증, 상태 코드, ProblemDetail 형식, 보안 필터(JWT는 `jwt()`) | `@WebMvcTest`, `MockMvcTester`, spring-security-test | 모듈 `presentation` mirror | `unit` / `test` | 예 |
| JPA slice | repository 쿼리, projection, 배열·JSON 매핑 | `@DataJpaTest` + Testcontainers `postgres:16` | 모듈 `infrastructure` mirror | `integration` / `integrationTest` | 예 |
| Integration | 서비스 + DB 트랜잭션, 불변식, 이벤트, 비동기 task, migration, 실제 JWT decoder | `@SpringBootTest`, Testcontainers, `TestJwksServer`, `FakeAiProvider`, Awaitility | 모듈 mirror, `*IntegrationTest` | `integration` / `integrationTest` | 예 |
| API E2E flow | 여러 endpoint를 HTTP로 이어 호출하는 사용자 흐름 (§11) | `@SpringBootTest(webEnvironment = RANDOM_PORT)`, `RestTestClient` | `com.devpilot.e2e` | `integration` / `integrationTest` | 예 |
| AI eval | 실제 모델 품질 (`17-ai-integration.md` §12) | JUnit + `RestClient`(실제 DeepSeek 호출) | `backend/src/evalTest/java` | — / `aiEval` | **아니오** (수동 workflow) |
| Flutter unit | controller(Notifier), repository 매핑, 오류 매핑, JSON round-trip | `flutter_test`, `ProviderContainer` | `app/test/` (lib mirror) | — / `flutter test` | 예 |
| Flutter widget | SCR-TODAY, SCR-REVIEW 등 화면 상태 | `flutter_test`, `WidgetTester` | `app/test/features/**/presentation/` | — / `flutter test` | 예 |
| Flutter integration | 온보딩 → Today UI 흐름 (fake API) | `integration_test`, Chrome | `app/integration_test/` | — / `flutter drive` | 아니오 (tag 배포 전 `app-integration` job) |
| 성능 스모크 | non-AI API p95 (§13) | k6 | `perf/` | — | 아니오 (S2·S5 종료 전 수동) |
| 배포 스모크 | health, 보안 헤더, 로그인 후 `/me` | shell (`curl`) | `infra/scripts/` | — | deploy workflow |

원칙:
- **규칙은 unit, 불변식과 트랜잭션은 integration, 흐름은 E2E**로 검증한다. 같은 내용을 여러 계층에서 반복하지 않는다.
- 단위·통합 테스트는 실제 AI API, 실제 운영 DB, 외부 네트워크를 호출하지 않는다.
- Mockito는 port 경계(`AuthenticatedUserResolver` in web slice, `AiProvider` 호출 횟수 확인이 필요한 곳)에만 쓴다. repository, entity, 규칙 클래스, `Clock`을 mock하지 않는다.

---

## 2. 도구 · 버전

버전은 Spring Boot 4.1.x BOM이 관리하는 값을 쓰고, BOM에 없는 것만 `libs.versions.toml`에 고정한다. 아래 "확인" 표시는 S0 bootstrap에서 실제 좌표·버전을 확인한다.

| 도구 | 기준 | 용도 · 규칙 |
|---|---|---|
| JUnit Jupiter | Boot 4.1 BOM (JUnit 6 계열, 확인) | `junit-jupiter`, `junit-jupiter-params`. JUnit 4·Vintage 금지 |
| AssertJ | BOM | 모든 assertion. `org.junit.jupiter.api.Assertions` import 금지(Checkstyle) |
| Mockito | BOM | 최소 사용(§1). Java 21+ 동적 agent 경고를 피하려고 Gradle test JVM에 `-javaagent:<mockito-core jar>` 설정 |
| Spring Boot Test | `spring-boot-starter-test` | slice 애노테이션 패키지는 Boot 4에서 모듈별로 나뉘었다 — import 경로 확인 |
| spring-security-test | BOM | `jwt()` post-processor, `SecurityMockMvcRequestPostProcessors` |
| Testcontainers | BOM (2.x, 확인) | **`postgres:16`** 이미지(개발·운영 DB와 같은 major, `18` §1.1), `@ServiceConnection`. 컨테이너는 JVM당 1개(singleton). 로컬 Docker가 없으면 서버 Docker를 SSH 터널로 쓴다(`18` §3.1: `DOCKER_HOST`, `TESTCONTAINERS_HOST_OVERRIDE`) |
| Awaitility | BOM | 비동기 결과 대기. `Thread.sleep` 대신 사용, 기본 최대 10초 |
| `TestJwksServer` | JDK `com.sun.net.httpserver.HttpServer` (추가 의존성 없음) | 로컬 EC P-256 키의 JWKS 제공. JWKS 제공에는 MockWebServer·WireMock을 쓰지 않는다. DeepSeek 요청 검사(`DeepSeekAiProviderRequestTest`)는 spring-test의 `MockRestServiceServer`를 쓴다(추가 의존성 없음, `17-ai-integration.md` §12.1). WireMock·MockWebServer는 쓰지 않는다 |
| Nimbus JOSE + JWT | `spring-security-oauth2-jose` 전이 의존성 | 테스트 토큰 서명 (`TestJwtFactory`) |
| ArchUnit | `archunit-junit5` 1.x 최신 (확인) | ARCH 규칙 |
| JaCoCo | Java 25 지원 버전 (확인) | §15 |
| `RestTestClient` | Spring Framework 7 `spring-test` | E2E HTTP 호출 (확인). 사용할 수 없으면 `TestRestTemplate` |
| Flutter test | `flutter_test`, `integration_test` (SDK 내장) | FVM 고정 버전 |
| k6 | 최신 안정판 (로컬 설치) | 선택 실행 성능 스모크 |

### 2.1 Testcontainers 설정

```java
@TestConfiguration(proxyBeanMethods = false)
public class PostgresTestcontainersConfig {

    static final PostgreSQLContainer POSTGRES =
            new PostgreSQLContainer(DockerImageName.parse("postgres:16"))
                    .withDatabaseName("devpilot")
                    .withReuse(true); // effective only when ~/.testcontainers.properties enables reuse

    static {
        POSTGRES.start();
    }

    @Bean
    @ServiceConnection
    PostgreSQLContainer postgres() {
        return POSTGRES;
    }
}
```

- 모든 DB 테스트는 이 설정을 `@Import`한다(직접 `@Container` 필드를 만들지 않는다). Spring context 캐시가 재사용되도록 **통합 테스트 설정 조합을 `@IntegrationTest` 메타 애노테이션 하나로 고정**한다(§3.3).
- 로컬 Windows: `%USERPROFILE%\.testcontainers.properties`에 `testcontainers.reuse.enable=true`. CI는 reuse를 켜지 않는다.
- Docker Desktop이 실행 중이 아니면 `integrationTest`는 실패한다(건너뛰지 않음).

---

## 3. 명명 · 구조

### 3.1 테스트 클래스와 메서드

| 대상 | 이름 |
|---|---|
| 단위 테스트 | `<ProductionClass>Test` — production 클래스 1개당 1개 |
| 통합 테스트 | `<ProductionClass>IntegrationTest` |
| E2E 흐름 | `<Flow>FlowTest` (`com.devpilot.e2e`) |
| 아키텍처 | `<Topic>ArchTest` (`com.devpilot.architecture`) |
| 여러 production 클래스를 가로지르는 보안 테스트 | `07-security-and-privacy.md` §16의 이름 그대로 (`AuthorizationIsolationTest` 등) |
| 메서드 | 영어 `should<Expected>When<Condition>`. 예: `shouldCapFinalRatingAtGoodWhenQuestionOnlyHintUsed` |
| `@DisplayName` | 선택. 쓰면 한국어 문장 (예: `@DisplayName("QUESTION_ONLY 힌트를 봤으면 최종 등급은 GOOD을 넘지 않는다")`) |
| 파라미터화 이름 | `@ParameterizedTest(name = "[{index}] {0}")` + vector의 `id` 컬럼 |

- 패키지는 production과 같다(`src/test/java/com/devpilot/review/domain/RuleBasedV1SchedulerTest.java`).
- 한 테스트 메서드는 한 동작을 검증한다. given/when/then 주석은 쓰지 않고 빈 줄로 구분한다.
- `@Nested`는 상태 전이표처럼 그룹이 명확할 때만 쓴다.
- `@TestMethodOrder`, 테스트 간 상태 공유 금지(E2E flow는 **한 메서드 안에서** 단계를 진행한다).

### 3.2 Source set과 태그

단일 `test` source set에 JUnit 태그로 나누고, 실제 모델 eval만 별도 source set으로 둔다.

| Source set | 디렉터리 | 태그 | Gradle task | `check` 포함 |
|---|---|---|---|---|
| `test` | `src/test/java`, `src/test/resources` | `unit` | `test` (`useJUnitPlatform { includeTags("unit") }`) | 예 |
| `test` | 같음 | `integration` | `integrationTest` (Test task, 같은 classpath, `includeTags("integration")`, `shouldRunAfter(test)`) | 예 |
| `evalTest` | `src/evalTest/java`, `src/evalTest/resources` | — | `aiEval` (`-PevalSuite=<suite>`) | **아니오** |

- 모든 테스트 클래스는 `@Tag("unit")` 또는 `@Tag("integration")`(메타 애노테이션 포함) 중 정확히 하나를 가진다. 태그가 없으면 어떤 task에서도 실행되지 않으므로 ArchUnit `TEST-02`가 실패시킨다.
- `evalTest`는 `test` 출력에 의존하지 않고 main에만 의존한다. `DEEPSEEK_API_KEY`가 없으면 즉시 실패한다.

### 3.3 메타 애노테이션

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Tag("integration")
@SpringBootTest
@ActiveProfiles("test")
@Import({PostgresTestcontainersConfig.class, TestClockConfig.class, TestJwksConfig.class, FakeAiConfig.class})
public @interface IntegrationTest {}
```

`FakeAiConfig`의 `FakeAiProvider` bean에는 main과 같은 `@ConditionalOnProperty("devpilot.ai.provider", havingValue = "fake")`를 붙인다. 그래서 provider를 덮어쓰는 테스트(E2E-07의 `disabled`)에서는 등록되지 않고 `DisabledAiProvider`가 선택된다.

`@ApiFlowTest`(E2E, `RANDOM_PORT` 추가), `@UnitTest`(`@Tag("unit")`)도 같은 방식으로 `com.devpilot.testsupport`에 둔다. 테스트마다 `@MockitoBean`이나 `@TestPropertySource`를 추가하면 context 캐시가 깨지므로, 통합 테스트에서는 **AI provider 설정 변경(E2E-07) 외에 추가하지 않는다.**

### 3.4 테스트 코드 규칙 (ArchUnit, `TestCodeRulesArchTest`)

| ID | 규칙 |
|---|---|
| TEST-01 | 테스트 코드에서 `Thread.sleep` 호출 금지 (Awaitility 또는 `MutableClock`) |
| TEST-02 | `*Test` 클래스는 `unit` 또는 `integration` 태그 중 정확히 하나 |
| TEST-03 | `org.junit.jupiter.api.Disabled`는 메시지에 `flaky: #<issue>` 형식만 허용하고, 전체 개수 1개 이하 (§16) |
| TEST-04 | `com.devpilot.architecture` 외 테스트에서 `@TestMethodOrder` 금지 |
| TEST-05 | `@RetryingTest`, JUnit Pioneer retry, Gradle test-retry plugin 사용 금지 |

---

## 4. Fixture

### 4.1 공용 테스트 지원 (`com.devpilot.testsupport`)

| 클래스 | 역할 |
|---|---|
| `MutableClock` | `Clock` 구현. `setInstant(Instant)`, `advance(Duration)`, zone 고정 UTC. 스레드 안전(`AtomicReference`) |
| `TestClockConfig` | `@Primary Clock` bean = `MutableClock`(초기값 `2026-10-05T10:00:00Z`, KST 19:00). 각 통합 테스트는 `@BeforeEach`에서 필요한 시각으로 `setInstant` |
| `FixedIds` | 결정적 UUID: `FixedIds.uuid(7)` → `00000000-0000-0000-0000-000000000007`. 규칙 unit 테스트 입력용. 저장 경로의 ID는 애플리케이션이 만든다 |
| `TestDataFactory` | 도메인 입력 record·entity builder의 진입점. `TestDataFactory.reviewItem().intervalDays(4).dueAt(…).build()` 형식. 모든 필드에 유효한 기본값 |
| `TestUsers` | `TestUsers.owner()`, `TestUsers.invited()`: 매 호출마다 새 `sub`(랜덤 UUID) + allowlist 이메일. `TestUsers.stranger()`: allowlist 밖 이메일 |
| `TestJwtFactory` | `TestJwksServer` 키로 ES256 토큰 발급. `validToken(user)`, `withClaims(user, Consumer<JWTClaimsSet.Builder>)`, `signedWith(otherKey)`, `withAlgorithm(…)` |
| `TestApi` | E2E·격리 테스트용 HTTP 헬퍼: `onboard(user)`, `generateToday(user, minutes)`, `startAttempt(user, challengeId)` 등. 매 POST에 새 `Idempotency-Key` |
| `FakeAiProvider` test hook | `fakeAiProvider.use(AiOperation, "case")`로 fixture 선택(`17-ai-integration.md` §12.2), `receivedRequests`, `callCount`, `blockUntilReleased`/`release`, `reset` (§10.1) |
| `AuditLogCapture` | Logback `ListAppender`로 `com.devpilot.audit` 로거 이벤트 수집 (`07` §6.3 필드 검증) |

### 4.2 데이터 규칙

- 통합 테스트는 **테이블을 비우지 않는다.** 테스트마다 `TestUsers`로 새 사용자를 만들고, 모든 assertion을 그 사용자의 `userId` 범위로 한다. 그래서 병렬·순서와 무관하다.
- test profile allowlist: `devpilot.security.allowed-emails=owner@devpilot.test,invited@devpilot.test`(비허용 사용자는 `stranger@devpilot.test`). `app_user`에는 이메일 컬럼이 없으므로 같은 이메일·다른 `sub` 사용자를 여러 명 만들 수 있다.
- seed catalog는 `src/test/resources/content/`의 테스트 전용 소형 YAML(skill 12개, challenge 6개, 카드 10장)을 `devpilot.content.location`으로 지정해 context 기동 시 1회 적재한다. 운영 `content/`에 테스트가 의존하지 않는다.
- entity를 테스트에서 직접 `repository.save`해 상태를 만드는 것은 JPA slice와 불변식 테스트에서만 허용한다. 그 외에는 API 또는 application service로 만든다.

---

## 5. 규칙 test vectors

### 5.1 파일 규칙

- `06-learning-engine-rules.md`의 Test vectors 표는 **한 행도 빠짐없이** 파일로 옮긴다(`06` 머리말).
- 위치: `backend/src/test/resources/vectors/`
- 이름: `06-<절 번호 2자리>-<규칙 kebab-case>.<csv|yaml>` (예: `06-06-review-schedule.csv`)
- 표 형태(한 행 = 입력 몇 개 + 기대값)는 CSV, 중첩 입력(이벤트 목록, rubric 목록, 후보 skill)은 YAML.
- 첫 줄 주석에 출처와 행 수를 적는다: `# source: 06 §6.6, rows: 10`. `VectorFileTest`가 모든 파일의 실제 행 수와 선언 행 수를 비교한다.
- 모든 행에 `id` 컬럼(`V01`…)을 둔다. 테스트 이름에 표시된다.
- `06`의 vector를 바꾸는 PR은 같은 PR에서 파일을 고친다. 파일만 바꾸는 PR은 리뷰에서 거절한다.
- CSV 소스: `@CsvFileSource(resources = "/vectors/06-06-review-schedule.csv", numLinesToSkip = 2)`(주석·헤더). `nullValues = "null"`을 지정해 `null` 리터럴은 null, 빈 칸은 빈 목록으로 읽는다. enum은 이름 문자열, 목록은 `|` 구분.
- YAML 소스: `@MethodSource`에서 `VectorLoader.load("06-07-skill-level.yaml", SkillLevelVector.class)`(테스트 전용 record, Jackson YAML).

예 (`06-06-review-schedule.csv`):

```csv
# source: 06 §6.6, rows: 10
id,prevInterval,selfRating,evaluatedOutcome,hintLevel,expectedFinal,expectedAdjustedBy,horizonDaysFromAnswer,expectedInterval
V01,1,GOOD,NOT_EVALUATED,SELF_EXPLAIN,GOOD,,null,2
V06,30,GOOD,CORRECT,PSEUDOCODE,AGAIN,HINT_CAP_AGAIN,null,1
V10,10,GOOD,CORRECT,SELF_EXPLAIN,GOOD,,5,4
```

### 5.2 `06` 절 → vector 파일 → 테스트 클래스

| `06` 절 | vector 파일 | 테스트 클래스 | 계층 |
|---|---|---|---|
| §1 N-4, N-5, N-7 | `06-01-fixed-point-math.csv` (경계: 0, 음수 거부, overflow) | `FixedPointMathTest` | unit |
| §1 N-6 | — (설정 바인딩 케이스) | `DevPilotPropertiesBindingTest` | unit |
| §2 | `06-02-plan-day.csv` (5행, DST zone vector 포함) | `PlanDayCalculatorTest` | unit |
| §3 | `06-03-study-budget.csv` (7행) | `StudyBudgetCalculatorTest` | unit |
| §4.2 | `06-04-required-minutes.csv` (3행) | `DeadlineRiskEvaluatorTest` | unit |
| §4.3 | `06-04-risk-level.csv` (8행) | `DeadlineRiskEvaluatorTest` | unit |
| §4.4 | `06-04-replan-suggestion.yaml` (1행) | `ReplanSuggestionPolicyTest` | unit |
| §5.3 | `06-05-task-proposal.yaml` (분기 4개 + comeback) | `TaskProposalPolicyTest` | unit |
| §5.4–5.5, §5.7 | `06-05-planner-score.yaml` (6행) | `PlannerScoringTest` | unit |
| §5.5 comebackMode | `06-05-comeback-mode.csv` | `ComebackModePolicyTest` | unit |
| §5.6 | `06-05-time-allocation.csv` (6행) | `TimeAllocatorTest` | unit |
| §5.8 | `06-05-reasons.yaml` (최소 1개 보장, modifier 우선, 최대 3개) | `ReasonTemplatesTest` | unit |
| §5.9 | — (상태 조합 표 7칸) | `TodayPlanServiceIntegrationTest` | integration |
| §6.1 | `06-06-review-schedule.csv`의 final·adjustedBy 컬럼 | `FinalRatingPolicyTest` | unit |
| §6.2, §6.6 | `06-06-review-schedule.csv` (10행) | `RuleBasedV1SchedulerTest` | unit |
| §6.3 | `06-06-first-due.yaml` | `SeedCardAssignmentServiceIntegrationTest` | integration |
| §6.4 | — (failures 2/4 경계, variant 상태) | `ReviewServiceIntegrationTest` | integration |
| §6.5 | `06-06-due-selection.yaml` (경계: `due_at = planDayStart(today + 1)`은 제외) | `DueReviewSelectorTest` | unit |
| §7.2–7.4, §7.6 #1–12, #15 | `06-07-skill-level.yaml` | `SkillLevelRulesTest` | unit |
| §7.5, §7.6 #13–14 | `06-07-planning-level.csv` | `PlanningLevelPolicyTest` | unit |
| §8.1 | `06-08-rubric-coverage.yaml` (6행) | `RubricScorerTest` | unit |
| §8.2 | `06-08-rubric-coverage.yaml`의 outcome 컬럼 | `AttemptOutcomeCalculatorTest` | unit |
| §8.3 | — | `SubmissionEvaluationTaskIntegrationTest` | integration |
| §9.1–9.2 | `06-09-hint-ladder.csv` (6행) | `HintLadderPolicyTest` | unit |
| §9.3 | `06-09-discovered-by.csv` | `DiscoveredByResolverTest` | unit |
| §9.4 | — (findingType × discoveredBy × skill 유무 조합, 같은 concept_key 재사용) | `CoachFindingServiceIntegrationTest` | integration |
| §10 | `06-10-verification-guard.csv` (7행) | `VerificationGuardTest` | unit |
| §11.2 | — (절차 1~9, `restoredDeferrals`, `acceptedDeferrals`와 중복 시 400) | `ReplanServiceIntegrationTest` | integration |
| §12 | `06-12-metrics.yaml` | `MetricsCalculatorTest` | unit |
| §13 | `06-13-job-fit.csv` (4행 + skill 없음 → null, target fallback 순서) | `JobFitClassifierTest` | unit |

- vector 외에 **경계값 테스트**를 같은 클래스에 추가한다: `availableMinutes` 5·720, interval 1·60, risk 경계 8,000·10,000·12,500bp, coverage 3,999·4,000·7,999·8,000bp, cooldown 23:59:59·24:00:00.
- 규칙 클래스 생성자에 넘기는 설정은 `03` §9 기본값을 정수로 변환한 `TestRuleSettings.defaults()`를 쓴다.

---
## 6. JWT 테스트

### 6.1 Web slice (`jwt()`)

- 대상: controller 요청 검증, 인증 필요 여부, ProblemDetail 형식.
- `@WebMvcTest(XxxController.class)` + `@Import(SecurityConfig.class)` + `@MockitoBean AuthenticatedUserResolver`(→ 고정 `ResolvedUser` 반환).
- 요청: `.with(jwt().jwt(j -> j.subject(sub.toString()).claim("email", "owner@devpilot.test").issuedAt(now)))`.
- slice에서는 서명·issuer 검증을 하지 않는다. 그 검증은 §6.2에서만 한다.

### 6.2 통합 (`JwtValidationIntegrationTest`)

구성:
1. `TestJwksServer`가 기동 시 EC P-256 키쌍(`kid = "test-key-1"`)을 만들고 `http://127.0.0.1:<port>/auth/v1/.well-known/jwks.json`으로 공개키 JWKS를 제공한다.
2. `TestJwksConfig`가 `DynamicPropertyRegistrar`로 `spring.security.oauth2.resourceserver.jwt.issuer-uri = http://127.0.0.1:<port>/auth/v1`, `spring.security.oauth2.resourceserver.jwt.jwk-set-uri = http://127.0.0.1:<port>/auth/v1/.well-known/jwks.json`, `jws-algorithms = ES256`을 **직접** 등록한다(`application-test.yml`의 placeholder 해석에 의존하지 않음. test profile은 `auth-mode = supabase`로 두어 JWKS 경로를 검증한다 — `devtoken` 모드는 §6.4에서 따로 본다). test profile에는 CORS 설정이 없다(`07-security-and-privacy.md` §9.1).
3. `TestJwtFactory`가 같은 private key로 `iss`, `aud=authenticated`, `sub`, `email`, `iat`, `exp=iat+3600`을 넣어 서명한다. 시각은 `MutableClock` 기준.
4. 검증 대상 endpoint: `GET /api/v1/me`.

| # | 케이스 | 기대 |
|---|---|---|
| J-01 | 유효 토큰 | 200 |
| J-02 | `Authorization` 헤더 없음 | 401 `AUTHENTICATION_REQUIRED` |
| J-03 | `Bearer` 뒤 값이 JWT 형식 아님 (`abc`) | 401 |
| J-04 | `Basic …` 스킴 | 401 |
| J-05 | `exp = now − 61초` | 401 |
| J-06 | `exp = now − 59초` (skew 60초 안) | 200 |
| J-07 | `nbf = now + 120초` | 401 |
| J-08 | 다른 EC 키로 서명, 같은 `kid` | 401 |
| J-09 | JWKS에 없는 `kid` (재조회 후에도 없음) | 401, JWKS 요청 횟수 증가 확인 |
| J-10 | `alg = HS256`, JWKS 공개키 바이트를 HMAC secret으로 사용 | 401 |
| J-11 | `alg = none`, 서명 없음 | 401 |
| J-12 | RS256 키로 서명한 토큰 (설정은 ES256) | 401 |
| J-13 | `iss` = 다른 발급자 URL | 401 |
| J-14 | `aud = anon` | 401 |
| J-15 | `aud` 없음 | 401 |
| J-16 | `sub` 없음 | 401 |
| J-17 | `sub = "not-a-uuid"` | 401 |
| J-18 | `is_anonymous = true` | 403 `USER_NOT_ALLOWED` |
| J-19 | allowlist 밖 이메일 | 403 `USER_NOT_ALLOWED`, `app_user` 0행, `AUTH_USER_REJECTED` |
| J-20 | `email` 없음 + `sub`이 `allowed-subjects`에 있음 | 200 |
| J-21 | JWKS 키 회전: 서버가 `test-key-2`를 추가하고 새 키로 서명 | 200 (재조회) |
| J-22 | 401 응답 본문에 `expired`, `signature`, `issuer`, `kid` 문자열 없음 | 통과 |

- 401 응답은 모두 같은 `code`, `title`, `detail`이어야 한다(J-22와 함께 `ProblemDetailsLeakTest`에서 교차 확인).
- `RecentLoginRequiredTest`(`DELETE /me`, `03` §4.2): `amr[].timestamp` 최댓값 = `now − 5분`(허용), `now − 5분 − 1초`(403 `RECENT_LOGIN_REQUIRED`), 오래된 `amr` + 최근 `amr` 섞임(최댓값 기준 허용), `amr` 없음 + `iat = now − 4분`(허용, fallback), `amr` 없음 + `iat = now − 6분`(403), 인증 시각 `now + 61초`(403), 이미 `DELETION_REQUESTED`(검사 없이 202).

### 6.4 개발 토큰 모드 (`DevTokenIntegrationTest`, `auth-mode = devtoken`)

`devtoken`은 **운영을 포함한 기본 인증 모드**이므로(`03` §4.2, 결정 A) §6.2와 같은 비중으로 검증한다. `@TestPropertySource(properties = "devpilot.security.auth-mode=devtoken")`로 전용 context를 쓰고, 키는 기동 시 생성된 것을 그대로 쓴다(테스트가 PEM을 주입하지 않는다).

| # | 요청 | 기대 |
|---|---|---|
| D-01 | `POST /dev/token` `{email: allowlist에 있는 값}` | 200, `tokenType = "Bearer"`, `expiresAt = now + 720h`, 감사 `AUTH_DEVTOKEN_ISSUED`. 이 시점에 `app_user` 행은 없다 |
| D-02 | D-01의 `accessToken`으로 `GET /me` | 200, `app_user` 1행 생성(JIT, `03` §4.3), `AUTH_USER_PROVISIONED` |
| D-03 | `POST /dev/token` `{email: allowlist 밖}` | 403 `USER_NOT_ALLOWED`, 토큰 없음, `app_user` 행 없음, 감사 `AUTH_DEVTOKEN_REJECTED` |
| D-04 | `POST /dev/token` `{email: "not-an-email"}` / body 없음 | 400 `VALIDATION_FAILED` |
| D-05 | `POST /dev/token`에 `Idempotency-Key` 없이 호출 | 200 (IK 대상이 아니다, `05` §1.7) |
| D-06 | `GET /dev/jwks.json` | 200, `keys[0].kty = "EC"`, `crv = "P-256"`, `alg = "ES256"`, `kid` 존재, private key 필드(`d`) 없음, `Cache-Control: no-store` |
| D-07 | 발급 토큰의 claim | `iss = ${APP_BASE_URL}/dev`, `aud = authenticated`, `sub`이 UUID, `email` 일치, `amr[0].method = "devtoken"` |
| D-08 | 다른 키로 서명한 같은 형식의 토큰 | 401 |
| D-09 | `exp`가 지난 토큰(`MutableClock` 전진) | 401 |
| D-10 | 같은 email로 두 번 발급 | `sub`이 같다(UUID v5(email)) → `app_user` 행은 여전히 1개 |
| D-11 | `auth-mode = supabase` context에서 `POST /dev/token`, `GET /dev/jwks.json` | 404 (bean 미등록) |
| D-12 | IP당 30회/시간 초과 | 429 `RATE_LIMITED` |

- prod profile + `auth-mode = devtoken` + `DEVPILOT_DEV_JWT_KEY` 없음 → **기동 실패**를 `ApplicationContextRunner`로 확인한다(`03` §9).
- `RecentLoginRequiredTest`(§6.2 끝)는 devtoken 발급 시각(`amr[].timestamp`)으로도 같은 규칙이 성립하는지 1케이스 확인한다.

---

## 7. 아키텍처 테스트 (ArchUnit)

규칙 정의는 `08-coding-conventions.md` §11.6이다. 모듈 의존 matrix는 `03-system-architecture.md` §2.2 표를 그대로 코드로 옮긴다.

| 테스트 클래스 | 규칙 |
|---|---|
| `ModuleDependencyArchTest` | ARCH-01, ARCH-02, ARCH-03 |
| `LayerArchTest` | ARCH-04, ARCH-09, ARCH-14, ARCH-20 |
| `TransactionBoundaryArchTest` | ARCH-10, ARCH-21 |
| `DomainPurityArchTest` | ARCH-11, ARCH-12, ARCH-13, ARCH-16 |
| `CodingRulesArchTest` | ARCH-05, ARCH-06, ARCH-07, ARCH-08, ARCH-15, ARCH-17, ARCH-18, ARCH-19 |
| `TestCodeRulesArchTest` | TEST-01 ~ TEST-05 (§3.4) |

- 클래스 로딩: `@AnalyzeClasses(packages = "com.devpilot", importOptions = ImportOption.DoNotIncludeTests.class)`를 공용 상수로 둔다. `TestCodeRulesArchTest`만 `OnlyIncludeTests`.
- 각 규칙은 `because("<ARCH-ID>: <문서 절>")`로 실패 메시지에 ID와 근거를 남긴다.
- ARCH-01 matrix는 `ModuleDependencyArchTest.ALLOWED_DEPENDENCIES` 상수 하나다. `03` §2.2를 바꾸는 PR은 이 상수를 같은 PR에서 바꾼다.
- 빈 규칙 방지: `archRule.allowEmptyShould(false)`(기본값) 유지. 대상 클래스가 아직 없는 규칙(예: S0의 `*Task`)은 해당 클래스가 처음 생기는 Sprint에 활성화하고, 비활성 기간에는 `@Disabled`가 아니라 규칙 목록에서 제외한 뒤 PR 설명에 적는다.
- **런타임 이중 방어**: `AiGatewayTransactionGuardTest`(integration) — `TransactionTemplate` 안에서 `AiGateway.call`을 호출하면 `IllegalStateException`이 나고 `FakeAiProvider` 호출 횟수가 0인지 확인한다(T-2, `08` §4.2).

---

## 8. DB · migration 테스트

### 8.1 Migration

| 테스트 | 내용 |
|---|---|
| `FlywayMigrationIntegrationTest` | 빈 `postgres:16` DB → Flyway 전체 적용 성공 → `spring.jpa.hibernate.ddl-auto=validate`로 context 기동 성공(모든 entity 매핑이 스키마와 일치). 적용된 migration 버전 목록이 `db/migration` 파일 목록과 같음 |
| `SchemaSnapshotConsistencyTest` | 같은 컨테이너에 DB `snapshot`을 만들어 `database/schema.sql`을 실행한다. migration 적용 DB와 비교: `information_schema.columns`(테이블, 컬럼, 타입, nullable, default), `pg_constraint`(이름 무관, `pg_get_constraintdef` 정규화 문자열 집합), `pg_indexes.indexdef`(스키마 이름 치환 후 집합). 차이가 있으면 실패하고 차이 목록을 출력한다 (`04` §10 "schema.sql = 전체 migration 결과") |
| `SupabaseHardeningMigrationTest` | (현재 운영 DB는 순수 PostgreSQL이라 V1의 DO 블록은 no-op다. Supabase 도입 시 의미가 생긴다) migration 전에 역할 `anon`, `authenticated`를 만든 DB에 전체 migration 적용 → `has_schema_privilege('anon', 'devpilot', 'USAGE')`, `has_table_privilege('authenticated', 'devpilot.app_user', 'SELECT')` 등이 모두 `false` (AC-20) |
| `MigrationImmutabilityCheck` (CI step) | PR diff에서 `backend/src/main/resources/db/migration/V*.sql` 중 **base 브랜치**에 이미 있는 파일이 수정되면 실패 (`git diff --name-status origin/${{ github.base_ref }}... \| grep '^M.*db/migration/V'`). base는 `developer` 또는 `main`이다 — `main` 고정으로 두면 `developer`에만 머지된 migration의 수정을 놓친다 |

- `schema.sql`의 파일 끝 DO 블록은 `snapshot` DB에서도 실행된다(역할이 없으면 no-op).

### 8.2 불변식 테스트 (I-01 ~ I-15)

DB 제약 자체는 `InvariantConstraintIntegrationTest`에서 JDBC로 직접 위반 행을 넣어 `SQLState 23505`(unique) / `23514`(check)를 확인한다. 애플리케이션 경로는 해당 서비스 통합 테스트에서 409 코드를 확인한다.

| 불변식 | DB 제약 테스트 | 애플리케이션 경로 테스트 | 기대 |
|---|---|---|---|
| I-01 career goal 1개 | 같은 `user_id` 2행 → 23505 | `CareerGoalServiceIntegrationTest` | `PUT`은 갱신, 중복 생성 없음 |
| I-02 ACTIVE plan 1개 | ACTIVE 2행 → 23505 | `ReplanServiceIntegrationTest.shouldFlushSupersededPlanBeforeInsertingNewVersion` | replan 성공 + ACTIVE 1개. 그리고 **SQL 실행 순서**를 확인: `update learning_plan … SUPERSEDED`가 `insert into learning_plan`보다 먼저 실행됨(Hibernate `StatementInspector`로 수집) |
| I-02 동시 replan (AC-24) | — | `ReplanConcurrencyIntegrationTest`: 같은 plan·같은 `version`으로 스레드 2개가 `CountDownLatch`로 동시에 replan | 정확히 1개 201, 나머지 409 `CONCURRENT_MODIFICATION` 또는 `PLAN_NOT_ACTIVE`, ACTIVE plan 1개 |
| I-03 plan-day당 daily_plan 1개 | 23505 | `TodayPlanServiceIntegrationTest` | 재생성은 같은 행 갱신 |
| I-04 활성 main task 1개 | 같은 daily_plan에 `is_main=true`·`PLANNED` 2행 → 23505. `COMPLETED` 1행 + `PLANNED` 1행은 성공 | `TodayPlanServiceIntegrationTest`: `06` §5.9 표 7칸 전부, force 재생성 시 `DEFERRED` 변경 → flush → 새 main INSERT 순서 | 표의 결과·오류 코드 |
| I-05 IN_PROGRESS 세션 1개 | 23505 | `LearningSessionServiceIntegrationTest`: 진행 중 세션이 있을 때 새 세션 시작 | 기존 `ABANDONED`, 새 세션 201 |
| I-06 사용자·개념당 review item 1개 | 23505 | `ReviewItemServiceIntegrationTest`: 같은 `concept_key` 생성 | 기존 항목 `ACTIVE`, `due_at = min(기존, 내일 시작)` |
| I-07 VERIFIED 근거 | `VERIFIED` + `AI_REASONING` → 23514 | `VerificationGuardTest` | 강등 |
| I-08 도구 source_type | `STATIC_ANALYSIS` + `AI_JUDGMENT` → 23514 | `VerificationGuardTest` | 강등 |
| I-09 VALIDATED 필수 필드 | `VALIDATED` + `prompt null` → 23514 | `ChallengeValidationServiceTest` | `REJECTED` |
| I-10 rubric weight 합 10,000 | (DB 제약 없음) | `ChallengeValidationServiceTest`: 9,999 / 10,000 / 10,001 | 10,000만 통과 |
| I-11 hint 1회 저장 | 23505 | `HintServiceIntegrationTest`: 같은 단계 재요청 | AI 호출 0, 저장 1행 |
| I-12 레벨 변경 ↔ state change | — | ARCH-11 + `SkillStateUpdaterIntegrationTest`: 이벤트 처리 후 `user_skill_state` 레벨 변경 수 = `skill_state_change` 행 수 | 일치 |
| I-13 learning_event 불변 | — | ARCH-16 | setter 없음 |
| I-14 마스킹 후 저장 | — | `CoachReviewMaskingOrderTest` (§10.3) | 원문 미저장 |
| I-15 타 사용자 접근 불가 | — | `AuthorizationIsolationTest` (§9) | 404 |

### 8.3 Repository (JPA slice)

- 모든 custom `@Query`와 projection 메서드는 `@DataJpaTest` 테스트 1개 이상을 가진다. 타 사용자 행이 섞인 데이터에서 `userId` 조건으로 걸러지는지 확인한다.
- JSON·배열 컬럼 매핑 round-trip: `LearningTask.scoreBreakdown`(jsonb record), `reasonCodes`(varchar[]), `SkillStateChange.evidenceEventIds`(uuid[]).
- cursor 쿼리: 같은 `sortKey`를 가진 행이 여러 개일 때 `id`로 중복·누락 없이 페이지가 이어지는지 확인한다(21행, limit 10).

---

## 9. 권한 격리 테스트

### 9.1 구조

- `AuthorizationIsolationTest`(`@ApiFlowTest`)는 **endpoint catalog 하나를 입력으로 하는 파라미터화 테스트**다.
- catalog: `com.devpilot.security.UserOwnedEndpoints` — `record EndpointCase(String id, HttpMethod method, String pathTemplate, Kind kind, BiFunction<Owner, TestApi, Map<String, String>> pathVariables, Function<Owner, Object> body, String expectedNotFoundCode)`.
- `@BeforeAll`: 사용자 A(`TestUsers.owner()`)가 모든 리소스를 가진 상태를 API로 만든다(온보딩, today, 세션, seed review 답변, 수동 카드, AI 생성 challenge + attempt + 제출 평가 완료, coach review 완료 + finding, evidence, weekly review, job posting — S7 전에는 해당 case를 catalog에 넣지 않는다).
- 사용자 B(`TestUsers.invited()`)는 온보딩만 한다. 사용자 C는 `TestUsers.stranger()`.

| 검증 | 대상 | 기대 |
|---|---|---|
| ISO-1 | `Kind.OWNED_RESOURCE`: B 토큰으로 A의 리소스 ID 사용 | 404 + case의 `expectedNotFoundCode`. A의 리소스 상태 변화 없음(요청 전후 `GET` 비교) |
| ISO-1b | `Kind.BODY_REFERENCE`: B 토큰으로 body에 A의 리소스 ID | 400 `VALIDATION_FAILED` + field error `REFERENCE_NOT_FOUND` (없는 ID와 같은 응답, `05-api-spec.md` §1.2.3). 새 행 없음 |
| ISO-2 | `Kind.SCOPED_COLLECTION`: B 토큰으로 호출 | 200, 응답에 A의 리소스 ID가 하나도 없음 |
| ISO-3 | 모든 case: `Authorization` 없음 | 401 `AUTHENTICATION_REQUIRED` |
| ISO-4 | 모든 case: C 토큰 | 403 `USER_NOT_ALLOWED` |
| ISO-5 | `IdempotencyTest` 연계: B가 A의 `Idempotency-Key` 값으로 같은 POST | 재생되지 않고 B의 요청으로 처리 |
| ISO-6 | B가 A의 cursor 문자열을 목록 API에 전달 | 200, B의 데이터만 |

- POST case는 매 요청 새 `Idempotency-Key`를 붙인다(401·403·404가 idempotency 처리보다 먼저인지도 함께 확인된다).

### 9.2 Catalog (`05-api-spec.md` 기준 사용자 소유 endpoint)

| Kind | endpoint (A의 ID를 넣는 위치) | 기대 code |
|---|---|---|
| OWNED_RESOURCE | `GET /plans/{planId}` | `PLAN_NOT_FOUND` |
| OWNED_RESOURCE | `PATCH /plans/{planId}/milestones/{milestoneId}` | `PLAN_NOT_FOUND` |
| OWNED_RESOURCE | `POST /plans/{planId}/replan/preview`, `POST /plans/{planId}/replan` | `PLAN_NOT_FOUND` |
| OWNED_RESOURCE | `PATCH /today/tasks/{taskId}` | `RESOURCE_NOT_FOUND` |
| BODY_REFERENCE | `POST /learning-sessions` (body `learningTaskId` = A의 task) | 400 `VALIDATION_FAILED` + field error `REFERENCE_NOT_FOUND` |
| OWNED_RESOURCE | `POST /learning-sessions/{sessionId}/complete`, `/abandon` | `RESOURCE_NOT_FOUND` |
| OWNED_RESOURCE | `GET /challenges/{challengeId}` (A 소유 AI 생성 challenge) | `RESOURCE_NOT_FOUND` |
| OWNED_RESOURCE | `POST /challenges/{challengeId}/attempts` (A 소유 challenge) | `RESOURCE_NOT_FOUND` |
| OWNED_RESOURCE | `GET /challenge-attempts/{attemptId}` | `RESOURCE_NOT_FOUND` |
| OWNED_RESOURCE | `POST /challenge-attempts/{attemptId}/self-explanation`, `/hints`, `/submissions`, `/abandon` | `RESOURCE_NOT_FOUND` |
| OWNED_RESOURCE | `POST /challenge-attempts/{attemptId}/submissions/{submissionNo}/retry` | `RESOURCE_NOT_FOUND` |
| OWNED_RESOURCE | `POST /reviews/{reviewItemId}/answer` | `RESOURCE_NOT_FOUND` |
| OWNED_RESOURCE | `PATCH /review-items/{reviewItemId}` | `RESOURCE_NOT_FOUND` |
| OWNED_RESOURCE | `GET /coach/reviews/{reviewId}`, `POST /coach/reviews/{reviewId}/retry`, `POST …/complete`, `DELETE …/content` | `RESOURCE_NOT_FOUND` |
| OWNED_RESOURCE | `POST /coach/reviews/{reviewId}/findings/{findingId}/responses`, `/hints`, `PATCH …/findings/{findingId}` | `RESOURCE_NOT_FOUND` |
| OWNED_RESOURCE | `GET /evidence/{evidenceId}`, `PATCH /evidence/{evidenceId}`, `POST …/accept`, `POST …/reject` | `RESOURCE_NOT_FOUND` |
| BODY_REFERENCE | `POST /evidence/drafts` (body `sourceLearningEventId` = A의 이벤트) | 400 `VALIDATION_FAILED` + field error `REFERENCE_NOT_FOUND` |
| OWNED_RESOURCE | `GET /weekly-reviews/{weekStartDate}`, `PUT …/reflection` (B에게 해당 주 리뷰 없음) | `RESOURCE_NOT_FOUND` |
| OWNED_RESOURCE | `GET /jobs/{jobId}`, `DELETE /jobs/{jobId}` | `RESOURCE_NOT_FOUND` |
| SCOPED_COLLECTION | `GET /me`, `PATCH /me`, `GET /me/export`, `GET /career-goal`, `GET /skills/tree`(공용 catalog, 사용자 데이터 없음 — A의 데이터가 섞이지 않음만 확인), `GET /skills/me`, `GET /skills/{skillId}/history` (공용 skill ID), `GET /plans/active`, `GET /plans`, `GET /plans/active/budget`, `GET /today`, `GET /learning-sessions`, `GET /challenges`, `GET /reviews/due`, `GET /review-items`, `GET /coach/reviews`, `GET /dashboard`, `GET /evidence`, `GET /evidence/export`, `GET /weekly-reviews`, `GET /thinking-patterns/trend`, `GET /jobs`, `GET /diagnostics/suggestions` | — |

- 404 `code` 열은 `05-api-spec.md`의 endpoint별 오류 표와 같아야 한다. 다르면 `05`를 기준으로 catalog를 고친다.
- `Kind.ACCOUNT_ACTION`(A의 ID를 넣을 위치가 없는 계정·생성 요청 — ISO-3·ISO-4만 적용): `DELETE /me`, `POST /me/calendar-token`, `POST /onboarding`, `POST /today/generate`, `POST /plans`, `POST /learning-sessions`(body 없음), `POST /review-items`, `POST /coach/reviews`, `POST /challenges/generate`, `POST /evidence`, `POST /jobs`, `PUT /career-goal`. catalog에 이 Kind로 등록한다.
- 제외 목록(`EndpointCatalogCompletenessTest`): `GET /api/v1/calendar/{token}.ics` — Bearer 인증을 쓰지 않으므로 `CalendarFeedSecurityTest`가 검증한다.

### 9.3 Catalog 완전성

`EndpointCatalogCompletenessTest`(integration)가 `RequestMappingHandlerMapping.getHandlerMethods()`의 모든 `/api/v1/**` 매핑을 읽어, 각 매핑이 `UserOwnedEndpoints` catalog 또는 제외 목록(`GET /api/v1/calendar/{token}.ics`)에 있는지 확인한다. 새 endpoint를 추가하고 catalog를 갱신하지 않으면 실패한다.

---

## 10. AI 테스트

### 10.1 `FakeAiProvider` fixture

- 형식·위치·선택 방법은 `17-ai-integration.md` §12.2가 기준이다: `backend/src/test/resources/ai-fixtures/<OPERATION>/<case>.json`, `attempts[]`(호출 순서별 응답, `stopReason`, `output`/`outputRaw`, `simulate`, `usage`), 선택은 `fakeAiProvider.use(AiOperation.X, "case")`, 지정이 없으면 `default`.
- `test` profile의 provider는 `fake`다(`03` §10). 실제 API는 호출하지 않는다.
- 테스트 전용 확인 기능(`FakeAiProvider`의 test hook, main 코드에서 호출 금지):

| 메서드 | 용도 |
|---|---|
| `receivedRequests(AiOperation)` | provider가 받은 `AiRequest` 목록 — 마스킹본 전달 확인(§10.4) |
| `callCount(AiOperation)` | AI 호출 횟수 — HL-1 캐시, idempotency 재생 확인 |
| `blockUntilReleased(AiOperation)` / `release(AiOperation)` | `CountDownLatch`로 호출을 붙잡아 동시성 테스트(E2E-06 7번, `SyncAiVersionConflictTest`) |
| `reset()` | `@AfterEach`에서 선택·기록 초기화 |

- 모든 fixture의 `output`이 스키마에 맞는지는 `OutputSchemaConsistencyTest`(`17` §12.1)와 함께 `AiFixtureSchemaTest`가 검사한다. 가드 위반을 일부러 담은 fixture는 파일 이름에 `-violation`을 붙이고 JSON 형식만 검사한다.

### 10.2 결정적 AI 테스트

테스트 목록과 vector는 `17-ai-integration.md` §12.1이 기준이다. 이 문서는 계층·태그와 추가 확인 항목만 정한다.

| 테스트 | 기준 vector | 계층 | 추가 확인 |
|---|---|---|---|
| `SecretMaskerTest`, `SecretMaskerPerformanceTest` | `17` §7.3 V1~V23, 30KB **200ms** 이내 | unit | 입력 문자열은 런타임 조합(`07` §11.3). 공유 CI runner에서 벽시계 단언은 흔들리므로 상한을 넉넉히 둔다(§16 flaky 예방). 실제 목표는 10ms이고 회귀 감시는 값 자체가 아니라 실패 여부로 한다 |
| `CodeDetectorTest`, `CodeLeakGuardTest` | `17` §6.3 C1~C11 | unit | HL-8 경계(`06` §9.1) |
| `EnumGuardTest`, `FindingCountGuardTest`, `SkillCodeGuardTest`, `LanguageGuardTest` | `17` §6.4~§6.7 | unit | — |
| `VerificationGuardTest` | `06` §10 vector 7행 + `17` §6.2 추가 vector | unit | 하위 도메인 허용(`sub.docs.spring.io`), 유사 도메인 거부(`docs.spring.io.evil.com`), URL fetch 없음(ArchUnit `ARCH-19`) |
| `AiCostCalculatorTest` | `17` §8.4 K1~K6 | unit | — |
| `AiBudgetGuardTest` | `17` §8.5 B1~B17 | integration | §10.3 |
| `AiGatewayTest` | `17` §5.3 표 전체 | integration | 가드 위반 재시도는 **ASYNC만 1회**(`attempt_no` 2), SYNC는 재시도 없이 502 `AI_OUTPUT_INVALID`. SDK 자체 재시도는 끔(`maxRetries(0)`), provider 호출마다 `ai_call_log` 1행(실패 포함, 원문 없음) |
| `PromptRegistryTest`, `PromptImmutabilityTest`, `OutputSchemaConsistencyTest`, `DeepSeekAiProviderRequestTest` | `17` §12.1 | unit | — |
| `AiGatewayTransactionGuardTest` | §7 런타임 이중 방어 | integration | — |

### 10.3 예산 경계 (`AiBudgetGuardTest`, integration)

- **벡터 기준값**: 운영 기본 월 예산은 USD 3(= 3,000,000 micro, 경고 2,400,000)이지만, 이 절과 `17` §8.5의 벡터는 `application-test.yml`이 고정한 **test profile 값 USD 25**(25,000,000 micro) 기준이다. 예산 값을 바꿔도 벡터는 그대로 쓴다.
- 결정(DEC-06, `03` §9): 월 예산은 **서비스 전체** 합계, 월 경계는 `devpilot.time.default-zone`(Asia/Seoul) 달력 월. 일일 한도는 사용자별, 사용자 plan-day 시작부터. 동시 실행은 사용자별 (진행 중 동기 호출 + `PENDING`/`RUNNING` 비동기 작업) ≥ 2.
- `17` §8.5 B1~B17를 그대로 파라미터화 케이스로 옮기고, 통합 테스트에서만 확인할 수 있는 아래 항목을 추가한다. 누적 비용은 `ai_call_log` 행을 직접 넣어 만든다(서로 다른 사용자 2명에 나눠 넣어 서비스 전체 합계를 검증).

| # | 조건 | 기대 |
|---|---|---|
| BI-01 | 사용자 A 10,000,000 + 사용자 B 9,999,999 micro USD (합 79.99996%) 후 A 호출 1회로 20,000,000 이상 | 호출 허용, 이후 A·B 모두 `aiStatus = BUDGET_WARNING`, `AI_BUDGET_WARNING` 정확히 1회 |
| BI-02 | 합계 25,000,000 | A·B 모두 429 `AI_MONTHLY_BUDGET_EXCEEDED`, `Retry-After` = 다음 달 1일 00:00 KST까지 초, `ai_call_log.status = BUDGET_BLOCKED` 1행, `AI_BUDGET_BLOCKED`(`reason = MONTHLY_BUDGET_EXCEEDED`), provider 호출 0 |
| BI-03 | BI-02 상태에서 `POST /today/generate`, `POST /reviews/{id}/answer`(`evaluate=false`), `GET /dashboard` | 모두 정상 (AC-12, AC-13) |
| BI-04 | BI-02 상태에서 `POST /reviews/{id}/answer`(`evaluate=true`) | 200, 답변 저장, `evaluationSkippedReason = AI_BUDGET_EXCEEDED` |
| BI-05 | BI-02 상태에서 `POST /challenge-attempts/{id}/submissions`(S3), `POST /coach/reviews`(**S4에 추가**) | 429, submission·coach_review 행 없음 |
| BI-06 | clock `2026-10-31T15:00:00Z`(= 11-01 00:00 KST) | 허용, `ENABLED` |
| BI-07 | 일일 한도 거부 | 429 `AI_DAILY_LIMIT_EXCEEDED`, `Retry-After` = 다음 plan-day 시작까지 초, 다른 사용자는 허용 |
| BI-08 | 같은 사용자 `PENDING` 비동기 작업 1개 + 동기 hint 1개 진행 중(`blockUntilReleased`)에 비동기 시작 요청 | 429 `AI_CONCURRENCY_LIMIT`, `Retry-After: 5`, 저장 없음 |

### 10.4 순서·동시성·대체 동작

| 테스트 | 내용 |
|---|---|
| `CoachReviewMaskingOrderTest` | (1) `content` 또는 `userSelfReview`에 private key → 422 `SECRET_DETECTED_BLOCKED`, `coach_review` 0행, `ai_call_log` 0행, 예산 집계 변화 없음, `SECRET_BLOCKED` 1회 (2) `content`와 `userSelfReview`에 일반 secret 각 1개 → 202, `maskedSecretCount = 2`, 저장값에 원문 secret 없음, `receivedRequests(COACH_REVIEW)`에 원문 secret 없음 (3) 예산 초과 상태 → 마스킹은 통과해도 429, 저장 없음 (AC-14, I-14) |
| `SecretMaskingEndpointsTest` | (격리 catalog처럼 **해당 endpoint가 생기는 Sprint에 행을 추가**한다) `17` §7.1 표의 endpoint·필드마다: private key → 422 + 행 없음, 일반 secret → 저장값 마스킹본 (coach finding 응답 `text`, 자기설명, 제출 `answerText`·`code`, 복습 `answerText`, 세션 `selfReflection`, `jobDescription`) |
| `SyncAiVersionConflictTest` | 동기 AI(`HINT_GENERATE`) 실행 중(`blockUntilReleased`) 다른 요청이 대상 `version`을 바꾸면 결과를 저장하지 않고 409 `CONCURRENT_MODIFICATION` (`03` §5.3) |
| `OrphanAsyncTaskJobIntegrationTest` | `RUNNING` + `status_updated_at = now − 10분 1초` → `FAILED(INTERRUPTED)`, `now − 9분 59초` → 변화 없음 |
| `ReviewEvaluateFallbackTest` | `REVIEW_EVALUATE` fixture `simulate: TIMEOUT` → 답변 200 저장, `evaluatedOutcome = NOT_EVALUATED`, `evaluationSkippedReason = AI_TIMEOUT` |
| `CoachResponseFeedbackFallbackTest` | `COACH_RESPONSE_FEEDBACK` fixture `simulate: PROVIDER_ERROR` → 응답 `text`(마스킹본) 저장, finding `USER_RESPONDED`, `feedbackSkippedReason = AI_UNAVAILABLE`, `user_identified_issue` 변화 없음 |
| `TodayChallengeProposalAiDisabledTest` | `aiStatus = DISABLED`(월 예산 도달) 또는 `BALANCE_EXHAUSTED`(공급자 잔액 소진)일 때 VALIDATED seed challenge가 있어도 main task가 `CHALLENGE`가 아님 (`06` §5.3 1번 조건) |
| `AiBalanceMonitorTest` | 402 수신 → `aiStatus = BALANCE_EXHAUSTED`, 이후 AI endpoint 503 `AI_UNAVAILABLE`(`Retry-After: 3600`), `AI_BALANCE_LOW` 감사 이벤트 1회 / `AiBalanceCheckJob`이 잔액 ≥ `min-balance-usd`를 받으면 해제 (`17` §8.7) |

### 10.5 Eval

실제 모델 eval의 case 구조, 합격 기준, 실행 조건은 `17-ai-integration.md` §12가 기준이다. 이 문서의 테스트는 eval을 대신하지 않고, eval은 PR CI 게이트가 아니다. prompt·모델·가드를 바꾼 PR은 PR 템플릿 "Tests"에 eval 실행 결과 링크를 적는다.

---
## 11. API E2E flows

- 실행 환경: `@ApiFlowTest`(`RANDOM_PORT`) + Testcontainers + `TestJwksServer` + `FakeAiProvider` + `MutableClock`. 비동기 task는 실제 `aiTaskExecutor`에서 실행되고 Awaitility로 기다린다(최대 10초, 간격 100ms).
- 공통 시작 시각: `2026-10-05T10:00:00Z` (KST 19:00, plan-day `2026-10-05`, `dayStartHour = 4`).
- 모든 POST는 새 `Idempotency-Key`(E2E-06 제외). 응답 `status`, `code`, 핵심 필드와 DB 상태(사용자 범위 SQL)를 함께 확인한다.
- 성공 응답 status(200/201/202/204)는 `05-api-spec.md`의 endpoint 정의를 따른다. 아래 표에 적은 status는 `05-api-spec.md`에 명시된 것만이다.

### E2E-01 온보딩 → Today → 세션 완료 (`OnboardingToTodayFlowTest`, AC-02, AC-11, AC-17)

| # | 요청 | 기대 |
|---|---|---|
| 1 | `GET /me` (첫 요청) | 200, `onboardingCompleted = false`, `app_user` 1행, `AUTH_USER_PROVISIONED` |
| 2 | `GET /today` | 409 `ONBOARDING_REQUIRED` |
| 3 | `POST /onboarding` — 카테고리 자기평가 13개, `dayStartHour = 4`, 평일 45/주말 240, 목표일 `2027-04-01` | 201, `activePlan.planVersion = 1` |
| 4 | `POST /onboarding` 다시 (새 키) | 409 `ONBOARDING_ALREADY_COMPLETED` |
| 5 | `GET /plans/active` | milestone 1개 이상, `plan_skill_target` = role target 복사(`adjustment = ROLE_DEFAULT`) |
| 6 | DB: `review_item` | seed 카드 10장 복사, 정렬 앞 5장 `due_at = 2026-10-04T19:00:00Z`, 다음 5장 `2026-10-05T19:00:00Z` (`06` §6.3) |
| 7 | `GET /today` | 404 `TODAY_NOT_GENERATED` |
| 8 | `POST /today/generate` `{availableMinutes: 45, energyLevel: NORMAL}` | main task 정확히 1개, `reasons` 1~3개, REVIEW task `estimatedMinutes = 8`(dueCount 5 — `06` §6.5 `due_at < planDayStart(today + 1)` 기준으로 첫 묶음 5장만 포함 → `min(ceilDiv(15, 2) = 8, 11, 40)`), main `estimatedMinutes ≤ floorDiv(37 × 11000, 10000) = 40` |
| 9 | `PATCH /today/tasks/{mainId}` `{status: IN_PROGRESS, version}` | 200 |
| 10 | `POST /learning-sessions` `{learningTaskId: mainId}` | `IN_PROGRESS`, `SESSION_STARTED` 이벤트 |
| 11 | clock +40분 → `POST /learning-sessions/{id}/complete` `{actualMinutes: 35}` | `COMPLETED`, `SESSION_COMPLETED` 이벤트 `plan_date = 2026-10-05` |
| 12 | `PATCH /today/tasks/{mainId}` `{status: COMPLETED, version}` | 200, `completed_at` 설정 |
| 13 | `POST /today/generate` `{force: false}` | 409 `TODAY_ALREADY_COMPLETED` |
| 14 | clock `2026-10-05T18:59:59Z`(KST 03:59:59) → `GET /today` | 같은 plan-day 계획 반환 |
| 15 | clock `2026-10-05T19:00:00Z`(KST 04:00) → `GET /today` | 404 `TODAY_NOT_GENERATED` (새 plan-day) |

### E2E-02 Seed 복습 답변 → 간격 (`SeedReviewFlowTest`, AC-05, AC-09)

| # | 요청 | 기대 |
|---|---|---|
| 1 | 온보딩 완료 사용자 (`TestApi.onboard`) | — |
| 2 | `GET /reviews/due?limit=20` | 5장(E2E-01 8번과 같은 기준), 각 항목에 `prompt`, `expectedAnswer`, `rubric` 포함 |
| 3 | 카드 X: `POST /reviews/{X}/answer` `{selfRating: GOOD, hintLevel: SELF_EXPLAIN, evaluate: false, answerText}` | `finalRating = GOOD`, `adjustedBy = []`, `intervalBefore = 1`, `intervalAfter = 2`, 다음 due `2026-10-06T19:00:00Z` |
| 4 | 카드 Y: `{selfRating: EASY, hintLevel: CONCEPT_HINT}` | `finalRating = HARD`, `adjustedBy = [HINT_CAP_HARD]`, `intervalAfter = 2` |
| 5 | 카드 Z: `{selfRating: GOOD, hintLevel: FULL_EXAMPLE}` | `finalRating = AGAIN`, `adjustedBy = [HINT_CAP_AGAIN]`, `intervalAfter = 1`, `consecutive_failures = 1` |
| 6 | `GET /reviews/due` | 2장 |
| 7 | DB | `review_answer` 3행, `REVIEW_ANSWERED` 이벤트 3행, 각 카드 skill의 `knowledge_level` 0→1 (`K1_ANY_EVENT`) 및 `skill_state_change` 행 (카드가 같은 skill이면 cooldown으로 1행) |
| 8 | 3번 요청을 같은 `Idempotency-Key`·같은 body로 재전송 | 같은 body, 헤더 `Idempotent-Replayed: true`, `review_answer` 3행 유지 |

### E2E-03 Challenge → hint → 제출 → 비동기 평가 → 복습 항목 → skill 변화 (`ChallengeAttemptFlowTest`, AC-04, AC-16, AC-09)

전제: 테스트 seed challenge C (`VALIDATED`, difficulty 2, skill S 1개, `hints_json` 1~3단계, rubric R1 4000 IMPLEMENTATION / R2 4000 EXPLANATION / R3 2000 IMPLEMENTATION).

| # | 요청 | 기대 |
|---|---|---|
| 1 | `GET /challenges/{C}` | `rubric`, `expectedConcepts` 없음 |
| 2 | `POST /challenges/{C}/attempts` | 201 `STARTED`, `CHALLENGE_STARTED`, S의 K 0→1 |
| 3 | `POST /challenge-attempts/{A}/hints` `{requestedLevel: CONCEPT_HINT}` | 409 `SELF_EXPLANATION_REQUIRED` |
| 4 | `POST /challenge-attempts/{A}/self-explanation` `{text}` | `SELF_EXPLANATION_SUBMITTED`, E 0→1 |
| 5 | `POST …/hints` `{requestedLevel: CONCEPT_HINT}` | 내용 = `hints_json.CONCEPT_HINT`, `maxHintLevel = CONCEPT_HINT`, `HINT_DISCLOSED.skippedLevels = [QUESTION_ONLY]`, AI 호출 0 |
| 6 | `POST …/hints` `{requestedLevel: QUESTION_ONLY}` | CONCEPT_HINT 내용 반환, AI 호출 0, `hint_disclosure` 1행 유지 (HL-1) |
| 7 | `fakeAiProvider.use(CHALLENGE_EVALUATE, "r1-met-only")` → `POST …/submissions` `{code, language: JAVA, answerText}` | 202, submission `PENDING`, `CHALLENGE_SUBMITTED`, I 0→1 |
| 8 | Awaitility: `GET /challenge-attempts/{A}` | submission `COMPLETED`, `evaluatedOutcome = PARTIAL`(coverage 4000), attempt `EVALUATED`, `outcome = PARTIAL`, `rubricCoverageBp = 4000`, `explanationCoverageBp = 0` |
| 9 | `GET /challenges/{C}` | 이제 `rubric`, `expectedConcepts` 포함 |
| 10 | DB `review_item` | `concept_key = CHALLENGE:{C}`, `review_type = EXPLAIN`, `source_type = CHALLENGE_ATTEMPT`, `due_at = 2026-10-05T19:00:00Z` |
| 11 | DB `skill_state_change` | S: K 0→1 `K1_ANY_EVENT`, E 0→1 `E1_ANY_EXPLANATION`, I 0→1 `I1_ATTEMPTED` 3행만 (E2는 coverage 0이라 없음) |
| 12 | clock +25시간, `fakeAiProvider.use(CHALLENGE_EVALUATE, "all-met")` → `POST …/submissions` | 202, attempt `SUBMITTED`, `submission_count = 2` |
| 13 | Awaitility | `evaluatedOutcome = CORRECT`, `outcome = SOLVED_WITH_HINTS`(maxHint CONCEPT_HINT), `CHALLENGE_EVALUATED`, I 1→2 `I2_SOLVED_GUIDED`, E 1→2 `E2_PARTIAL`(`explanationCoverageBp = 10000`, 독립 아님 → E3 아님), 새 review item 없음(`06` §8.3 조건 미충족) |
| 14 | `fakeAiProvider.use(CHALLENGE_EVALUATE, "timeout")` → 3번째 제출 | Awaitility: submission `FAILED`, `failureCode = AI_TIMEOUT`, attempt `SUBMITTED` 유지 |
| 15 | `fakeAiProvider.use(CHALLENGE_EVALUATE, "all-met")` → `POST …/submissions/3/retry` | 202 → `COMPLETED` |
| 16 | 완료된 제출에 `POST …/submissions/2/retry` | 409 `AI_TASK_NOT_RETRYABLE` |

### E2E-04 Coach review → 응답 → 완료 → thinking observation (`CoachReviewFlowTest`, AC-06, AC-14, AC-19)

fixture `coach-review/two-findings`: F1(`RESOURCE_LIFECYCLE`, `BUG`, `mentionedByUser = true`, skill S1), F2(`EXCEPTION_STRATEGY`, `RISK`, `mentionedByUser = false`, skill S2), `incorrectClaims = [CONCURRENCY]`.

| # | 요청 | 기대 |
|---|---|---|
| 1 | `POST /coach/reviews` `{contentType: CODE, language: JAVA, content(런타임 조합 fake secret 1개 포함), confidentialConsent: true, userSelfReview: "스트림을 닫는지 모르겠다", context}` | 202 `{status: PENDING, maskedSecretCount: 1}` |
| 2 | 같은 요청 `confidentialConsent: false` (새 키) | 400 `VALIDATION_FAILED` |
| 3 | Awaitility `GET /coach/reviews/{R}` | `COMPLETED`, findings 2개, 수정 코드 필드 없음, `verificationStatus`·`confidence` 존재 |
| 4 | DB | `content`에 원문 secret 없음, `content_retention_until = created_at + 30일`, `thinking_pattern_observation(CONCURRENCY, INCORRECT_CLAIM)` 1행 |
| 5 | `fakeAiProvider.use(COACH_RESPONSE_FEEDBACK, "identified")` → `POST /coach/reviews/{R}/findings/{F2}/responses` `{text}` | F2 `USER_RESPONDED`, `userIdentifiedIssue = true` |
| 6 | `fakeAiProvider.use(HINT_GENERATE, "question-only")` → `POST …/findings/{F2}/hints` `{requestedLevel: QUESTION_ONLY}` | hint 반환, `HINT_DISCLOSED` |
| 7 | `PATCH …/findings/{F1}` `{status: RESOLVED, version}` | 200 |
| 8 | `POST /coach/reviews/{R}/complete` | `closedAt` 설정 |
| 9 | DB | F1 `discovered_by = MENTIONED_UNPROMPTED`, F2 `FOUND_AFTER_HINT`; observation `RESOURCE_LIFECYCLE/MENTIONED_UNPROMPTED`, `EXCEPTION_STRATEGY/FOUND_AFTER_HINT`; `COACH_FINDING_CLOSED` 2행, `COACH_REVIEW_COMPLETED`; `skill_state_change`에 S1·S2의 DEBUGGING 0→1 `D1_ANY_REVIEW` 포함 |
| 9a | DB `review_item` (`06` §9.4) | F2(RISK, `FOUND_AFTER_HINT`, skill S2) → `concept_key = COACH:{S2 code}:EXCEPTION_STRATEGY`, `review_type = EXPLAIN`, `source_type = COACH_FINDING`, `source_id = F2`, `prompt` = F2 `learning_question`, `due_at = 2026-10-05T19:00:00Z`. F1(`MENTIONED_UNPROMPTED`)은 항목 없음 |
| 10 | `PATCH …/findings/{F2}` `{status: DISMISSED, version}` | 409 `REVIEW_ALREADY_CLOSED` |
| 11 | `DELETE /coach/reviews/{R}/content` | 성공, `content = null`, `content_purged_at` 설정, findings 유지 |
| 12 | `POST /coach/reviews` content에 `-----BEGIN OPENSSH PRIVATE KEY-----` 블록 | 422 `SECRET_DETECTED_BLOCKED`, 새 행 0, `ai_call_log` 증가 0 |
| 13 | clock +30일 1초 → `CoachContentPurgeJob` 메서드 직접 호출 (다른 review R2) | R2 `content = null` |

### E2E-05 Replan preview → commit → 새 version (`ReplanFlowTest`, AC-01, AC-03, AC-24)

| # | 요청 | 기대 |
|---|---|---|
| 1 | 온보딩 완료, 활성 plan P1(`planVersion 1`) | — |
| 2 | `POST /plans/{P1}/replan/preview` (**`Idempotency-Key` 없음**) — MUST milestone 기간을 줄여 risk HIGH가 되는 편집안 | 200, `riskLevel = HIGH`, `deferSuggestions` 1개 이상, `riskAfterSuggestions` 존재. DB plan 1행 유지 |
| 3 | `POST /plans/{P1}/replan` `{version, reason, milestones, acceptedDeferrals: [첫 제안 skill]}` | 새 plan P2 `planVersion = 2`, `supersedesPlanId = P1` |
| 4 | `GET /plans/active` / `GET /plans/{P1}` / `GET /plans` | P2 / `SUPERSEDED` + `supersededAt` / 2개 |
| 5 | DB | P2 `plan_skill_target`에서 수락한 skill `deferred = true`, `adjustment = DEFERRED`; `PLAN_REPLANNED` 이벤트 `{fromVersion: 1, toVersion: 2}`; 감사 이벤트 `PLAN_REPLANNED`; `plan_progress_snapshot(P2, 2026-10-05)` |
| 6 | 과거 `daily_plan` | `learning_plan_id = P1` 유지 |
| 7 | `POST /plans/{P1}/replan` (새 키) | 409 `PLAN_NOT_ACTIVE` |
| 8 | `PATCH /plans/{P2}/milestones/{M}` `{status: IN_PROGRESS, version: <이전 값>}` | 409 `CONCURRENT_MODIFICATION` |
| 8a | `POST /plans/{P2}/replan` 같은 skill을 `acceptedDeferrals`와 `restoredDeferrals`에 동시에 | 400 `VALIDATION_FAILED`, 새 plan 없음 |
| 8b | `POST /plans/{P2}/replan` `{version, reason, milestones, restoredDeferrals: [3번에서 defer한 skill]}` | P3 `planVersion = 3`, 해당 skill `deferred = false`, `adjustment = USER_EDITED` (`06` §11.2) |
| 9 | 동시 replan은 `ReplanConcurrencyIntegrationTest`(§8.2) | — |

### E2E-06 Idempotency (`IdempotencyTest`, AC-23)

| # | 요청 | 기대 |
|---|---|---|
| 1 | `POST /today/generate` 헤더 없음 | 400 `IDEMPOTENCY_KEY_REQUIRED` |
| 2 | `POST /today/generate` 키 `abc` (8자 미만) | 400 `VALIDATION_FAILED` |
| 3 | `POST /challenges/generate` 키 K1, body B1 | 202, Awaitility로 생성 완료, `CHALLENGE_GENERATE` 호출 1회 |
| 4 | K1 + B1 재전송 | 202, 같은 body, `Idempotent-Replayed: true`, AI 호출 여전히 1회, challenge 행 1개 |
| 5 | K1 + B2 (body 필드 하나 다름) | 422 `IDEMPOTENCY_KEY_REUSED` |
| 6 | K1 + B1, JSON 키 순서·공백만 다름 | 재생 (canonical hash, `03` §5.4) |
| 7 | `fakeAiProvider.blockUntilReleased(HINT_GENERATE)`로 붙잡은 상태에서 같은 키 K2로 동기 hint 요청 2개 동시 | 1개 200, 1개 409 `IDEMPOTENCY_IN_PROGRESS` |
| 8 | self-explanation 없이 hint 요청 키 K3 → 409 `SELF_EXPLANATION_REQUIRED` → self-explanation 제출 → 같은 K3로 같은 hint 요청 | 두 번째는 재생이 아니라 실행되어 200 (실패 시 record 삭제) |
| 9 | 사용자 B가 K1 + B1 | 재생 아님, B의 요청으로 202 |
| 10 | clock +24시간 1초 → `RetentionCleanupJob` 직접 호출 → K1 + B1 | 새로 실행(AI 호출 2회) |
| 11 | `PATCH`/`PUT`/`DELETE` 요청에 `Idempotency-Key` 헤더 포함 | 헤더 무시, 정상 처리 |
| 12 | `POST /plans/{planId}/replan/preview`에 `Idempotency-Key` 헤더 포함, 같은 키로 2회 | 둘 다 200으로 새로 계산, `idempotency_record` 행 없음 (`05` §1.7) |

### E2E-07 AI 비활성 (`AiDisabledFlowTest`, AC-12)

`@ApiFlowTest` + `@TestPropertySource(properties = "devpilot.ai.provider=disabled")` (이 테스트 전용 context). AI를 쓸 수 없을 때 자기채점 같은 대체 경로는 없다(`17-ai-integration.md` §3.10).

| # | 요청 | 기대 |
|---|---|---|
| 1 | `GET /me` | 200, `aiStatus = DISABLED` (`FakeAiProvider`는 조건부라 등록되지 않고 `DisabledAiProvider`가 쓰인다, §3.3) |
| 2 | `POST /onboarding`, `GET /plans/active`, `GET /dashboard` | 모두 정상 |
| 3 | `POST /today/generate` (테스트 seed에 VALIDATED challenge 있음) | 정상, main task `taskType ≠ CHALLENGE` (`06` §5.3) |
| 4 | `POST /reviews/{id}/answer` `{evaluate: true, answerText}` | 200, `evaluatedOutcome = NOT_EVALUATED`, `evaluationSkippedReason = AI_UNAVAILABLE`, 간격 계산 정상 |
| 5 | seed challenge attempt → self-explanation → hint `QUESTION_ONLY`~`DIRECTION` | 정상 (`hints_json`, AI 호출 없음) |
| 6 | hint `PSEUDOCODE` + `acknowledgeEvidenceImpact: true` | 503 `AI_UNAVAILABLE`, `hint_disclosure` 행 없음 |
| 7 | `POST /challenge-attempts/{id}/submissions` | 503 `AI_UNAVAILABLE`, `challenge_submission` 행 없음, attempt 상태·`submission_count` 변화 없음 |
| 8 | `POST /challenges/generate` | 503 `AI_UNAVAILABLE`, `challenge` 행 없음 |
| 9 | `POST /coach/reviews` | 503 `AI_UNAVAILABLE`, `coach_review` 행 없음 |
| 10 | 7~9와 같은 `Idempotency-Key`로 재요청 | 재생이 아니라 다시 503 (실패 응답은 저장하지 않음, `05` §1.7) |
| 11 | 1~10 동안 로그 | ERROR 레벨 0건 |

---

## 12. Flutter 테스트

| 종류 | 대상 · 파일 | 규칙 |
|---|---|---|
| Controller 단위 | `test/features/today/presentation/today_controller_test.dart` 등 모든 `*Controller` | `ProviderContainer(overrides: [todayRepositoryProvider.overrideWithValue(FakeTodayRepository())])`. 상태 전이(loading → data/error), `Idempotency-Key`가 재시도 시 유지되고 새 행동 시 바뀌는지 |
| Repository 매핑 | `*_repository_test.dart` | fake `Dio` adapter(`HttpClientAdapter` 구현)로 요청 path·method·헤더·body와 응답 매핑 확인 |
| 인터셉터 | `test/core/api/interceptors_test.dart` | 순서(`08-coding-conventions.md` §8.4), 401 → refresh 1회 → 재시도, POST에만 `Idempotency-Key`, ProblemDetail → `ApiException` |
| 오류 문구 | `error_message_mapper_test.dart` | 매핑된 code → ARB, 모르는 code → `detail`, 둘 다 없음 → `errorUnknown` |
| JSON round-trip | `test/features/**/data/models/*_test.dart` | fixture `test/fixtures/api/<name>.json`(OpenAPI 예시에서 복사) → `fromJson` → `toJson` → 원본과 동일. **모르는 enum 값**(`"status": "ARCHIVED_V2"`) → `unknown`, `List<Enum>` 안의 모르는 값 → `unknown`, 명시적 `null` 필드 허용 |
| Widget: SCR-TODAY | `today_screen_test.dart` | 상태 5개: loading skeleton / `TODAY_NOT_GENERATED` → 시간 칩·컨디션 입력 / 생성 후 main task 1개 + reason 1~3개 + 복습 N장 / 오류 배너 + 재시도 / AI unavailable 배너(비-AI 기능 버튼 활성 유지). 360×800 화면에서 overflow 없음, "시작" 버튼 44px 이상 |
| Widget: SCR-REVIEW | `review_screen_test.dart` | 답 입력 전 `expectedAnswer`·rubric 미표시 / "힌트 보기" → rubric 첫 항목만 표시 후 제출 body `hintLevel = CONCEPT_HINT` / "정답 먼저 보기" → `FULL_EXAMPLE` / 자기평가 4버튼 / `adjustedBy` 안내 표시 / 마지막 카드 후 완료 상태 |
| Widget: Markdown | `markdown_view_test.dart` | `07-security-and-privacy.md` §9.5 (raw HTML 텍스트, 비 https 링크 비활성, 이미지 미렌더링) |
| Integration | `integration_test/onboarding_to_today_test.dart` | 아래 |

Integration test (`onboarding_to_today_test.dart`):
- `ProviderScope` override로 `AuthGateway`를 로그인 상태 fake로, 각 repository를 in-memory fake API(`test/fixtures/api/` 응답 사용)로 바꾼다. 실제 backend에 연결하지 않는다(전체 스택은 §11 E2E-01이 검증).
- 흐름: 앱 시작 → 온보딩 4단계 입력 → "그대로 시작" → Today 생성 입력 → 45분·보통 선택 → 생성 → main task 제목과 reason 표시 → "시작" → 상태 `IN_PROGRESS` 표시.
- 실행: `fvm flutter drive --driver=test_driver/integration_test.dart --target=integration_test/onboarding_to_today_test.dart -d web-server --browser-name=chrome` (chromedriver 필요).
- **Flutter web은 canvas로 렌더링하므로 Selenium·Playwright 같은 DOM 기반 자동화는 쓰지 않는다.** 요소 찾기는 `find.byKey(const Key('today.generateButton'))`처럼 Flutter finder와 위젯 `Key`로 한다. Key 이름은 `<feature>.<element>` 형식.

---

## 13. 성능 스모크

NFR-02: non-AI API p95 < 1000ms.

| 항목 | 값 |
|---|---|
| 실행 시점 | S2 종료 전(실사용 시작 전), S5 종료 전. 수동 |
| 환경 | 로컬 `infra/compose.perf.yml`: api 컨테이너 `cpus: 2`, `mem_limit: 1.5g`(운영 서버 조건, `10` §3.3), PostgreSQL 16 컨테이너, `SPRING_PROFILES_ACTIVE=perf`(= `prod` 설정 + fake AI + 테스트 JWKS + rate limit 완화 `requests-per-minute: 100000`) |
| 네트워크 가정 | 운영 DB는 같은 호스트라 왕복 지연이 작다. 대신 tailnet 구간(클라이언트 ↔ 서버) 지연이 더해진다. 결과 p95가 700ms를 넘으면 원인을 조사한다 |
| 토큰 | `./gradlew perfToken`(test source의 `TestJwtFactory` 사용)으로 2시간짜리 토큰 3개 생성 → `K6_TOKENS` 환경변수 |
| 데이터 | `perf/seed.sql` (사용자당) — skill 80, `user_skill_state` 80, `review_item` 400(오늘 due 40), `review_answer` 3,000, `learning_event` 6,000(180일), `learning_session` 300, `daily_plan` 180 + `learning_task` 540, plan version 3 + milestone 30, `challenge_attempt` 200 + submission 300, `coach_review` 50 + finding 250, `evidence_candidate` 40, `weekly_review` 26. 사용자 3명 |

`perf/smoke.js` 구성:

```javascript
export const options = {
  scenarios: { smoke: { executor: 'constant-vus', vus: 5, duration: '3m' } },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    'http_req_duration{endpoint:me}': ['p(95)<1000'],
    'http_req_duration{endpoint:today}': ['p(95)<1000'],
    'http_req_duration{endpoint:reviews_due}': ['p(95)<1000'],
    'http_req_duration{endpoint:review_answer}': ['p(95)<1000'],
    'http_req_duration{endpoint:today_generate}': ['p(95)<1000'],
    'http_req_duration{endpoint:plans_active}': ['p(95)<1000'],
    'http_req_duration{endpoint:plan_budget}': ['p(95)<1000'],
    'http_req_duration{endpoint:skills_me}': ['p(95)<1000'],
    'http_req_duration{endpoint:dashboard}': ['p(95)<1000'],
    'http_req_duration{endpoint:learning_sessions}': ['p(95)<1000'],
    'http_req_duration{endpoint:coach_reviews}': ['p(95)<1000'],
    'http_req_duration{endpoint:replan_preview}': ['p(95)<1000'],
  },
};
// 각 VU: 토큰 1개 선택 → me → today → reviews/due → review answer(evaluate=false, 새 Idempotency-Key)
// → plans/active → plans/active/budget → skills/me → dashboard → learning-sessions → coach/reviews
// → (10회에 1회) today/generate force=true, replan/preview → sleep(1)
```

- 실패 기준: threshold 하나라도 실패. 결과 요약(`k6 --summary-export`)을 `perf/results/<date>.json`으로 저장하고 PR 설명에 p95 표를 붙인다(파일은 커밋하지 않음).
- 실패하면 Hibernate SQL 수(`hibernate.generate_statistics` perf profile만)와 느린 쿼리(`EXPLAIN ANALYZE`)를 확인하고 인덱스·projection으로 고친다.

---

## 14. 정적 분석 · 품질 게이트

### 14.1 CI 순서 (`ci.yml`)

트리거: `main`·`developer` push와 **두 브랜치로 향하는 PR**(`08-coding-conventions.md` §10.1). 필수 체크 4개(`security`, `backend`, `app`, `content`)는 두 브랜치 모두에 건다.

앞 단계가 실패하면 같은 job의 뒤 단계는 실행하지 않는다. job끼리는 병렬이다.

**job `backend`** (paths `backend/**`, `content/**`, `database/**`)

| 순서 | 단계 | 실패 기준 |
|---|---|---|
| 1 | `gradle/actions/wrapper-validation` | wrapper checksum 불일치 |
| 2 | `./gradlew spotlessCheck` | 포맷 차이 1건 |
| 3 | `./gradlew compileJava compileTestJava` | 컴파일 오류, main 경고 1건(`-Werror`), lockfile 불일치 |
| 4 | `./gradlew checkstyleMain checkstyleTest` | 위반 1건 |
| 5 | `./gradlew pmdMain spotbugsMain` | 위반 1건 |
| 6 | `./gradlew test` (tag `unit`: 규칙, ArchUnit, web slice) | 실패 1건 |
| 7 | `./gradlew integrationTest` (tag `integration`: Testcontainers, E2E) | 실패 1건 |
| 8 | `./gradlew jacocoTestCoverageVerification` | §15 기준 미달 |
| 9 | migration 불변 검사 (§8.1) | 기존 `V*.sql` 수정 |
| 10 | OpenAPI 스냅샷: 7단계의 `OpenApiSnapshotTest`(tag `integration`, test profile, `springdoc.api-docs.enabled=true`)가 `build/openapi/openapi.yaml`을 쓰고, `./gradlew openApiCheck`가 `docs/api/openapi.yaml`과 비교한다. 갱신은 `./gradlew openApiUpdate` (`18-project-setup-and-local-dev.md`) | 생성 파일 없음 또는 스냅샷과 차이 있음(갱신 커밋 필요) |

**job `app`** (paths `app/**`)

| 순서 | 단계 | 실패 기준 |
|---|---|---|
| 1 | `fvm flutter pub get --enforce-lockfile` | lockfile 불일치 |
| 2 | `dart run build_runner build --delete-conflicting-outputs` | 생성 오류 |
| 3 | `dart format --output=none --set-exit-if-changed lib test integration_test` | 변경 필요 파일 1개 |
| 4 | `fvm flutter analyze --fatal-infos --fatal-warnings` | 1건 |
| 5 | `app/tool/check_identifiers.sh` | 로마자 식별자 1건 |
| 6 | `fvm flutter test --coverage` | 실패 1건 |
| 7 | `fvm flutter build web --release --no-web-resources-cdn` | 빌드 실패 |

**job `content`** (paths `content/**`): `python3 content/tools/validate_content.py`(참조 검증기, `19-content-spec.md` §4) — 오류 1건. Java `ContentValidator`는 backend unit test(`ContentValidatorTest`)와 기동 시 검증에서 같은 규칙을 확인한다.

**job `security`** (모든 PR): `actions-pin-check` → `gitleaks` → `trivy-fs`. 실패 기준은 `07-security-and-privacy.md` §11.

- `main` ruleset의 필수 status check: `backend`, `app`, `content`, `security`. path 필터로 job이 건너뛰어진 경우 성공으로 보고하도록 각 job에 `if` 대신 path 판정 step을 둔다.
- `deploy.yml`은 `backend`·`app`을 다시 실행한 뒤 이미지 빌드 → `trivy-image` → 배포 → `smoke-headers.sh`(GitHub runner에서 공개 도메인 대상, 실패 시 직전 tag로 롤백) 순서다(`10-deployment-and-operations.md`).
- `app-integration` job(§12)은 `workflow_dispatch`와 `v*` tag push에서만 실행한다.

### 14.2 로컬 실행

- backend 전체: `./gradlew spotlessApply check` (`check`는 `test`, `integrationTest`, 정적 분석, 커버리지 검증을 포함하고 `aiEval`은 제외).
- app 전체: `dart format . && fvm flutter analyze && fvm flutter test`.
- PR을 만들기 전에 두 명령이 통과해야 한다(PR 템플릿 "Tests"에 결과 기록).

---

## 15. 커버리지

- 도구: JaCoCo. `test`와 `integrationTest`의 exec 데이터를 합쳐 계산한다.
- **전체 프로젝트 커버리지 게이트는 두지 않는다.**
- 게이트: 아래 패키지 각각 **line coverage ≥ 80%** (`jacocoTestCoverageVerification`, `element = PACKAGE`, `LINE COVEREDRATIO 0.80`).

| 패키지 | 주요 대상 |
|---|---|
| `com.devpilot.plan.domain` | `StudyBudgetCalculator`, `DeadlineRiskEvaluator`, `ReplanSuggestionPolicy` |
| `com.devpilot.skill.domain` | `SkillLevelRules`, `PlanningLevelPolicy` |
| `com.devpilot.review.domain` | `FinalRatingPolicy`, `RuleBasedV1Scheduler`, `DueReviewSelector` |
| `com.devpilot.today.domain` | `PlannerScoring`, `TaskProposalPolicy`, `TimeAllocator`, `ReasonTemplates` |
| `com.devpilot.training.domain` | `AttemptOutcomeCalculator` |
| `com.devpilot.learning.domain` | `HintLadderPolicy`, `ComebackModePolicy`, `RubricScorer` (여러 모듈이 공유, `03` §3.2) |
| `com.devpilot.coach.domain` | `DiscoveredByResolver` |
| `com.devpilot.evidence.domain` | `MetricsCalculator` |
| `com.devpilot.job.domain` | `JobFitClassifier` (S7부터) |
| `com.devpilot.common.time`, `com.devpilot.common.math` | `PlanDayCalculator`, `FixedPointMath` |
| `com.devpilot.integration.ai.guard`, `.masking`, `.budget` | 가드 6종, `SecretMasker`, `AiBudgetGuard`, `AiCostCalculator` |

- 해당 패키지가 아직 없는 Sprint에서는 규칙 목록에서 빠진다(빈 패키지로 통과시키지 않음).
- 커버리지를 올리려고 getter·record만 호출하는 테스트를 쓰지 않는다. 미달이면 vector·경계값 테스트를 추가한다.
- Flutter는 `--coverage`로 수집만 하고 게이트를 두지 않는다.

---

## 16. Flaky test 정책

| 규칙 | 내용 |
|---|---|
| 정의 | 코드 변경 없이 같은 커밋에서 통과와 실패가 모두 나온 테스트 |
| 예방 | 시간은 `MutableClock`, 대기는 Awaitility(`Thread.sleep` 금지, TEST-01), 사용자 데이터는 테스트마다 새 사용자(§4.2), 순서 의존 금지, 랜덤은 고정 seed, 포트는 `RANDOM_PORT`, 외부 네트워크 금지 |
| 재시도 | 자동 재시도 plugin·애노테이션 금지(TEST-05). CI "Re-run failed jobs"로 통과시킨 경우에도 flaky로 기록한다 |
| 발견 시 | GitHub issue(label `flaky`, 실패 로그·커밋 SHA) 생성 → **2 작업일 안에** 원인 수정 |
| 격리 | 2 작업일 안에 못 고치면 `@Disabled("flaky: #<issue>")`. 동시에 격리된 테스트는 최대 1개(TEST-03). 2개째가 필요하면 새 기능 작업을 멈추고 먼저 고친다 |
| 격리 금지 | `07-security-and-privacy.md` §16의 보안 테스트, §9 권한 격리, §6 JWT, §10.3 예산, ArchUnit. 이 테스트가 flaky면 수정 전까지 머지를 막는다 |
| 기록 | 수정 PR에 원인 분류(시간, 동시성, 순서, 환경, 데이터)를 적는다 |

---

## 17. 테스트 데이터 개인정보

| 규칙 | 내용 |
|---|---|
| 코드 | 회사·고객·실제 운영 코드를 fixture, vector, eval case, 스크린샷에 쓰지 않는다. 모든 코드 예시는 직접 작성한 합성 코드 |
| 채용공고 | 실제 JD를 붙여넣지 않는다. 가상 회사(`Example Corp`, `Sample Labs`)와 합성 요구사항만 |
| 사람 정보 | 실명, 실제 이메일, 실제 GitHub 계정 금지. 이메일은 `*@devpilot.test`, 표시 이름은 `Test Owner`, `Test Invited` |
| Secret | 실제 키 금지. fake secret은 런타임 문자열 조합(`07` §11.3) |
| 운영 데이터 | 운영 DB 덤프·백업을 테스트·perf·demo 데이터로 쓰지 않는다. `perf/seed.sql`은 생성 스크립트로 만든다 |
| 로그·리포트 | CI 아티팩트(테스트 리포트)에 토큰·secret이 찍히지 않게 테스트 로그도 `07` §6.1을 따른다 |
| 리뷰 | fixture를 추가하는 PR은 "Security impact"에 합성 데이터임을 적는다 |

---

## 18. Definition of Done

완료 기준은 `16-definition-of-ready-done.md`가 유일한 기준이다. 이 문서와 관련된 최소 조건은 다음과 같다.

- 해당 기능의 `06` vector 전부 통과, 관련 AC 테스트 존재·통과
- 사용자 소유 endpoint를 추가했으면 §9 catalog 갱신
- §14.1 CI job 전부 green
- 새 테스트가 §3 명명·태그 규칙과 §17 데이터 규칙을 지킴
