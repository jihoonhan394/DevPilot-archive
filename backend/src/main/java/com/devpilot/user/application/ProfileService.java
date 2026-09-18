package com.devpilot.user.application;

import com.devpilot.common.error.ErrorCode;
import com.devpilot.common.error.ForbiddenException;
import com.devpilot.common.security.AllowedUserPolicy;
import org.jspecify.annotations.Nullable;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;

/**
 * 프로필 조회. **S0 임시 구현**: 사용자 테이블·JIT 프로비저닝(docs/03 §4.3)은 S1(BL-SEC-04, BL-FND-21)에서 들어온다. 지금은 검증된
 * JWT의 {@code sub}·{@code email}을 돌려주고 allowlist만 다시 확인한다.
 */
@Service
public class ProfileService {

    private final AllowedUserPolicy allowedUserPolicy;

    public ProfileService(AllowedUserPolicy allowedUserPolicy) {
        this.allowedUserPolicy = allowedUserPolicy;
    }

    public ProfileView currentProfile(Jwt jwt) {
        String email = jwt.getClaimAsString("email");
        if (!allowedUserPolicy.isAllowed(email, jwt.getSubject())) {
            throw new ForbiddenException(
                    ErrorCode.USER_NOT_ALLOWED, "user is not in the allowlist");
        }
        return new ProfileView(jwt.getSubject(), AllowedUserPolicy.normalizeEmail(email));
    }

    /** S0 임시 프로필. */
    public record ProfileView(String subject, @Nullable String email) {}
}
