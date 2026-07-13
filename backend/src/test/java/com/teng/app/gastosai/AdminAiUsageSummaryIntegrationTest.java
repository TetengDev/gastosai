package com.teng.app.gastosai;

import com.teng.app.gastosai.ai.AiFeature;
import com.teng.app.gastosai.config.JwtUtil;
import com.teng.app.gastosai.entity.AiUsageStatus;
import com.teng.app.gastosai.entity.Role;
import com.teng.app.gastosai.entity.User;
import com.teng.app.gastosai.repository.AiUsageRepository;
import com.teng.app.gastosai.repository.UserRepository;
import com.teng.app.gastosai.service.AiUsageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
class AdminAiUsageSummaryIntegrationTest {

	@Autowired WebApplicationContext webApplicationContext;
	@Autowired UserRepository userRepository;
	@Autowired AiUsageRepository aiUsageRepository;
	@Autowired PasswordEncoder passwordEncoder;
	@Autowired JwtUtil jwtUtil;
	@Autowired AiUsageService aiUsageService;

	MockMvc mockMvc;
	String adminAuth;
	String userAuth;

	@BeforeEach
	void setUp() {
		mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).apply(springSecurity()).build();
		aiUsageRepository.deleteAll();
		userRepository.deleteAll();
		User admin = userRepository.save(User.builder().name("Admin").email("admin-usage@test.com")
				.password(passwordEncoder.encode("password")).role(Role.ADMIN).build());
		User normal = userRepository.save(User.builder().name("Norm").email("norm-usage@test.com")
				.password(passwordEncoder.encode("password")).role(Role.USER).build());
		adminAuth = "Bearer " + jwtUtil.generate(admin.getEmail());
		userAuth = "Bearer " + jwtUtil.generate(normal.getEmail());
		aiUsageService.record(normal.getId(), "openai", "gpt-4o-mini", AiFeature.CHAT_CRUD_ASSISTANT,
				100, 50, AiUsageStatus.SUCCESS, null);
	}

	@Test
	void admin_getsMonthToDateSummaryWithTokensAndCost() throws Exception {
		mockMvc.perform(get("/admin/ai-usage/summary").header("Authorization", adminAuth))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(1))
				.andExpect(jsonPath("$[0].feature").value("CHAT_CRUD_ASSISTANT"))
				.andExpect(jsonPath("$[0].model").value("gpt-4o-mini"))
				.andExpect(jsonPath("$[0].requests").value(1))
				.andExpect(jsonPath("$[0].inputTokens").value(100))
				.andExpect(jsonPath("$[0].outputTokens").value(50))
				.andExpect(jsonPath("$[0].estimatedCostUsd").isNumber());
	}

	@Test
	void normalUser_isForbidden() throws Exception {
		mockMvc.perform(get("/admin/ai-usage/summary").header("Authorization", userAuth))
				.andExpect(status().isForbidden());
	}

	@Test
	void unauthenticated_isRejected() throws Exception {
		mockMvc.perform(get("/admin/ai-usage/summary"))
				.andExpect(status().is4xxClientError());
	}
}
