package com.teng.app.gastosai.service;

import com.teng.app.gastosai.config.JwtUtil;
import com.teng.app.gastosai.dto.AuthResponse;
import com.teng.app.gastosai.dto.LoginRequest;
import com.teng.app.gastosai.dto.RegisterRequest;
import com.teng.app.gastosai.entity.User;
import com.teng.app.gastosai.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class AuthService {

	private final UserRepository userRepository;
	private final PasswordEncoder passwordEncoder;
	private final JwtUtil jwtUtil;
	private final CategorySeedService categorySeedService;

	@Transactional
	public AuthResponse register(RegisterRequest request) {
		if (userRepository.existsByEmail(request.email())) {
			throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");
		}
		User user = User.builder()
				.name(request.name())
				.email(request.email())
				.password(passwordEncoder.encode(request.password()))
				.build();
		User saved = userRepository.save(user);
		categorySeedService.seedPredefinedForUser(saved);
		return sessionFor(saved, true);
	}

	// Hash of a throwaway value, computed once with the injected encoder. Matched against
	// when the email is unknown so a login attempt takes the same time whether or not the
	// account exists — closes the timing side-channel that would otherwise allow user
	// enumeration (CWE-208). Built via the configured passwordEncoder (not a fresh
	// BCryptPasswordEncoder) so it stays valid if the encoder is ever swapped for a
	// DelegatingPasswordEncoder.
	private String dummyHash;

	@jakarta.annotation.PostConstruct
	void initDummyHash() {
		this.dummyHash = passwordEncoder.encode("gastos-nonexistent-account-placeholder");
	}

	@Transactional(readOnly = true)
	public AuthResponse login(LoginRequest request) {
		User user = userRepository.findByEmail(request.email()).orElse(null);
		String hash = user != null ? user.getPassword() : dummyHash;
		boolean matches = passwordEncoder.matches(request.password(), hash);
		if (user == null || !matches) {
			throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
		}
		return sessionFor(user, false);
	}

	public AuthResponse sessionFor(User user, boolean isNew) {
		return new AuthResponse(jwtUtil.generate(user.getEmail()), user.getEmail(), user.getName(), user.getNickname(), user.getAvatarColor(), user.getDefaultCategoryName(), user.getAvatar(), isNew, user.getRole().name());
	}
}
