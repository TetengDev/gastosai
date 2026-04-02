package com.teng.app.gastosai.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.teng.app.gastosai.config.OpenAiProperties;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class OpenAiSqlGenerator {

	private static final String SYSTEM_PROMPT = """
			You generate exactly one PostgreSQL SELECT query for the table "expenses" with columns:
			id (bigint), amount (numeric), category (varchar), date (date), note (text).
			Rules:
			- Output only the SQL, no markdown unless you wrap it in a single ```sql code block.
			- SELECT only; no semicolons at the end.
			- Query only the expenses table (aliases like e are fine).
			- Use standard PostgreSQL date functions when the user asks about months or ranges.
			""";

	private static final Pattern SQL_FENCE = Pattern.compile("(?is)```(?:sql)?\\s*([\\s\\S]*?)```");

	private final RestClient openAiRestClient;
	private final OpenAiProperties openAiProperties;
	private final ObjectMapper objectMapper = new ObjectMapper();

	public OpenAiSqlGenerator(RestClient openAiRestClient, OpenAiProperties openAiProperties) {
		this.openAiRestClient = openAiRestClient;
		this.openAiProperties = openAiProperties;
	}

	public String generateSql(String question) {
		if (openAiProperties.getApiKey() == null || openAiProperties.getApiKey().isBlank()) {
			throw new IllegalStateException("OPENAI_API_KEY is not configured");
		}

		ObjectNode body = objectMapper.createObjectNode();
		body.put("model", openAiProperties.getModel());
		body.put("temperature", 0);
		ArrayNode messages = body.putArray("messages");
		ObjectNode system = messages.addObject();
		system.put("role", "system");
		system.put("content", SYSTEM_PROMPT);
		ObjectNode user = messages.addObject();
		user.put("role", "user");
		user.put("content", question);

		String raw = openAiRestClient.post()
				.uri("/v1/chat/completions")
				.contentType(MediaType.APPLICATION_JSON)
				.body(body.toString())
				.retrieve()
				.body(String.class);

		if (raw == null || raw.isBlank()) {
			throw new IllegalStateException("Empty response from OpenAI");
		}

		try {
			JsonNode root = objectMapper.readTree(raw);
			String content = root.path("choices").path(0).path("message").path("content").asText("");
			return extractSql(content);
		}
		catch (Exception e) {
			throw new IllegalStateException("Failed to parse OpenAI response", e);
		}
	}

	static String extractSql(String content) {
		if (content == null) {
			return "";
		}
		String t = content.trim();
		Matcher m = SQL_FENCE.matcher(t);
		if (m.find()) {
			return m.group(1).trim();
		}
		return t;
	}
}
