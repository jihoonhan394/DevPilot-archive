package com.devpilot.user.presentation;

import io.swagger.v3.oas.annotations.media.Schema;
import org.jspecify.annotations.Nullable;

/**
 * {@code GET /api/v1/me} 응답 — **S0 임시 형태**. S1(BL-FND-21)에서 docs/05 §3.1의 전체 프로필로 바뀐다.
 *
 * @param sub JWT {@code sub}
 * @param email JWT {@code email} (소문자)
 */
public record MeResponse(String sub, @Schema(types = {"string", "null"}) @Nullable String email) {}
