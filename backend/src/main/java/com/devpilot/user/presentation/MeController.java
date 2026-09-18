package com.devpilot.user.presentation;

import com.devpilot.user.application.ProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** {@code GET /api/v1/me} — S0 임시 (docs/05 §3.1은 S1). */
@RestController
@RequestMapping("/api/v1/me")
@Tag(name = "user")
public class MeController {

    private final ProfileService profileService;

    public MeController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping
    @Operation(operationId = "userGetMe")
    public MeResponse me(@AuthenticationPrincipal Jwt jwt) {
        ProfileService.ProfileView profile = profileService.currentProfile(jwt);
        return new MeResponse(profile.subject(), profile.email());
    }
}
