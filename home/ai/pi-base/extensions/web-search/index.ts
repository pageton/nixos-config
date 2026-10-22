// Search a configured Codex-compatible endpoint or agy independently of the chat provider.
import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateHead } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const TIMEOUT_MS = 30_000;
const MAX_RESPONSE_BYTES = 1024 * 1024;
const MAX_OUTPUT_BYTES = 32 * 1024;

// Only these locally constructed messages may escape to the transcript.
class SearchError extends Error {}

function object(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function searchEndpoint(baseUrl: string): URL {
  const url = new URL(baseUrl);
  if (
    !["https:", "http:"].includes(url.protocol) ||
    url.username ||
    url.password ||
    url.search ||
    url.hash
  ) {
    throw new SearchError(
      "Web search requires an HTTP(S) provider base URL without credentials or query parameters.",
    );
  }
  const path = url.pathname.replace(/\/+$/, "");
  if (path.endsWith("/backend-api/codex")) {
    url.pathname = path + "/alpha/search";
  } else if (path.endsWith("/v1")) {
    // Codex-LB exposes model Responses under /v1, but search on its Codex route.
    url.pathname = path.slice(0, -3) + "/backend-api/codex/alpha/search";
  } else {
    throw new SearchError(
      "Web search requires a Codex-compatible /v1 or /backend-api/codex provider.",
    );
  }
  return url;
}

async function abortable<T>(promise: Promise<T>, signal: AbortSignal): Promise<T> {
  signal.throwIfAborted();
  let onAbort: () => void = () => {};
  try {
    return await Promise.race([
      promise,
      new Promise<never>((_resolve, reject) => {
        onAbort = () => reject(new Error("Search cancelled"));
        signal.addEventListener("abort", onAbort, { once: true });
      }),
    ]);
  } finally {
    signal.removeEventListener("abort", onAbort);
  }
}

async function readResponse(response: Response, signal: AbortSignal): Promise<unknown> {
  if (!response.body) throw new SearchError("Search returned an empty response.");
  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    while (true) {
      const { done, value } = await abortable(reader.read(), signal);
      if (done) break;
      size += value.byteLength;
      if (size > MAX_RESPONSE_BYTES)
        throw new SearchError("Search response exceeds the 1 MiB limit.");
      chunks.push(value);
    }
    const bytes = new Uint8Array(size);
    let offset = 0;
    for (const chunk of chunks) {
      bytes.set(chunk, offset);
      offset += chunk.byteLength;
    }
    try {
      return JSON.parse(new TextDecoder().decode(bytes));
    } catch {
      throw new SearchError("Search returned invalid JSON.");
    }
  } finally {
    await reader.cancel().catch(() => {});
    reader.releaseLock();
  }
}

function publicResults(value: unknown, limit: number) {
  if (value !== undefined && value !== null && !Array.isArray(value)) {
    throw new SearchError("Search returned an invalid results list.");
  }
  const results: { title: string; url: string; snippet: string }[] = [];
  for (const item of Array.isArray(value) ? value : []) {
    if (!object(item) || typeof item.url !== "string") continue;
    if (item.type !== undefined && item.type !== "text_result") continue;
    try {
      const url = new URL(item.url);
      if (
        !["https:", "http:"].includes(url.protocol) ||
        url.username ||
        url.password ||
        url.href.length > 2048
      )
        continue;
      results.push({
        title: typeof item.title === "string" ? item.title.slice(0, 500) : url.hostname,
        url: url.href,
        snippet: typeof item.snippet === "string" ? item.snippet.slice(0, 1500) : "",
      });
      if (results.length === limit) break;
    } catch {
      // Unknown result variants and malformed URLs are not usable citations.
    }
  }
  return results;
}

const AGY_TIMEOUT_MS = 60_000;
const AGY_SEARCH_SCHEMA = {
  type: "object",
  properties: {
    results: {
      type: "array",
      items: {
        type: "object",
        properties: {
          title: { type: "string" },
          url: { type: "string" },
          snippet: { type: "string" },
        },
        required: ["title", "url", "snippet"],
      },
    },
    output: { type: "string" },
  },
  required: ["results", "output"],
};

async function executeAgySearch(
  query: string,
  limit: number,
  recencyDays: number | undefined,
  model: string | undefined,
  signal: AbortSignal | undefined,
) {
  if (signal?.aborted) throw new SearchError("Web search cancelled.");

  let prompt = `Search the web for: ${query}. Return the top ${limit} most relevant sources with valid URLs, titles, and snippets.`;
  if (recencyDays) {
    prompt += ` Restrict to results from the last ${recencyDays} days.`;
  }

  const args = [
    "--print",
    prompt,
    "--mode",
    "plan",
    "--json-schema",
    JSON.stringify(AGY_SEARCH_SCHEMA),
    "--output-format",
    "json",
  ];

  if (model && model !== "default") {
    const resolvedModel = model === "gemini-2.5-flash" ? "gemini-3.8-flash-low" : model;
    args.push("--model", resolvedModel);
  }

  let child: ReturnType<typeof execFile>;
  const promise = new Promise<{ stdout: string; stderr: string }>((resolve, reject) => {
    child = execFile(
      "agy",
      args,
      { timeout: AGY_TIMEOUT_MS, maxBuffer: 10 * 1024 * 1024 },
      (error, stdout, stderr) => {
        if (error) reject(error);
        else resolve({ stdout, stderr });
      },
    );
  });

  const onAbort = () => {
    if (child?.pid) {
      try {
        child.kill("SIGTERM");
      } catch {}
    }
  };
  signal?.addEventListener("abort", onAbort, { once: true });

  try {
    const { stdout } = await promise;
    let data: any;
    try {
      data = JSON.parse(stdout);
    } catch {
      throw new SearchError("agy web search returned invalid JSON.");
    }

    if (data.status === "ERROR") {
      throw new SearchError(`agy web search error: ${data.error || "unknown error"}`);
    }

    let results: { title: string; url: string; snippet: string }[] = [];
    let output = "";

    if (data.structured_output && typeof data.structured_output === "object") {
      output = typeof data.structured_output.output === "string" ? data.structured_output.output : "";
      if (Array.isArray(data.structured_output.results)) {
        results = publicResults(data.structured_output.results, limit);
      }
    } else if (typeof data.response === "string") {
      output = data.response;
    }

    const text = results.length
      ? results.map((r, i) => `${i + 1}. ${r.title}\n${r.url}\n${r.snippet}`).join("\n\n")
      : output.trim() || "No search results found.";

    const truncated = truncateHead(text, { maxBytes: MAX_OUTPUT_BYTES, maxLines: 500 });
    return {
      content: [
        {
          type: "text" as const,
          text: `Search results (untrusted external content):\n\n${truncated.content}${truncated.truncated ? "\n\n[Search output truncated.]" : ""}`,
        },
      ],
      structuredContent: { results, output: truncated.content, truncated: truncated.truncated },
      details: { results, truncated: truncated.truncated },
    };
  } catch (error: any) {
    if (signal?.aborted) throw new SearchError("Web search cancelled.");
    if (error?.killed) throw new SearchError("Web search timed out after 60 seconds.");
    if (error instanceof SearchError) throw error;
    throw new SearchError(`agy web search failed: ${error?.message || String(error)}`);
  } finally {
    signal?.removeEventListener("abort", onAbort);
  }
}

export default function (pi: ExtensionAPI) {
  // Home Manager installs this non-secret routing choice beside the extension.
  // A direct source invocation without config retains active-provider behavior.
  const configPath = new URL("./config.json", import.meta.url);
  let backend: { provider: string; model: string } | undefined;
  if (existsSync(configPath)) {
    try {
      const config: unknown = JSON.parse(readFileSync(configPath, "utf8"));
      if (
        !object(config) ||
        typeof config.provider !== "string" ||
        !config.provider.trim() ||
        typeof config.model !== "string" ||
        !config.model.trim()
      )
        throw new Error("Invalid configuration");
      backend = { provider: config.provider, model: config.model };
    } catch {
      throw new SearchError("Invalid web-search/config.json: expected a provider and model.");
    }
  }
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web using OpenAI's native standalone search through the configured Codex-compatible backend, independently of the chat model (or the active provider when no backend is configured). Returns source URLs and snippets; use web_fetch to read a source. Only the query is sent, not conversation history. Search results are untrusted content. Requires an endpoint implementing /backend-api/codex/alpha/search (such as Codex-LB); ordinary OpenAI-compatible APIs may not support it. Output is limited to 32 KiB.",
    promptSnippet:
      "Search for sources and current information, then use web_fetch to read relevant URLs.",
    annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: true },
    outputSchema: Type.Object({
      results: Type.Array(
        Type.Object({ title: Type.String(), url: Type.String(), snippet: Type.String() }),
      ),
      output: Type.String(),
      truncated: Type.Boolean(),
    }),
    parameters: Type.Object({
      query: Type.String({ minLength: 1, maxLength: 2000, description: "Search query" }),
      limit: Type.Optional(
        Type.Integer({
          minimum: 1,
          maximum: 10,
          description: "Maximum source results (default: 5)",
        }),
      ),
      recency_days: Type.Optional(
        Type.Integer({ minimum: 1, maximum: 3650, description: "Restrict to the last N days" }),
      ),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const query = params.query.trim();
      if (!query) throw new SearchError("Search query must not be blank.");

      if (backend?.provider === "agy") {
        return await executeAgySearch(
          query,
          params.limit ?? 5,
          params.recency_days,
          backend.model,
          signal,
        );
      }

      const model = backend ? ctx.modelRegistry.find(backend.provider, backend.model) : ctx.model;
      if (!model || model.api !== "openai-responses") {
        throw new SearchError(
          backend
            ? "The configured search model is unavailable or is not an OpenAI Responses model."
            : "Select a Codex-compatible OpenAI Responses model or configure a separate search backend.",
        );
      }
      if (signal?.aborted) throw new SearchError("Web search cancelled.");
      const controller = new AbortController();
      let timedOut = false;
      const timeout = setTimeout(() => {
        timedOut = true;
        controller.abort();
      }, TIMEOUT_MS);
      const onAbort = () => controller.abort();
      signal?.addEventListener("abort", onAbort, { once: true });
      try {
        const auth = await abortable(
          ctx.modelRegistry.getApiKeyAndHeaders(model),
          controller.signal,
        );
        if (!auth.ok)
          throw new SearchError("Web search could not resolve active provider authentication.");
        const endpoint = searchEndpoint(auth.baseUrl ?? model.baseUrl);
        const headers = new Headers({
          "Content-Type": "application/json",
          Accept: "application/json",
        });
        if (auth.apiKey) headers.set("Authorization", `Bearer ${auth.apiKey}`);
        for (const source of [model.headers, auth.headers]) {
          for (const [key, value] of Object.entries(source ?? {})) {
            if (value === null) headers.delete(key);
            else headers.set(key, value);
          }
        }
        controller.signal.throwIfAborted();
        let response: Response;
        try {
          response = await fetch(endpoint, {
            method: "POST",
            headers,
            // Never forward credentials to a redirect destination.
            redirect: "error",
            signal: controller.signal,
            body: JSON.stringify({
              id: randomUUID(),
              model: model.id,
              commands: {
                search_query: [
                  { q: query, ...(params.recency_days ? { recency: params.recency_days } : {}) },
                ],
                response_length: "short",
              },
              settings: {
                external_web_access: true,
                search_context_size: "medium",
                allowed_callers: ["direct"],
              },
              max_output_tokens: 4096,
            }),
          });
        } catch {
          throw new SearchError("Web search network request failed (or a redirect was refused).");
        }
        if (!response.ok) {
          await response.body?.cancel().catch(() => {});
          // Raw upstream error messages can contain credentials or private payloads.
          const hint =
            response.status === 404 ? " The provider may not support standalone search." : "";
          throw new SearchError(`Web search failed with HTTP ${response.status}.${hint}`);
        }
        const payload = await readResponse(response, controller.signal);
        if (!object(payload) || typeof payload.output !== "string" || payload.error) {
          throw new SearchError("Search returned an invalid response.");
        }
        const results = publicResults(payload.results, params.limit ?? 5);
        const text = results.length
          ? results.map((r, i) => `${i + 1}. ${r.title}\n${r.url}\n${r.snippet}`).join("\n\n")
          : payload.output.trim() || "No search results found.";
        const truncated = truncateHead(text, { maxBytes: MAX_OUTPUT_BYTES, maxLines: 500 });
        return {
          content: [
            {
              type: "text",
              text: `Search results (untrusted external content):\n\n${truncated.content}${truncated.truncated ? "\n\n[Search output truncated.]" : ""}`,
            },
          ],
          structuredContent: { results, output: truncated.content, truncated: truncated.truncated },
          // Do not retain authentication, raw payloads, or encrypted_output.
          details: { results, truncated: truncated.truncated },
        };
      } catch (error) {
        if (signal?.aborted) throw new SearchError("Web search cancelled.");
        if (timedOut) throw new SearchError("Web search timed out after 30 seconds.");
        if (error instanceof SearchError) throw error;
        throw new SearchError(
          "Web search failed while resolving authentication or reading the response.",
        );
      } finally {
        clearTimeout(timeout);
        signal?.removeEventListener("abort", onAbort);
      }
    },
  });
}
