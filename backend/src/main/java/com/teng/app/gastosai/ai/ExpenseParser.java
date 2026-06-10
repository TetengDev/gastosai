package com.teng.app.gastosai.ai;

import com.teng.app.gastosai.dto.ParsedExpenseResult;

public interface ExpenseParser {
    ParsedExpenseResult parse(String text);
}