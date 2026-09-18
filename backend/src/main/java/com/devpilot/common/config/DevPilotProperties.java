package com.devpilot.common.config;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import org.jspecify.annotations.Nullable;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * {@code devpilot.*} 설정 루트 (docs/03 §9). 모듈별 설정은 중첩 record로 둔다.
 *
 * <p>S0에는 인증·웹 설정만 바인딩한다. 나머지 블록(planner, budget, review, ai …)은 해당 기능이 생기는 단계에서 중첩 record로
 * 추가한다(BL-FND-09). 바인딩되지 않은 키는 무시된다.
 */
@Validated
@ConfigurationProperties("devpilot")
public record DevPilotProperties(@Valid @NotNull Security security, @Valid @NotNull Web web) {

    /** 인증 방식 (docs/03 §4.2). */
    public enum AuthMode {
        DEVTOKEN,
        SUPABASE
    }

    public record Security(
            @NotNull AuthMode authMode,
            @Valid @NotNull Devtoken devtoken,
            List<String> allowedEmails,
            List<String> allowedSubjects,
            @Positive int maxRequestBodyBytes,
            @Nullable String logHashKey) {

        public Security {
            allowedEmails = normalize(allowedEmails, true);
            allowedSubjects = normalize(allowedSubjects, false);
        }

        private static List<String> normalize(@Nullable List<String> values, boolean lowerCase) {
            if (values == null) {
                return List.of();
            }
            return values.stream()
                    .map(String::trim)
                    .filter(value -> !value.isEmpty())
                    .map(value -> lowerCase ? value.toLowerCase(Locale.ROOT) : value)
                    .toList();
        }
    }

    /** devtoken 모드 설정. {@code privateKeyPem}이 비면 기동 시 키를 만든다(prod는 필수). */
    public record Devtoken(
            @NotBlank String issuer, @Nullable String privateKeyPem, @NotNull Duration tokenTtl) {}

    public record Web(@NotBlank String appBaseUrl, List<String> corsAllowedOrigins) {

        public Web {
            corsAllowedOrigins =
                    corsAllowedOrigins == null
                            ? List.of()
                            : corsAllowedOrigins.stream()
                                    .map(String::trim)
                                    .filter(origin -> !origin.isEmpty())
                                    .toList();
        }
    }
}
