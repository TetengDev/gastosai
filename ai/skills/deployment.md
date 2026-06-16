# Skill: Deployment

How to deploy gastosai to its production targets: Koyeb (backend), Vercel (frontend), Supabase (database).

> For a copy-paste, free-tier **user-testing** deploy using **Fly.io** for the backend (with OpenAI cost caps), follow `docs/deploy-testing-guide.md`. This skill documents the Koyeb path and deeper production notes.

---

## Overview

| Layer | Service | Plan |
|---|---|---|
| Backend | Koyeb | Free (512 MB RAM) |
| Frontend | Vercel | Free (static SPA) |
| Database | Supabase | Free (PostgreSQL; pauses after ~1 week idle) |

---

## Database — Supabase

1. Create a project at supabase.com
2. Copy the **Session mode** connection string (port 5432)
3. Set `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` in backend env vars
4. Change DDL strategy from `create-drop` to `validate` for prod:
   ```
   SPRING_JPA_HIBERNATE_DDL_AUTO=validate
   ```
5. Apply schema via Flyway migrations before first deploy (no migrations exist yet — create them when ready)

**Supabase pauses** free projects after ~1 week of inactivity. The first request after a pause takes ~30s to wake. Monitor and handle gracefully.

---

## Backend — Koyeb

### Dockerfile (backend/Dockerfile)

Multi-stage build with BuildKit cache mounts for fast rebuilds. Runtime uses alpine JDK and runs as a non-root user.

```dockerfile
# syntax=docker/dockerfile:1
FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /app
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn dependency:go-offline -q
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn clean package -DskipTests -q

FROM eclipse-temurin:25-jdk-alpine
RUN addgroup -S spring && adduser -S spring -G spring
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
RUN chown spring:spring app.jar
USER spring
ENV JAVA_OPTS="-Xmx320m -XX:+UseSerialGC -XX:MaxRAMPercentage=70"
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

> **Keep in sync:** If you change this snippet, update `backend/Dockerfile` to match. The canonical source is the file; this is documentation only.

### JVM tuning for 512 MB

```
JAVA_OPTS=-Xmx320m -XX:+UseSerialGC -XX:MaxRAMPercentage=70
```

SerialGC is preferred over G1GC on constrained memory — lower overhead, simpler pause model.

### Environment variables to set on Koyeb

```
DB_URL=jdbc:postgresql://<supabase-host>:5432/postgres
DB_USERNAME=postgres
DB_PASSWORD=<supabase-password>
OPENAI_API_KEY=<key>          # or CLAUDE_API_KEY
GASTOS_AI_PROVIDER=openai     # or claude
GASTOS_SEED_SAMPLE_DATA=false # do not seed in prod
SPRING_PROFILES_ACTIVE=prod
SPRING_JPA_HIBERNATE_DDL_AUTO=validate
```

### CORS

Before deploying, update `WebConfig` to restrict CORS to the Vercel URL:

```java
config.addAllowedOrigin("https://your-app.vercel.app");
```

---

## Frontend — Vercel

1. Connect the GitHub repo to Vercel
2. Set the root directory to `frontend/`
3. Build command: `npm run build`
4. Output directory: `dist`
5. Set environment variable:
   ```
   VITE_API_URL=https://your-koyeb-url.koyeb.app
   ```

Vercel auto-deploys on push to `main`. The SPA uses React Router — add a `vercel.json` to handle client-side routing:

```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

---

## CI — GitHub Actions

`.github/workflows/ci.yml` runs backend tests on every push to `main`/`master` and on pull requests. It uses `eclipse-temurin:25` and Maven cache.

Frontend linting/build is not yet in CI — add a `frontend-ci` job if needed.

---

## Checklist before first production deploy

- [ ] Flyway migrations created for current schema
- [ ] `SPRING_JPA_HIBERNATE_DDL_AUTO=validate` set
- [ ] `GASTOS_SEED_SAMPLE_DATA=false`
- [ ] CORS restricted to Vercel domain
- [ ] `vercel.json` rewrite rule in place
- [ ] Supabase connection string tested locally
- [ ] All secrets in Koyeb env vars, not in source
