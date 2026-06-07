# 📊 gastos.ai

> AI-powered expense tracker with dashboards and natural language insights.

---

## 🚀 Overview

**gastos.ai** is a full-stack application that allows users to:

* Track daily expenses
* Visualize spending patterns
* Ask AI questions about financial data

---

## ✨ Features

### ✅ Expense Tracking

* Add, edit, delete expenses
* Categorize spending (Food, Transport, etc.)
* Track date and notes

### 📊 Dashboard & Reports

* Monthly spending summary
* Category breakdown
* Spending trends

### 🤖 AI Insights

* Natural language queries
* Converts text → SQL → results

Example:

> “How much did I spend on food last month?”

---

## 🧱 Tech Stack

### Backend

* Java 17+
* Spring Boot
* Spring Data JPA

### Database

* PostgreSQL

### AI

* OpenAI API

### Deployment

* Docker (optional)
* Render / Railway

---

## 🏗️ Architecture

Client → Spring Boot API → PostgreSQL
                             ↓
                         OpenAI API

---

## 📂 Project Structure

```
gastos-ai/
├── controller/
├── service/
├── repository/
├── entity/
├── dto/
├── config/
└── ai/
```

---

## 🗄️ Database Schema

```sql
CREATE TABLE expenses (
  id SERIAL PRIMARY KEY,
  amount DECIMAL NOT NULL,
  category VARCHAR(50),
  date DATE,
  note TEXT
);
```

---

## 🔌 API Endpoints

### Expenses

```
POST   /expenses
GET    /expenses
PUT    /expenses/{id}
DELETE /expenses/{id}
```

### Reports

```
GET /expenses/report/monthly
GET /expenses/report/category
```

### AI

```
POST /ai/query
```

---

## 🤖 AI Flow

1. User submits a question
2. Convert question → SQL using OpenAI
3. Execute SQL query
4. Return result

---

## 🛠️ Tools

### 📋 Planning

* Notion / Trello
* Whimsical / Draw.io
* Google Sheets

### 💻 Development

* IntelliJ IDEA
* Postman / Insomnia
* DBeaver / pgAdmin
* Git + GitHub

### 🧪 Testing

* JUnit
* Mockito
* Testcontainers (optional)

---

## 🚀 Deployment

### Build

```
./mvnw clean package
```

### Environment Variables

```
DB_URL=
DB_USERNAME=
DB_PASSWORD=
OPENAI_API_KEY=
```

### Steps

1. Push code to GitHub
2. Connect to Render or Railway
3. Configure environment variables
4. Deploy backend
5. Provision PostgreSQL database

---

## 🔄 CI/CD (Optional)

* GitHub Actions

  * Build
  * Test
  * Deploy

---

## 📈 Monitoring & Maintenance

### Logging

* Spring Boot logs

### Monitoring

* UptimeRobot
* Grafana + Prometheus (advanced)

### Maintenance

* Daily DB backups
* Monitor API performance
* Rotate API keys
* Check logs regularly

---

## 🔐 Security

* Input validation
* Environment-based secrets
* Rate limiting (AI endpoint)
* JWT authentication (planned)

---

## 🧭 Roadmap

### v1

* Expense CRUD
* Reports
* AI queries

### v2

* Authentication (JWT)
* Multi-user support
* Recurring expenses

### v3

* Data pipeline (Airflow)
* Data warehouse
* BI dashboards

### v4

* AI insights
* RAG-based querying

---

## 🧠 Focus Areas

* SQL aggregation
* API design
* AI integration
* Cloud deployment

---

## ⚡ Notes

Keep v1 simple and ship fast.
Iterate based on real usage and data.

---

## 📦 Sample API Requests & Responses

### Create Expense

```
POST /expenses
Content-Type: application/json

{
  "amount": 250.50,
  "category": "Food",
  "date": "2026-04-01",
  "note": "Lunch"
}
```

**Response**

```
{
  "id": 1,
  "amount": 250.50,
  "category": "Food",
  "date": "2026-04-01",
  "note": "Lunch"
}
```

---

### AI Query

```
POST /ai/query

{
  "question": "How much did I spend on food last month?"
}
```

**Response**

```
{
  "answer": 5200.75
}
```

---

## 🧩 ER Diagram (Simple)

```
[User] (future)
   |
   | 1
   |———< has >———∞
                 |
             [Expense]
             - id
             - amount
             - category
             - date
             - note
```

---

## 🛠️ Step-by-Step Development Guide

### Step 1: Project Setup (Day 1)

* Initialize Spring Boot project
* Add dependencies (Web, JPA, PostgreSQL)
* Setup basic structure

### Step 2: Database Integration (Day 1-2)

* Configure PostgreSQL
* Create Expense entity
* Setup repository layer

### Step 3: CRUD APIs (Day 2-3)

* Implement controller + service
* Test endpoints using Postman

### Step 4: Reporting APIs (Day 3-4)

* Monthly aggregation
* Category aggregation

### Step 5: AI Integration (Day 5-6)

* Integrate OpenAI API
* Implement text-to-SQL conversion
* Execute dynamic queries safely

### Step 6: Testing (Day 6-7)

* Unit tests (JUnit + Mockito)
* Test API flows

### Step 7: Deployment (Day 7)

* Build JAR
* Deploy to Render/Railway
* Setup PostgreSQL instance

---

## 📅 Timeline (Realistic)

| Week   | Goal                         |
| ------ | ---------------------------- |
| Week 1 | Backend CRUD + DB            |
| Week 2 | Reports + AI Integration     |
| Week 3 | Deployment + Testing         |
| Week 4 | Improvements + UI (optional) |

---

## 🖼️ Screenshots (To Add Later)

* Dashboard view
* API responses (Postman)
* AI query demo

---

## 🧠 Pro Tips

* Start simple, avoid overengineering
* Focus on SQL quality (this is your edge)
* Log AI-generated queries for debugging
* Add constraints to avoid dangerous SQL execution

---
