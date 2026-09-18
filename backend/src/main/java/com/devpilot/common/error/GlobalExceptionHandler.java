package com.devpilot.common.error;

import com.devpilot.common.web.RequestBodyTooLargeException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.jspecify.annotations.Nullable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.MessageSourceResolvable;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import tools.jackson.databind.exc.InvalidFormatException;

/**
 * 예외 → Problem Details 변환 (docs/03 §7, docs/05 §1.3). 응답 {@code detail}에는 사용자용 한국어 문장만 넣고 내부
 * 메시지·stack trace는 로그에만 남긴다.
 */
@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);
    private static final String IDEMPOTENCY_KEY_HEADER = "Idempotency-Key";
    private static final String TYPE_MISMATCH = "TYPE_MISMATCH";
    private static final int MAX_CAUSE_DEPTH = 16;

    private final ProblemDetailFactory problemDetailFactory;

    public GlobalExceptionHandler(ProblemDetailFactory problemDetailFactory) {
        this.problemDetailFactory = problemDetailFactory;
    }

    @ExceptionHandler(DevPilotException.class)
    public ResponseEntity<ProblemDetail> handleDevPilot(
            DevPilotException exception, HttpServletRequest request) {
        log.debug(
                "request rejected code={} reason={}",
                exception.errorCode(),
                exception.getMessage());
        return respond(request, exception.errorCode(), exception.errors());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ProblemDetail> handleBodyValidation(
            MethodArgumentNotValidException exception, HttpServletRequest request) {
        List<ApiFieldError> errors = new ArrayList<>();
        for (FieldError fieldError : exception.getBindingResult().getFieldErrors()) {
            errors.add(fieldError(fieldError.getField(), fieldError));
        }
        return respond(request, ErrorCode.VALIDATION_FAILED, errors);
    }

    @ExceptionHandler(HandlerMethodValidationException.class)
    public ResponseEntity<ProblemDetail> handleMethodValidation(
            HandlerMethodValidationException exception, HttpServletRequest request) {
        List<ApiFieldError> errors = new ArrayList<>();
        exception
                .getParameterValidationResults()
                .forEach(
                        result -> {
                            String field = result.getMethodParameter().getParameterName();
                            for (MessageSourceResolvable error : result.getResolvableErrors()) {
                                errors.add(fieldError(field == null ? "" : field, error));
                            }
                        });
        return respond(request, ErrorCode.VALIDATION_FAILED, errors);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ProblemDetail> handleConstraintViolation(
            ConstraintViolationException exception, HttpServletRequest request) {
        List<ApiFieldError> errors = new ArrayList<>();
        for (ConstraintViolation<?> violation : exception.getConstraintViolations()) {
            String code =
                    violation
                            .getConstraintDescriptor()
                            .getAnnotation()
                            .annotationType()
                            .getSimpleName();
            errors.add(
                    new ApiFieldError(
                            violation.getPropertyPath().toString(),
                            code,
                            interpolate(
                                    problemDetailFactory.validationMessage(code),
                                    violation.getConstraintDescriptor().getAttributes())));
        }
        return respond(request, ErrorCode.VALIDATION_FAILED, errors);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ProblemDetail> handleNotReadable(
            HttpMessageNotReadableException exception, HttpServletRequest request) {
        if (hasCause(exception, RequestBodyTooLargeException.class)) {
            return respond(request, ErrorCode.REQUEST_TOO_LARGE, List.of());
        }
        InvalidFormatException invalidFormat = findCause(exception, InvalidFormatException.class);
        if (invalidFormat != null
                && invalidFormat.getTargetType() != null
                && invalidFormat.getTargetType().isEnum()) {
            return respond(request, ErrorCode.UNKNOWN_ENUM_VALUE, List.of());
        }
        log.debug("malformed request body reason={}", exception.getMessage());
        return respond(request, ErrorCode.MALFORMED_REQUEST, List.of());
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ProblemDetail> handleTypeMismatch(
            MethodArgumentTypeMismatchException exception, HttpServletRequest request) {
        Class<?> requiredType = exception.getRequiredType();
        if (requiredType != null && requiredType.isEnum()) {
            return respond(request, ErrorCode.UNKNOWN_ENUM_VALUE, List.of());
        }
        ApiFieldError error =
                new ApiFieldError(
                        exception.getName(),
                        TYPE_MISMATCH,
                        problemDetailFactory.validationMessage(TYPE_MISMATCH));
        return respond(request, ErrorCode.VALIDATION_FAILED, List.of(error));
    }

    @ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<ProblemDetail> handleMissingHeader(
            MissingRequestHeaderException exception, HttpServletRequest request) {
        if (IDEMPOTENCY_KEY_HEADER.equalsIgnoreCase(exception.getHeaderName())) {
            return respond(request, ErrorCode.IDEMPOTENCY_KEY_REQUIRED, List.of());
        }
        ApiFieldError error =
                new ApiFieldError(
                        exception.getHeaderName(),
                        "NotNull",
                        problemDetailFactory.validationMessage("NotNull"));
        return respond(request, ErrorCode.VALIDATION_FAILED, List.of(error));
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ProblemDetail> handleMediaType(HttpServletRequest request) {
        return respond(request, ErrorCode.MALFORMED_REQUEST, List.of());
    }

    /** 지원하지 않는 메서드는 노출하지 않고 404로 답한다 (docs/05 §1.3). */
    @ExceptionHandler({
        HttpRequestMethodNotSupportedException.class,
        NoResourceFoundException.class
    })
    public ResponseEntity<ProblemDetail> handleNotFound(HttpServletRequest request) {
        return respond(request, ErrorCode.RESOURCE_NOT_FOUND, List.of());
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ProblemDetail> handleAuthentication(HttpServletRequest request) {
        return respond(request, ErrorCode.AUTHENTICATION_REQUIRED, List.of());
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ProblemDetail> handleAccessDenied(HttpServletRequest request) {
        return respond(request, ErrorCode.FORBIDDEN, List.of());
    }

    @ExceptionHandler(ObjectOptimisticLockingFailureException.class)
    public ResponseEntity<ProblemDetail> handleOptimisticLock(HttpServletRequest request) {
        return respond(request, ErrorCode.CONCURRENT_MODIFICATION, List.of());
    }

    /**
     * 최후 방어선 (docs/03 §7, docs/08 §3.10 허용 위치 1). 예상하지 못한 예외는 500 {@code INTERNAL_ERROR}로 바꾸고 stack
     * trace는 로그에만 한 번 남긴다.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ProblemDetail> handleUnexpected(
            Exception exception, HttpServletRequest request) {
        log.error("unexpected error path={}", request.getRequestURI(), exception);
        return respond(request, ErrorCode.INTERNAL_ERROR, List.of());
    }

    private ResponseEntity<ProblemDetail> respond(
            HttpServletRequest request, ErrorCode errorCode, List<ApiFieldError> errors) {
        ResponseEntity.BodyBuilder builder =
                ResponseEntity.status(errorCode.status())
                        .contentType(MediaType.APPLICATION_PROBLEM_JSON);
        if (errorCode == ErrorCode.AUTHENTICATION_REQUIRED) {
            builder.header(HttpHeaders.WWW_AUTHENTICATE, "Bearer");
        }
        return builder.body(problemDetailFactory.create(request, errorCode, errors));
    }

    private ApiFieldError fieldError(String field, MessageSourceResolvable error) {
        String code = lastCode(error);
        Map<String, Object> attributes = Map.of();
        if (error instanceof FieldError springFieldError
                && springFieldError.contains(ConstraintViolation.class)) {
            ConstraintViolation<?> violation = springFieldError.unwrap(ConstraintViolation.class);
            attributes = violation.getConstraintDescriptor().getAttributes();
        }
        return new ApiFieldError(
                field, code, interpolate(problemDetailFactory.validationMessage(code), attributes));
    }

    private static String lastCode(MessageSourceResolvable error) {
        String[] codes = error.getCodes();
        if (codes == null || codes.length == 0) {
            return "DEFAULT";
        }
        return codes[codes.length - 1];
    }

    /** {@code {min}}, {@code {max}}, {@code {value}} 같은 annotation 속성을 문구에 넣는다. */
    private static String interpolate(String template, Map<String, Object> attributes) {
        String message = template;
        for (Map.Entry<String, Object> attribute : attributes.entrySet()) {
            message =
                    message.replace(
                            "{" + attribute.getKey() + "}", String.valueOf(attribute.getValue()));
        }
        return message;
    }

    private static boolean hasCause(Throwable throwable, Class<? extends Throwable> type) {
        return findCause(throwable, type) != null;
    }

    private static <T extends Throwable> @Nullable T findCause(Throwable throwable, Class<T> type) {
        Throwable current = throwable;
        for (int depth = 0; current != null && depth < MAX_CAUSE_DEPTH; depth++) {
            if (type.isInstance(current)) {
                return type.cast(current);
            }
            current = current.getCause();
        }
        return null;
    }
}
