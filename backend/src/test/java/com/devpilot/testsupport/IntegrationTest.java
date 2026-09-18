package com.devpilot.testsupport;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import org.junit.jupiter.api.Tag;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

/**
 * 통합 테스트 조합 (docs/09 §3.3). Spring context 캐시가 재사용되도록 설정을 이 애노테이션 하나로 고정한다. FakeAiConfig는 AI 기능이
 * 생기는 S3에 추가한다.
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Tag("integration")
@SpringBootTest
@ActiveProfiles("test")
@Import({PostgresTestcontainersConfig.class, TestClockConfig.class, TestJwksConfig.class})
public @interface IntegrationTest {}
