-- Sample expenses for gastos.ai (PostgreSQL).
-- Run manually in psql/pgAdmin against your database, or enable app seeding via gastos.seed-sample-data=true

INSERT INTO expenses (amount, category, date, note) VALUES
(89.50, 'Food', '2026-03-28', 'Groceries — weekend shop'),
(245.00, 'Food', '2026-03-30', 'Dinner with friends'),
(120.00, 'Transport', '2026-03-31', 'Gas station'),
(45.00, 'Transport', '2026-04-01', 'Metro + bus top-up'),
(250.50, 'Food', '2026-04-01', 'Lunch'),
(1899.00, 'Bills', '2026-04-02', 'Rent contribution'),
(599.00, 'Bills', '2026-04-02', 'Electricity'),
(350.00, 'Shopping', '2026-04-02', 'Clothing'),
(129.99, 'Entertainment', '2026-04-02', 'Streaming subscriptions'),
(75.00, 'Health', '2026-04-03', 'Pharmacy'),
(42.30, 'Food', '2026-04-03', 'Coffee & pastries'),
(2100.00, 'Transport', '2026-04-03', 'Car service'),
(15.50, 'Food', '2026-04-03', 'Snack'),
(480.00, 'Bills', '2026-04-03', 'Internet'),
(199.00, 'Shopping', '2026-04-03', 'Electronics accessory');
