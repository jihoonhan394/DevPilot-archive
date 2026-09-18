package com.devpilot.common.error;

import com.devpilot.common.web.TraceIdFilter;
import jakarta.servlet.http.HttpServletRequest;
import java.net.URI;
import java.util.List;
import java.util.Locale;
import org.springframework.context.MessageSource;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.stereotype.Component;

/**
 * RFC 9457 Problem Details 본문을 만든다 (docs/05 §1.2.1). {@code type}·{@code title}은 {@link ErrorCode},
 * {@code detail}은 {@code messages_ko.properties}, 확장 속성은 {@code code}·{@code traceId}·{@code
 * errors}다.
 */
@Component
public class ProblemDetailFactory {

    private static final Locale MESSAGE_LOCALE = Locale.KOREAN;

    private final MessageSource messageSource;

    public ProblemDetailFactory(MessageSource messageSource) {
        this.messageSource = messageSource;
    }

    public ProblemDetail create(HttpServletRequest request, ErrorCode errorCode) {
        return create(request, errorCode, List.of());
    }

    public ProblemDetail create(
            HttpServletRequest request, ErrorCode errorCode, List<ApiFieldError> errors) {
        ProblemDetail problem =
                ProblemDetail.forStatusAndDetail(
                        HttpStatusCode.valueOf(errorCode.status()), detail(errorCode));
        problem.setType(URI.create(errorCode.type()));
        problem.setTitle(errorCode.title());
        problem.setInstance(URI.create(request.getRequestURI()));
        problem.setProperty("code", errorCode.name());
        problem.setProperty("traceId", TraceIdFilter.currentTraceId(request));
        problem.setProperty("errors", List.copyOf(errors));
        return problem;
    }

    public String detail(ErrorCode errorCode) {
        return messageSource.getMessage(errorCode.messageKey(), null, MESSAGE_LOCALE);
    }

    /** {@code validation.<code>} 문구. 없으면 {@code validation.DEFAULT}. */
    public String validationMessage(String code) {
        String fallback = messageSource.getMessage("validation.DEFAULT", null, MESSAGE_LOCALE);
        String message =
                messageSource.getMessage("validation." + code, null, fallback, MESSAGE_LOCALE);
        return message != null ? message : fallback;
    }
}
