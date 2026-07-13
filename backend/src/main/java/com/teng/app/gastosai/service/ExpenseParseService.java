package com.teng.app.gastosai.service;

import com.teng.app.gastosai.ai.AiFeature;
import com.teng.app.gastosai.ai.ExpenseParser;
import com.teng.app.gastosai.ai.LlmResult;
import com.teng.app.gastosai.config.AiProviderProperties;
import com.teng.app.gastosai.config.ClaudeProperties;
import com.teng.app.gastosai.config.OpenAiProperties;
import com.teng.app.gastosai.dto.ParsedExpenseResult;
import com.teng.app.gastosai.entity.AiUsageStatus;
import com.teng.app.gastosai.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ExpenseParseService {

    private final ExpenseParser expenseParser;
    private final AiUsageService aiUsageService;
    private final AiProviderProperties aiProviderProperties;
    private final OpenAiProperties openAiProperties;
    private final ClaudeProperties claudeProperties;

    public ParsedExpenseResult parse(String text, User user) {
        try {
            LlmResult<ParsedExpenseResult> result = expenseParser.parse(text);
            aiUsageService.record(user.getId(), aiProviderProperties.getProvider(),
                    resolveModel(), AiFeature.EXPENSE_PARSE,
                    result.usage().inputTokens(), result.usage().outputTokens(),
                    AiUsageStatus.SUCCESS, null);
            return result.value();
        } catch (Exception e) {
            aiUsageService.record(user.getId(), aiProviderProperties.getProvider(),
                    resolveModel(), AiFeature.EXPENSE_PARSE,
                    null, null, AiUsageStatus.FAILED, e.getClass().getSimpleName());
            throw e;
        }
    }

    private String resolveModel() {
        return "claude".equalsIgnoreCase(aiProviderProperties.getProvider())
                ? claudeProperties.getModel()
                : openAiProperties.getModel();
    }
}
