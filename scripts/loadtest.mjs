// Dependency-free load test. Usage: node scripts/loadtest.mjs <token> [concurrency] [reqsPerEndpoint]
// Hits read-heavy endpoints against http://localhost:8080. Reports p50/p95/p99 latency, RPS, errors.
import http from "node:http";

const token = process.argv[2];
const CONC = parseInt(process.argv[3] || "50", 10);
const PER = parseInt(process.argv[4] || "500", 10);
const BASE = "http://localhost:8080";
const month = new Date().toISOString().slice(0, 7);

const ENDPOINTS = [
  `/expenses/page?page=0&size=50`,
  `/budgets/summary?month=${month}`,
  `/budget-rules/summary?month=${month}`,
  `/expenses/report/category`,
  `/user/entitlements`,
];

const agent = new http.Agent({ keepAlive: true, maxSockets: CONC });

function once(path) {
  return new Promise((resolve) => {
    const t = process.hrtime.bigint();
    const req = http.get(BASE + path, { headers: { Authorization: `Bearer ${token}` }, agent }, (r) => {
      r.on("data", () => {});
      r.on("end", () => resolve({ ms: Number(process.hrtime.bigint() - t) / 1e6, code: r.statusCode }));
    });
    req.on("error", () => resolve({ ms: -1, code: 0 }));
  });
}

function pct(arr, p) {
  const a = arr.slice().sort((x, y) => x - y);
  return a[Math.min(a.length - 1, Math.floor((p / 100) * a.length))];
}

async function runEndpoint(path) {
  const lat = [];
  let errors = 0;
  let next = 0;
  const wall0 = Date.now();
  async function worker() {
    while (next < PER) {
      next++;
      const { ms, code } = await once(path);
      if (code === 200 && ms >= 0) lat.push(ms);
      else errors++;
    }
  }
  await Promise.all(Array.from({ length: CONC }, worker));
  const secs = (Date.now() - wall0) / 1000;
  const avg = lat.reduce((s, x) => s + x, 0) / (lat.length || 1);
  console.log(
    `${path}\n  ok=${lat.length} err=${errors} rps=${(PER / secs).toFixed(0)}` +
      ` avg=${avg.toFixed(1)}ms p50=${pct(lat, 50).toFixed(1)} p95=${pct(lat, 95).toFixed(1)} p99=${pct(lat, 99).toFixed(1)} max=${Math.max(...lat).toFixed(1)}`,
  );
}

(async () => {
  console.log(`Load test: concurrency=${CONC}, ${PER} reqs/endpoint, ${ENDPOINTS.length} endpoints`);
  for (const e of ENDPOINTS) await runEndpoint(e);
})();
