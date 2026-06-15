import type { ChatPreviewData, ParsedExpenseResult } from "../../api/types";

/** A single chat transcript entry: a user/assistant message and any attached draft/action/preview state. */
export interface Message {
  role: "user" | "assistant";
  content: unknown;
  timestamp: Date;
  attachmentUrl?: string;
  attachmentName?: string;
  draft?: ParsedExpenseResult;
  draftSaved?: boolean;
  draftEdits?: { amount?: number; date?: string; time?: string; description?: string };
  categoryOverride?: string;
  actionType?: "success" | "error";
  actionResult?: unknown;
  actionPreview?: ChatPreviewData & { originalMessage: string };
  actionPreviewConfirmed?: boolean;
  editedParams?: Record<string, unknown>;
  disambiguateItems?: Array<{ id: number; description: string; amount: number; date: string }>;
  selectedDisambiguateIds?: number[];
  draftCancelled?: boolean;
}
