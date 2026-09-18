package com.devpilot.common.error;

/**
 * ProblemDetail {@code errors[]} 항목 (docs/05 §1.2.1).
 *
 * @param field JSON 경로(점·index 표기) 또는 query/path/header 이름
 * @param code Bean Validation annotation 단순 이름 또는 도메인 코드 (docs/05 §1.2.3)
 * @param message 사용자용 한국어 문장
 */
public record ApiFieldError(String field, String code, String message) {}
