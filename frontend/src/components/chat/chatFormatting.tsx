import type { ReactNode } from "react";
import { formatCurrency, formatDate } from "../../lib/formatters";
import type { Message } from "./chatTypes";

// Pure formatting + NL-query answer rendering for the chat widget. Extracted from ChatWidget;
// stateless and behavior-preserving.

export const HIDDEN_FIELDS = new Set(["id", "category_id", "categoryid"]);
const CURRENCY_KEYWORDS = ["amount", "total", "sum", "spent", "cost", "price", "fee"];

export function isCurrencyKey(key: string): boolean {
  const k = key.toLowerCase();
  return CURRENCY_KEYWORDS.some((w) => k.includes(w));
}

export function isDateKey(key: string): boolean {
  const k = key.toLowerCase();
  return k.includes("date") || k === "created_at" || k === "updated_at";
}

export function humanLabel(key: string): string {
  const labels: Record<string, string> = {
    amount: "Amount",
    description: "Description",
    category: "Category",
    date: "Date",
    total: "Total",
    month: "Month",
    name: "Category",
    count: "Count",
    note: "Note",
  };
  return (
    labels[key.toLowerCase()] ??
    key.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())
  );
}

export function formatField(key: string, value: unknown): string {
  if (value === null || value === undefined) return "—";
  if (isCurrencyKey(key)) return formatCurrency(Number(value));
  if (isDateKey(key)) return formatDate(String(value));
  return String(value);
}

export function renderAnswer(answer: unknown, accentText: string): ReactNode {
  if (answer === null || answer === undefined)
    return <span>No results found.</span>;
  if (typeof answer === "string") return <span className={accentText}>{answer}</span>;
  if (typeof answer === "number")
    return (
      <span className={`font-semibold ${accentText}`}>
        {formatCurrency(answer)}
      </span>
    );

  if (Array.isArray(answer)) {
    if (answer.length === 0) return <span>No results found.</span>;
    const rows = answer as Record<string, unknown>[];
    const keys = Object.keys(rows[0]).filter(
      (k) => !HIDDEN_FIELDS.has(k.toLowerCase())
    );
    const isExpenseList = keys.some((k) => k.toLowerCase() === "description");

    if (isExpenseList) {
      return (
        <div className="space-y-2 mt-1 w-full">
          <p className="text-xs text-gray-400">
            {rows.length} result{rows.length !== 1 ? "s" : ""}
          </p>
          {rows.map((row, i) => (
            <div
              key={i}
              className="bg-gray-50 dark:bg-gray-700/50 rounded-xl px-3 py-2.5 border border-gray-100 dark:border-gray-700"
            >
              <div className="flex justify-between items-start gap-2">
                <span className="text-sm text-gray-800 dark:text-gray-200 font-medium leading-snug flex-1">
                  {String(row.description ?? "—")}
                </span>
                {row.amount != null && (
                  <span className={`text-sm font-semibold whitespace-nowrap shrink-0 ${accentText}`}>
                    {formatCurrency(Number(row.amount))}
                  </span>
                )}
              </div>
              <div className="flex flex-wrap items-center gap-x-2 gap-y-1 mt-1.5">
                {row.category != null && (
                  <span className={`text-xs px-2 py-0.5 rounded-full border ${accentText} bg-opacity-10`}>
                    {String(row.category)}
                  </span>
                )}
                {row.date != null && (
                  <span className="text-xs text-gray-400">
                    {formatDate(String(row.date))}
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      );
    }

    const firstRow = rows[0];
    const labelKeys = keys.filter(
      (k) => !isCurrencyKey(k) && typeof firstRow[k] !== "number"
    );
    const metricKeys = keys.filter(
      (k) => isCurrencyKey(k) || typeof firstRow[k] === "number"
    );
    const orderedKeys = [...labelKeys, ...metricKeys];

    return (
      <div className="w-full mt-1 divide-y divide-gray-100 dark:divide-gray-700">
        {rows.map((row, i) => (
          <div key={i} className="flex items-center justify-between gap-3 py-2">
            {orderedKeys.map((k, ki) => (
              <span
                key={k}
                className={
                  ki === orderedKeys.length - 1
                    ? `font-semibold text-sm whitespace-nowrap ${accentText}`
                    : "text-sm text-gray-700 dark:text-gray-300 truncate"
                }
              >
                {formatField(k, row[k])}
              </span>
            ))}
          </div>
        ))}
      </div>
    );
  }

  if (typeof answer === "object" && answer !== null) {
    const row = answer as Record<string, unknown>;
    const keys = Object.keys(row).filter(
      (k) => !HIDDEN_FIELDS.has(k.toLowerCase())
    );
    return (
      <div className="space-y-1.5 mt-1 w-full">
        {keys.map((k) => (
          <div key={k} className="flex justify-between gap-2">
            <span className="text-xs text-gray-500 dark:text-gray-400">{humanLabel(k)}</span>
            <span className="text-sm font-medium dark:text-gray-200">{formatField(k, row[k])}</span>
          </div>
        ))}
      </div>
    );
  }

  return <span>{String(answer)}</span>;
}

export function renderActionResult(msg: Message) {
  const isDelete = typeof msg.content === "string" && msg.content.toLowerCase().includes("deleted");
  return (
    <div className={`mt-2 border-l-2 ${isDelete ? "border-red-500 dark:border-red-400" : "border-green-500 dark:border-green-400"} pl-3`}>
      <p className={`text-sm font-medium ${isDelete ? "text-red-700 dark:text-red-300" : "text-green-700 dark:text-green-300"}`}>{msg.content as string}</p>
      {Boolean(msg.actionResult && typeof msg.actionResult === "object" && "id" in (msg.actionResult as object)) && (
        <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">ID: #{(msg.actionResult as { id: number }).id}</p>
      )}
    </div>
  );
}
