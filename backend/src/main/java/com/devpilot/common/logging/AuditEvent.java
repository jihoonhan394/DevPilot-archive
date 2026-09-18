package com.devpilot.common.logging;

/** 감사 이벤트 이름 (docs/07 §6.3). 값은 기능이 생기는 단계에서 추가한다. S0: devtoken 발급·거부. */
public enum AuditEvent {
    AUTH_DEVTOKEN_ISSUED,
    AUTH_DEVTOKEN_REJECTED
}
