package com.teng.app.gastosai.bootstrap;

import com.teng.app.gastosai.entity.Expense;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class ExpenseSampleData {

	private ExpenseSampleData() {
	}

	public static List<Expense> expenses() {
		return List.of(
				expense("89.50", "Food", "2026-03-28", "Groceries — weekend shop"),
				expense("245.00", "Food", "2026-03-30", "Dinner with friends"),
				expense("120.00", "Transport", "2026-03-31", "Gas station"),
				expense("45.00", "Transport", "2026-04-01", "Metro + bus top-up"),
				expense("250.50", "Food", "2026-04-01", "Lunch"),
				expense("1899.00", "Bills", "2026-04-02", "Rent contribution"),
				expense("599.00", "Bills", "2026-04-02", "Electricity"),
				expense("350.00", "Shopping", "2026-04-02", "Clothing"),
				expense("129.99", "Entertainment", "2026-04-02", "Streaming subscriptions"),
				expense("75.00", "Health", "2026-04-03", "Pharmacy"),
				expense("42.30", "Food", "2026-04-03", "Coffee & pastries"),
				expense("2100.00", "Transport", "2026-04-03", "Car service"),
				expense("15.50", "Food", "2026-04-03", "Snack"),
				expense("480.00", "Bills", "2026-04-03", "Internet"),
				expense("199.00", "Shopping", "2026-04-03", "Electronics accessory"));
	}

	private static Expense expense(String amount, String category, String date, String note) {
		return Expense.builder()
				.amount(new BigDecimal(amount))
				.category(category)
				.date(LocalDate.parse(date))
				.note(note)
				.build();
	}
}
