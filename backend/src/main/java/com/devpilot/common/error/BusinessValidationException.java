package com.devpilot.common.error;

import java.util.List;

/** 도메인 검사 실패: 400 {@code VALIDATION_FAILED} + 도메인 field code (docs/05 §1.2.3). */
public class BusinessValidationException extends DevPilotException {

    private static final long serialVersionUID = 1L;

    public BusinessValidationException(String message, List<ApiFieldError> errors) {
        super(ErrorCode.VALIDATION_FAILED, message, errors);
    }
}
