package com.devpilot.common.error;

import java.util.List;
import java.util.Objects;

/**
 * 클라이언트에 전달되는 오류의 공통 상위 타입 (docs/03 §3.1, docs/08 §3.10). 메시지는 영어 내부용이고 사용자 문구는 {@code
 * messages_ko.properties}의 {@code error.<CODE>}에서 온다.
 */
public abstract class DevPilotException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    private final ErrorCode errorCode;
    private final List<ApiFieldError> errors;

    protected DevPilotException(ErrorCode errorCode, String message) {
        this(errorCode, message, List.of());
    }

    protected DevPilotException(ErrorCode errorCode, String message, List<ApiFieldError> errors) {
        super(message);
        this.errorCode = Objects.requireNonNull(errorCode, "errorCode");
        this.errors = List.copyOf(errors);
    }

    public ErrorCode errorCode() {
        return errorCode;
    }

    public List<ApiFieldError> errors() {
        return errors;
    }
}
