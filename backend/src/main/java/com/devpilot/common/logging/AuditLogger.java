package com.devpilot.common.logging;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.spi.LoggingEventBuilder;
import org.springframework.stereotype.Component;

/**
 * 감사 로그 (docs/03 §8, docs/07 §6.3). 로거 이름은 {@code com.devpilot.audit}, INFO, 필드 {@code event}와 호출자가
 * 준 key-value. 이메일·토큰·요청 body 원문을 넣지 않는다 — 이메일은 {@link #emailRef(String)}로만 남긴다.
 */
@Component
public class AuditLogger {

    private static final Logger log = LoggerFactory.getLogger("com.devpilot.audit");
    private static final int REF_HEX_LENGTH = 12;

    public void log(AuditEvent event, Map<String, ?> fields) {
        LoggingEventBuilder builder = log.atInfo().addKeyValue("event", event.name());
        fields.forEach(builder::addKeyValue);
        builder.log("audit event={}", event.name());
    }

    /** 이메일 SHA-256 앞 12 hex (docs/05 §1.4.5). */
    public static String emailRef(String normalizedEmail) {
        try {
            byte[] digest =
                    MessageDigest.getInstance("SHA-256")
                            .digest(normalizedEmail.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest).substring(0, REF_HEX_LENGTH);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is not available", exception);
        }
    }
}
