package com.teng.app.gastosai.bootstrap;

import com.teng.app.gastosai.repository.ExpenseRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * Startup seeding when {@code gastos.seed-sample-data=true}. Add more seed methods as the app grows.
 */
@Component
@Order(0)
@ConditionalOnProperty(name = "gastos.seed-sample-data", havingValue = "true")
@RequiredArgsConstructor
public class AppDataLoader implements ApplicationRunner {

	private static final Logger log = LoggerFactory.getLogger(AppDataLoader.class);

	private final ExpenseRepository expenseRepository;

	@Override
	public void run(ApplicationArguments args) {
		seedExpensesIfEmpty();
	}

	private void seedExpensesIfEmpty() {
		long n = expenseRepository.count();
		if (n > 0) {
			log.info("Skipping sample expense seed: {} row(s) already in expenses", n);
			return;
		}
		expenseRepository.saveAll(ExpenseSampleData.expenses());
		log.info("Loaded {} sample expenses", expenseRepository.count());
	}
}
