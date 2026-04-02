package com.teng.app.gastosai.service;

import com.teng.app.gastosai.ai.OpenAiSqlGenerator;
import com.teng.app.gastosai.ai.SqlGuard;
import com.teng.app.gastosai.dto.AiQueryResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class AiQueryService {

	private static final Logger log = LoggerFactory.getLogger(AiQueryService.class);

	private final OpenAiSqlGenerator openAiSqlGenerator;
	private final JdbcTemplate jdbcTemplate;

	public AiQueryService(OpenAiSqlGenerator openAiSqlGenerator, JdbcTemplate jdbcTemplate) {
		this.openAiSqlGenerator = openAiSqlGenerator;
		this.jdbcTemplate = jdbcTemplate;
	}

	public AiQueryResponse runNaturalLanguageQuery(String question) {
		String rawSql = openAiSqlGenerator.generateSql(question);
		String sql = SqlGuard.validateAndNormalize(rawSql);
		log.info("AI-generated SQL (validated): {}", sql);

		List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql);
		return new AiQueryResponse(normalizeAnswer(rows));
	}

	private static Object normalizeAnswer(List<Map<String, Object>> rows) {
		if (rows == null || rows.isEmpty()) {
			return null;
		}
		if (rows.size() == 1) {
			Map<String, Object> row = rows.get(0);
			if (row.size() == 1) {
				return row.values().iterator().next();
			}
		}
		return rows;
	}
}
