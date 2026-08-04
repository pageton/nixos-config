import { AsyncLocalStorage } from "node:async_hooks";
import { spawn } from "node:child_process";
import { randomBytes } from "node:crypto";
import { appendFile, chmod, mkdir, readFile, rename, rm, stat, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import path from "node:path";

export const HOOK_RUNTIME_VERSION = 1;

export const HOOK_EVENTS = Object.freeze([
  "before_task",
  "after_task",
  "on_task_success",
  "on_task_failure",
  "on_task_cancelled",
  "before_agent",
  "after_agent",
  "on_agent_success",
  "on_agent_failure",
  "on_agent_timeout",
  "before_tool_call",
  "after_tool_call",
  "on_tool_success",
  "on_tool_failure",
  "before_file_read",
  "after_file_read",
  "before_file_write",
  "after_file_write",
  "before_file_delete",
  "after_file_delete",
  "before_command",
  "after_command",
  "on_command_success",
  "on_command_failure",
  "on_command_timeout",
  "before_git_operation",
  "after_git_operation",
  "on_git_success",
  "on_git_failure",
  "before_approval_request",
  "after_approval_granted",
  "after_approval_denied",
  "on_error",
  "before_retry",
  "after_retry",
  "before_plan",
  "after_plan",
  "on_agent_cancelled",
  "before_cancel",
  "after_cancel",
  "before_git_prepare",
  "before_git_commit",
  "after_git_commit",
  "before_git_push",
  "after_git_push",
  "after_approval_rejected",
  "before_rollback_prepare",
  "before_rollback",
  "after_rollback",
]);

export const HOOK_STATUSES = Object.freeze([
  "continue",
  "modify",
  "skip",
  "block",
  "cancel",
  "retry",
]);
export const HOOK_FAILURE_POLICIES = Object.freeze([
  "ignore",
  "warn",
  "fail_operation",
  "fail_task",
]);
export const HOOK_EXECUTION_MODES = Object.freeze(["serial", "parallel"]);
export const HOOK_PERMISSIONS = Object.freeze([
  "read_task_context",
  "modify_task_context",
  "read_agent_context",
  "modify_agent_context",
  "read_tool_metadata",
  "modify_tool_arguments",
  "read_file_metadata",
  "read_file_content",
  "read_command",
  "modify_command",
  "read_git_state",
  "read_approval_context",
  "read_error_context",
  "write_logs",
  "request_approval",
  "block_operation",
  "cancel_task",
  "retry_operation",
]);

const EVENT_SET = new Set(HOOK_EVENTS);
const STATUS_SET = new Set(HOOK_STATUSES);
const FAILURE_POLICY_SET = new Set(HOOK_FAILURE_POLICIES);
const EXECUTION_MODE_SET = new Set(HOOK_EXECUTION_MODES);
const PERMISSION_SET = new Set(HOOK_PERMISSIONS);
const CONTROL_PERMISSIONS = new Set([
  "modify_task_context",
  "modify_agent_context",
  "modify_tool_arguments",
  "modify_command",
  "request_approval",
  "block_operation",
  "cancel_task",
  "retry_operation",
]);
const MANDATORY_BUILTINS = new Set([
  "approval-recorder",
  "git-baseline",
  "permission-guard",
  "protected-paths",
  "workspace-boundary",
  "command-policy",
  "git-safety",
]);
const INTERCEPTION_EVENTS = new Set([
  "before_task",
  "before_agent",
  "before_tool_call",
  "before_file_read",
  "before_file_write",
  "before_file_delete",
  "before_command",
  "before_git_operation",
  "before_approval_request",
  "before_retry",
  "before_plan",
  "before_cancel",
  "before_git_prepare",
  "before_git_commit",
  "before_git_push",
  "before_rollback_prepare",
  "before_rollback",
]);
const RESULT_PRECEDENCE = Object.freeze({
  continue: 0,
  modify: 1,
  skip: 2,
  retry: 3,
  block: 4,
  cancel: 5,
});
const DEFAULT_TIMEOUT_MS = 5_000;
const MAX_HOOK_TIMEOUT_MS = 5 * 60 * 1_000;
const MAX_RESULT_REASON = 2_000;
const MAX_EXECUTION_RECORDS = 500;
const MAX_REPORT_BYTES = 4 * 1024 * 1024;
const SAFE_ENVIRONMENT_NAMES = [
  "HOME",
  "LANG",
  "LC_ALL",
  "LOGNAME",
  "NIX_SSL_CERT_FILE",
  "PATH",
  "SSL_CERT_FILE",
  "TERM",
  "TZ",
  "USER",
  "XDG_CACHE_HOME",
  "XDG_CONFIG_HOME",
  "XDG_DATA_HOME",
  "XDG_RUNTIME_DIR",
  "XDG_STATE_HOME",
  "ZCODE_ORCHESTRATOR_ROLE",
  "ZCODE_ORCHESTRATOR_RUN_ID",
  "ZCODE_ORCHESTRATOR_UNIT_ID",
  "ZCODE_ORCHESTRATOR_WORKSPACE",
];
const SENSITIVE_KEY = /(?:api[_-]?key|authorization|credential|password|secret|token|cookie)/iu;
const PATCH_SCHEMAS = Object.freeze({
  before_task: { task: "object", metadata: "object", tracing: "object", policies: "object", gitBaseline: "object" },
  before_agent: { agent: "object", metadata: "object", tracing: "object", policies: "object" },
  before_tool_call: { tool: "object", metadata: "object" },
  before_file_read: { file: "object", metadata: "object" },
  before_file_write: { file: "object", metadata: "object" },
  before_file_delete: { file: "object", metadata: "object" },
  before_command: { command: "object", metadata: "object" },
  before_git_operation: { git: "object", metadata: "object" },
  before_approval_request: { approval: "object", metadata: "object" },
  before_retry: { retry: "object", metadata: "object" },
  before_plan: { task: "object", metadata: "object" },
  before_cancel: { cancellation: "object", metadata: "object" },
  before_git_prepare: { git: "object", metadata: "object" },
  before_git_commit: { git: "object", metadata: "object" },
  before_git_push: { git: "object", metadata: "object" },
  before_rollback_prepare: { rollback: "object", metadata: "object" },
  before_rollback: { rollback: "object", metadata: "object" },
});

/** @typedef {"continue"|"modify"|"skip"|"block"|"cancel"|"retry"} HookStatus */
/** @typedef {"ignore"|"warn"|"fail_operation"|"fail_task"} HookFailurePolicy */
/** @typedef {"serial"|"parallel"} HookExecutionMode */
/**
 * @typedef {Object} HookResult
 * @property {HookStatus} status
 * @property {string|null} reason
 * @property {Record<string, unknown>} context_patch
 * @property {Record<string, unknown>} metadata
 * @property {boolean} require_approval
 * @property {boolean} retry
 */

export class HookConfigurationError extends Error {
  constructor(message) {
    super(message);
    this.name = "HookConfigurationError";
  }
}

export class HookOperationError extends Error {
  constructor(message, status = "block", hook = null) {
    super(message);
    this.name = "HookOperationError";
    this.status = status;
    this.hook = hook;
  }
}

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function boundedString(value, maximum = MAX_RESULT_REASON) {
  const text = typeof value === "string" ? value : String(value ?? "");
  return text.length <= maximum ? text : `${text.slice(0, maximum)}\n[truncated]`;
}

function uniqueStrings(value) {
  if (!Array.isArray(value)) throw new HookConfigurationError("hook permissions must be an array");
  return [...new Set(value.map((item) => {
    if (typeof item !== "string" || !PERMISSION_SET.has(item)) {
      throw new HookConfigurationError(`unknown hook permission: ${String(item)}`);
    }
    return item;
  }))];
}

function assertOnlyKeys(value, allowed, label) {
  for (const key of Object.keys(value)) {
    if (!allowed.has(key)) throw new HookConfigurationError(`${label} contains unknown field: ${key}`);
  }
}

function cloneJson(value) {
  if (value === undefined) return undefined;
  return JSON.parse(JSON.stringify(value));
}

function redactSensitive(value, key = "") {
  if (SENSITIVE_KEY.test(key)) return "[REDACTED]";
  if (Array.isArray(value)) return value.map((item) => redactSensitive(item));
  if (!isRecord(value)) return value;
  return Object.fromEntries(Object.entries(value).map(([childKey, child]) => [childKey, redactSensitive(child, childKey)]));
}

function mergeRecords(base, patch) {
  const output = isRecord(base) ? { ...base } : {};
  for (const [key, value] of Object.entries(patch)) {
    output[key] = isRecord(value) && isRecord(output[key]) ? mergeRecords(output[key], value) : cloneJson(value);
  }
  return output;
}

function normalizeInteger(value, fallback, minimum, maximum, label) {
  const parsed = Number.parseInt(String(value ?? fallback), 10);
  if (!Number.isSafeInteger(parsed) || parsed < minimum || parsed > maximum) {
    throw new HookConfigurationError(`${label} must be an integer between ${minimum} and ${maximum}`);
  }
  return parsed;
}

function defaultResult() {
  return {
    status: "continue",
    reason: null,
    context_patch: {},
    metadata: {},
    require_approval: false,
    retry: false,
  };
}

function normalizeResult(value) {
  if (value === undefined || value === null) return defaultResult();
  if (!isRecord(value)) throw new Error("hook result must be an object");
  assertOnlyKeys(
    value,
    new Set(["status", "reason", "context_patch", "metadata", "require_approval", "retry"]),
    "hook result",
  );
  const status = value.status ?? "continue";
  if (!STATUS_SET.has(status)) throw new Error(`invalid hook result status: ${String(status)}`);
  if (value.reason !== undefined && value.reason !== null && typeof value.reason !== "string") {
    throw new Error("hook result reason must be a string or null");
  }
  const contextPatch = value.context_patch ?? {};
  const metadata = value.metadata ?? {};
  if (!isRecord(contextPatch)) throw new Error("hook result context_patch must be an object");
  if (!isRecord(metadata)) throw new Error("hook result metadata must be an object");
  if (value.require_approval !== undefined && typeof value.require_approval !== "boolean") {
    throw new Error("hook result require_approval must be a boolean");
  }
  if (value.retry !== undefined && typeof value.retry !== "boolean") {
    throw new Error("hook result retry must be a boolean");
  }
  if (status === "modify" && Object.keys(contextPatch).length === 0) {
    throw new Error("modify hook result requires a non-empty context_patch");
  }
  return {
    status,
    reason: value.reason === undefined || value.reason === null ? null : boundedString(value.reason),
    context_patch: cloneJson(contextPatch),
    metadata: redactSensitive(cloneJson(metadata)),
    require_approval: value.require_approval === true,
    retry: value.retry === true || status === "retry",
  };
}

function validatePatch(event, patch) {
  if (Object.keys(patch).length === 0) return;
  const schema = PATCH_SCHEMAS[event];
  if (!schema) throw new Error(`${event} does not permit context modifications`);
  for (const [key, value] of Object.entries(patch)) {
    if (!(key in schema)) throw new Error(`${event} context patch contains unsupported field: ${key}`);
    if (schema[key] === "object" && !isRecord(value)) throw new Error(`${event}.${key} patch must be an object`);
  }
}

function modificationPermission(event) {
  if (event === "before_task") return "modify_task_context";
  if (event === "before_agent") return "modify_agent_context";
  if (event === "before_tool_call") return "modify_tool_arguments";
  if (event === "before_command") return "modify_command";
  if (event === "before_retry") return "retry_operation";
  return null;
}

function validateResultPermissions(definition, event, result) {
  const permissions = new Set(definition.permissions);
  if (result.status === "modify") {
    const required = modificationPermission(event);
    if (!required || !permissions.has(required)) throw new Error(`${definition.name} cannot modify ${event} context`);
  }
  if (["skip", "block"].includes(result.status) && !permissions.has("block_operation")) {
    throw new Error(`${definition.name} lacks block_operation permission`);
  }
  if (result.status === "cancel" && !permissions.has("cancel_task")) {
    throw new Error(`${definition.name} lacks cancel_task permission`);
  }
  if (result.retry && !permissions.has("retry_operation")) {
    throw new Error(`${definition.name} lacks retry_operation permission`);
  }
  if (result.require_approval && !permissions.has("request_approval")) {
    throw new Error(`${definition.name} lacks request_approval permission`);
  }
}

function sanitizeContext(context, permissions) {
  const allowed = new Set(permissions);
  const output = {
    event: context.event,
    timestamp: context.timestamp,
    taskId: context.taskId ?? context.runId ?? null,
    runId: context.runId ?? null,
    unitId: context.unitId ?? null,
  };
  if (allowed.has("read_task_context") && isRecord(context.task)) output.task = redactSensitive(cloneJson(context.task));
  if (allowed.has("read_agent_context") && isRecord(context.agent)) output.agent = redactSensitive(cloneJson(context.agent));
  if (allowed.has("read_tool_metadata") && isRecord(context.tool)) output.tool = redactSensitive(cloneJson(context.tool));
  if (allowed.has("read_file_metadata") && isRecord(context.file)) {
    output.file = redactSensitive(cloneJson(context.file));
    if (!allowed.has("read_file_content")) delete output.file.content;
  }
  if (allowed.has("read_command") && isRecord(context.command)) {
    output.command = redactSensitive(cloneJson(context.command));
    delete output.command.environment;
  }
  if (allowed.has("read_git_state") && isRecord(context.git)) output.git = redactSensitive(cloneJson(context.git));
  if (allowed.has("read_approval_context") && isRecord(context.approval)) {
    output.approval = redactSensitive(cloneJson(context.approval));
  }
  if (allowed.has("read_error_context") && isRecord(context.error)) output.error = redactSensitive(cloneJson(context.error));
  if (isRecord(context.retry) && allowed.has("read_error_context")) output.retry = redactSensitive(cloneJson(context.retry));
  if (isRecord(context.metadata)) output.metadata = redactSensitive(cloneJson(context.metadata));
  return Object.freeze(output);
}

function validateDefinition(input, registrationOrder) {
  if (!isRecord(input)) throw new HookConfigurationError("hook definition must be an object");
  const allowedKeys = new Set([
    "name",
    "event",
    "handler",
    "enabled",
    "priority",
    "executionMode",
    "timeoutMs",
    "failurePolicy",
    "permissions",
    "mandatory",
    "category",
    "description",
  ]);
  assertOnlyKeys(input, allowedKeys, "hook definition");
  if (typeof input.name !== "string" || !/^[a-z0-9][a-z0-9-]{1,63}$/u.test(input.name)) {
    throw new HookConfigurationError("hook name must match ^[a-z0-9][a-z0-9-]{1,63}$");
  }
  if (!EVENT_SET.has(input.event)) throw new HookConfigurationError(`unknown hook event: ${String(input.event)}`);
  if (typeof input.handler !== "function") throw new HookConfigurationError(`${input.name} requires a handler function`);
  if (input.enabled !== undefined && typeof input.enabled !== "boolean") {
    throw new HookConfigurationError(`${input.name}.enabled must be a boolean`);
  }
  const executionMode = input.executionMode ?? "serial";
  if (!EXECUTION_MODE_SET.has(executionMode)) {
    throw new HookConfigurationError(`${input.name} has invalid execution mode: ${executionMode}`);
  }
  const permissions = uniqueStrings(input.permissions ?? []);
  if (executionMode === "parallel" && (INTERCEPTION_EVENTS.has(input.event) || permissions.some((item) => CONTROL_PERMISSIONS.has(item)))) {
    throw new HookConfigurationError(`${input.name} cannot run in parallel because it can intercept or mutate execution`);
  }
  const failurePolicy = input.failurePolicy ?? "warn";
  if (!FAILURE_POLICY_SET.has(failurePolicy)) {
    throw new HookConfigurationError(`${input.name} has invalid failure policy: ${failurePolicy}`);
  }
  return Object.freeze({
    name: input.name,
    event: input.event,
    handler: input.handler,
    enabled: input.enabled ?? true,
    priority: normalizeInteger(input.priority, 100, -1000, 1000, `${input.name}.priority`),
    executionMode,
    timeoutMs: normalizeInteger(input.timeoutMs, DEFAULT_TIMEOUT_MS, 1, MAX_HOOK_TIMEOUT_MS, `${input.name}.timeoutMs`),
    failurePolicy,
    permissions,
    mandatory: input.mandatory === true,
    category: typeof input.category === "string" ? input.category : "automation",
    description: typeof input.description === "string" ? boundedString(input.description, 500) : "",
    registrationOrder,
  });
}

async function runBounded(items, maximum, operation) {
  const output = new Array(items.length);
  let cursor = 0;
  const workers = Array.from({ length: Math.min(maximum, items.length) }, async () => {
    while (cursor < items.length) {
      const index = cursor;
      cursor += 1;
      output[index] = await operation(items[index], index);
    }
  });
  await Promise.all(workers);
  return output;
}

async function runWithTimeout(handler, context, timeoutMs, parentSignal) {
  const controller = new AbortController();
  let timedOut = false;
  let timer;
  let rejectCancellation;
  const cancellation = new Promise((_, reject) => {
    rejectCancellation = reject;
  });
  const abort = () => {
    const reason = parentSignal?.reason ?? new Error("hook dispatch cancelled");
    controller.abort(reason);
    rejectCancellation(reason);
  };
  if (parentSignal?.aborted) abort();
  else parentSignal?.addEventListener("abort", abort, { once: true });
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => {
      timedOut = true;
      const error = new Error(`hook timed out after ${timeoutMs}ms`);
      error.timedOut = true;
      controller.abort(error);
      reject(error);
    }, timeoutMs);
  });
  try {
    const value = await Promise.race([
      handler(context, { signal: controller.signal }),
      timeout,
      cancellation,
    ]);
    return { value, timedOut };
  } finally {
    clearTimeout(timer);
    parentSignal?.removeEventListener("abort", abort);
  }
}

export class HookStateStore {
  constructor(stateDir) {
    this.path = path.join(stateDir, "hook-state.json");
  }

  async load() {
    try {
      const value = JSON.parse(await readFile(this.path, "utf8"));
      if (!isRecord(value) || value.version !== 1 || !isRecord(value.enabled)) {
        throw new HookConfigurationError(`invalid hook state file: ${this.path}`);
      }
      return value;
    } catch (error) {
      if (error?.code === "ENOENT") return { version: 1, enabled: {} };
      throw error;
    }
  }

  async save(state) {
    await mkdir(path.dirname(this.path), { recursive: true, mode: 0o700 });
    const temporary = `${this.path}.${process.pid}.${randomBytes(4).toString("hex")}.tmp`;
    await writeFile(temporary, `${JSON.stringify(state, null, 2)}\n`, { mode: 0o600 });
    await rename(temporary, this.path);
    await chmod(this.path, 0o600);
  }

  async set(name, enabled) {
    const state = await this.load();
    state.enabled[name] = enabled;
    await this.save(state);
  }
}

export class HookManager {
  constructor(options = {}) {
    this.enabled = options.enabled ?? true;
    this.maxDepth = normalizeInteger(options.maxDepth, 4, 1, 16, "hooks.maxDepth");
    this.maxParallel = normalizeInteger(options.maxParallel, 4, 1, 32, "hooks.maxParallel");
    this.unsafeAllowDisableMandatory = options.unsafeAllowDisableMandatory === true;
    if (!this.enabled && !this.unsafeAllowDisableMandatory) {
      throw new HookConfigurationError("disabling all hooks requires unsafeAllowDisableMandatory");
    }
    this.stateStore = options.stateStore ?? null;
    this.reporter = typeof options.reporter === "function" ? options.reporter : null;
    this.hooks = new Map(HOOK_EVENTS.map((event) => [event, []]));
    this.registrationOrder = 0;
    this.initialized = false;
    this.dispatchStorage = new AsyncLocalStorage();
    this.executionHistory = [];
  }

  register(definition) {
    const normalized = validateDefinition(definition, this.registrationOrder);
    this.registrationOrder += 1;
    const entries = this.hooks.get(normalized.event);
    if (entries.some((entry) => entry.name === normalized.name)) {
      throw new HookConfigurationError(`hook already registered for ${normalized.event}: ${normalized.name}`);
    }
    entries.push({ ...normalized });
    return () => this.unregister(normalized.event, normalized.name);
  }

  unregister(event, name) {
    if (!EVENT_SET.has(event)) throw new HookConfigurationError(`unknown hook event: ${String(event)}`);
    const entries = this.hooks.get(event);
    const index = entries.findIndex((entry) => entry.name === name);
    if (index < 0) return false;
    if (entries[index].mandatory && !this.unsafeAllowDisableMandatory) {
      throw new HookConfigurationError(`mandatory hook cannot be unregistered: ${name}`);
    }
    entries.splice(index, 1);
    return true;
  }

  async initialize() {
    if (this.initialized) return;
    if (this.stateStore) {
      const state = await this.stateStore.load();
      for (const entries of this.hooks.values()) {
        for (const entry of entries) {
          if (!(entry.name in state.enabled)) continue;
          if (entry.mandatory && state.enabled[entry.name] === false && !this.unsafeAllowDisableMandatory) {
            throw new HookConfigurationError(`mandatory hook cannot be disabled: ${entry.name}`);
          }
          entry.enabled = state.enabled[entry.name];
        }
      }
    }
    this.initialized = true;
  }

  list(filters = {}) {
    const records = [...this.hooks.values()]
      .flat()
      .filter((entry) => !filters.event || entry.event === filters.event)
      .filter((entry) => filters.enabled === undefined || entry.enabled === filters.enabled)
      .sort((left, right) => left.event.localeCompare(right.event) || left.priority - right.priority || left.registrationOrder - right.registrationOrder)
      .map(({ handler: _handler, registrationOrder, ...entry }) => ({ ...entry, registrationOrder }));
    return cloneJson(records);
  }

  show(name) {
    const records = this.list().filter((entry) => entry.name === name);
    if (records.length === 0) throw new HookConfigurationError(`unknown hook: ${name}`);
    return records;
  }


  detail(name) {
    return {
      definitions: this.show(name),
      recentExecutions: this.executionHistory.filter((record) => record.hook === name).slice(-50),
    };
  }
  async setEnabled(name, enabled) {
    if (typeof enabled !== "boolean") throw new HookConfigurationError("enabled must be a boolean");
    const entries = [...this.hooks.values()].flat().filter((entry) => entry.name === name);
    if (entries.length === 0) throw new HookConfigurationError(`unknown hook: ${name}`);
    if (!enabled && entries.some((entry) => entry.mandatory) && !this.unsafeAllowDisableMandatory) {
      throw new HookConfigurationError(`mandatory hook cannot be disabled: ${name}`);
    }
    for (const entry of entries) entry.enabled = enabled;
    if (this.stateStore) await this.stateStore.set(name, enabled);
    return this.show(name);
  }

  events() {
    return HOOK_EVENTS.map((event) => {
      const entries = this.hooks
        .get(event)
        .slice()
        .sort((left, right) => left.priority - right.priority || left.registrationOrder - right.registrationOrder);
      return {
        event,
        hookCount: entries.length,
        enabledCount: entries.filter((entry) => entry.enabled).length,
        interception: INTERCEPTION_EVENTS.has(event),
        hooks: entries.map((entry) => ({ name: entry.name, enabled: entry.enabled, priority: entry.priority })),
      };
    });
  }

  async runOne(definition, event, context, signal) {
    const startedAt = Date.now();
    let result;
    let error = null;
    let timedOut = false;
    try {
      const safeContext = sanitizeContext(context, definition.permissions);
      const execution = await runWithTimeout(definition.handler, safeContext, definition.timeoutMs, signal);
      timedOut = execution.timedOut;
      result = normalizeResult(execution.value);
      validatePatch(event, result.context_patch);
      validateResultPermissions(definition, event, result);
      if (definition.executionMode === "parallel" && result.status !== "continue") {
        throw new Error("parallel observer hooks may only return continue");
      }
    } catch (caught) {
      timedOut = caught?.timedOut === true;
      error = boundedString(caught instanceof Error ? caught.message : String(caught));
      if (definition.failurePolicy === "fail_task") {
        result = { ...defaultResult(), status: "cancel", reason: `${definition.name} failed: ${error}` };
      } else if (definition.failurePolicy === "fail_operation") {
        result = { ...defaultResult(), status: "block", reason: `${definition.name} failed: ${error}` };
      } else {
        result = {
          ...defaultResult(),
          metadata: definition.failurePolicy === "warn" ? { warnings: [`${definition.name}: ${error}`] } : {},
        };
      }
    }
    const record = {
      hook: definition.name,
      event,
      startedAt: new Date(startedAt).toISOString(),
      durationMs: Date.now() - startedAt,
      resultStatus: result.status,
      failurePolicy: definition.failurePolicy,
      executionMode: definition.executionMode,
      priority: definition.priority,
      taskId: context.taskId ?? context.runId ?? null,
      error,
      timedOut,
      modifiedContext: Object.keys(result.context_patch).length > 0,
      requiredApproval: result.require_approval,
      blocked: result.status === "block",
      cancelled: result.status === "cancel",
    };
    return { definition, result, record };
  }

  async dispatch(event, inputContext = {}, options = {}) {
    await this.initialize();
    if (!EVENT_SET.has(event)) throw new HookConfigurationError(`unknown hook event: ${String(event)}`);
    const parent = this.dispatchStorage.getStore() ?? { depth: 0, stack: [] };
    if (parent.depth >= this.maxDepth) throw new HookOperationError(`maximum hook execution depth exceeded (${this.maxDepth})`);
    if (parent.stack.includes(event)) throw new HookOperationError(`recursive hook event rejected: ${event}`);
    const context = {
      ...cloneJson(inputContext),
      event,
      timestamp: new Date().toISOString(),
    };
    const selected = this.enabled
      ? this.hooks.get(event)
          .filter((entry) => entry.enabled)
          .sort((left, right) => left.priority - right.priority || left.registrationOrder - right.registrationOrder)
      : [];
    const aggregate = {
      ...defaultResult(),
      context,
      executions: [],
    };
    const apply = (execution) => {
      aggregate.executions.push(execution.record);
      if (Object.keys(execution.result.context_patch).length > 0) {
        aggregate.context = mergeRecords(aggregate.context, execution.result.context_patch);
        aggregate.context_patch = mergeRecords(aggregate.context_patch, execution.result.context_patch);
      }
      aggregate.metadata = mergeRecords(aggregate.metadata, execution.result.metadata);
      aggregate.require_approval ||= execution.result.require_approval;
      aggregate.retry ||= execution.result.retry;
      if (RESULT_PRECEDENCE[execution.result.status] > RESULT_PRECEDENCE[aggregate.status]) {
        aggregate.status = execution.result.status;
        aggregate.reason = execution.result.reason;
      } else if (execution.result.reason && !aggregate.reason) aggregate.reason = execution.result.reason;
    };
    await this.dispatchStorage.run({ depth: parent.depth + 1, stack: [...parent.stack, event] }, async () => {
      for (let index = 0; index < selected.length;) {
        const current = selected[index];
        if (current.executionMode === "parallel") {
          const group = [];
          while (index < selected.length && selected[index].executionMode === "parallel" && selected[index].priority === current.priority) {
            group.push(selected[index]);
            index += 1;
          }
          const executions = await runBounded(group, this.maxParallel, (definition) => this.runOne(definition, event, aggregate.context, options.signal));
          for (const execution of executions) apply(execution);
        } else {
          apply(await this.runOne(current, event, aggregate.context, options.signal));
          index += 1;
        }
        if (["block", "cancel", "skip"].includes(aggregate.status)) break;
      }
    });
    aggregate.executions = aggregate.executions.slice(-MAX_EXECUTION_RECORDS);
    this.executionHistory.push(...aggregate.executions);
    this.executionHistory = this.executionHistory.slice(-MAX_EXECUTION_RECORDS);
    if (this.reporter && aggregate.executions.length > 0) {
      try {
        await this.reporter(aggregate.executions);
      } catch (error) {
        const warnings = Array.isArray(aggregate.metadata.warnings) ? aggregate.metadata.warnings : [];
        aggregate.metadata = {
          ...aggregate.metadata,
          warnings: [...warnings, `hook report failed: ${boundedString(error instanceof Error ? error.message : String(error))}`],
        };
      }
    }
    return aggregate;
  }
}

export function parseShellCommand(command) {
  if (typeof command !== "string") return { segments: [], operators: [], valid: false };
  const segments = [];
  const operators = [];
  let current = [];
  let token = "";
  let quote = null;
  let escaped = false;
  const pushToken = () => {
    if (token.length > 0) current.push(token);
    token = "";
  };
  const pushSegment = (operator) => {
    pushToken();
    if (current.length > 0) segments.push({ argv: current });
    current = [];
    if (operator) operators.push(operator);
  };
  for (let index = 0; index < command.length; index += 1) {
    const character = command[index];
    if (escaped) {
      token += character;
      escaped = false;
      continue;
    }
    if (character === "\\" && quote !== "'") {
      escaped = true;
      continue;
    }
    if (quote) {
      if (character === quote) quote = null;
      else token += character;
      continue;
    }
    if (character === "'" || character === '"') {
      quote = character;
      continue;
    }
    if (/\s/u.test(character)) {
      pushToken();
      if (character === "\n") pushSegment(";");
      continue;
    }
    const pair = command.slice(index, index + 2);
    if (["&&", "||"].includes(pair)) {
      pushSegment(pair);
      index += 1;
      continue;
    }
    if ([";", "|"].includes(character)) {
      pushSegment(character);
      continue;
    }
    token += character;
  }
  pushSegment(null);
  return { segments, operators, valid: quote === null && !escaped };
}

function commandExecutable(argv) {
  let index = 0;
  while (index < argv.length && /^[A-Za-z_][A-Za-z0-9_]*=.*/u.test(argv[index])) index += 1;
  return { index, executable: path.basename(argv[index] ?? "") };
}

export function gitOperationsFromCommand(command) {
  const parsed = typeof command === "string" ? parseShellCommand(command) : command;
  const operations = [];
  for (const segment of parsed.segments ?? []) {
    const { index: executableIndex, executable } = commandExecutable(segment.argv);
    if (executable !== "git") continue;
    let index = executableIndex + 1;
    while (index < segment.argv.length) {
      const argument = segment.argv[index];
      if (["-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env"].includes(argument)) {
        index += 2;
        continue;
      }
      if (argument.startsWith("--git-dir=") || argument.startsWith("--work-tree=") || argument.startsWith("--namespace=") || argument.startsWith("--config-env=")) {
        index += 1;
        continue;
      }
      if (argument.startsWith("-")) {
        index += 1;
        continue;
      }
      operations.push({ operation: argument, argv: segment.argv.slice(executableIndex), mutating: !GIT_READ_OPERATIONS.has(argument) });
      break;
    }
  }
  return operations;
}

const GIT_READ_OPERATIONS = new Set([
  "annotate",
  "blame",
  "branch",
  "cat-file",
  "diff",
  "diff-tree",
  "for-each-ref",
  "grep",
  "help",
  "log",
  "ls-files",
  "ls-remote",
  "merge-base",
  "name-rev",
  "rev-list",
  "rev-parse",
  "show",
  "show-ref",
  "status",
  "symbolic-ref",
  "tag",
  "version",
  "whatchanged",
]);

function inspectCommandPolicy(command, home = homedir()) {
  const parsed = parseShellCommand(command);
  if (!parsed.valid) return { status: "block", reason: "command has unterminated quoting or escaping" };
  for (const segment of parsed.segments) {
    const { index, executable } = commandExecutable(segment.argv);
    const args = segment.argv.slice(index + 1);
    if (["shutdown", "reboot", "poweroff"].includes(executable) || executable.startsWith("mkfs")) {
      return { status: "block", reason: `${executable} is blocked by command policy` };
    }
    if (executable === "sudo") return { status: "block", reason: "sudo is blocked inside ZCode task execution" };
    if (executable === "dd") return { status: "block", reason: "dd requires manual execution outside ZCode" };
    if (executable === "kill" && args.includes("-9")) return { status: "block", reason: "kill -9 requires manual execution outside ZCode" };
    if (executable === "chmod" && args.includes("-R") && args.includes("777")) {
      return { status: "block", reason: "recursive world-writable chmod is blocked" };
    }
    if (executable === "chown" && args.includes("-R")) return { status: "block", reason: "recursive chown is blocked" };
    if (executable === "rm") {
      const recursive = args.some((argument) => /^-[^-]*r/iu.test(argument) || ["--recursive", "-rf", "-fr"].includes(argument));
      const force = args.some((argument) => /^-[^-]*f/iu.test(argument) || argument === "--force");
      const targets = args.filter((argument) => !argument.startsWith("-"));
      if (recursive && force && targets.some((target) => ["/", "~", home, `${home}/`].includes(target))) {
        return { status: "block", reason: `recursive forced removal of ${targets.join(", ")} is blocked` };
      }
    }
  }
  return { status: "continue", reason: null };
}

function isProtectedPath(target) {
  const normalized = target.replaceAll("\\", "/");
  const segments = normalized.split("/").filter(Boolean);
  const basename = segments.at(-1) ?? "";
  return (
    basename === ".env" ||
    basename.startsWith(".env.") ||
    basename.endsWith(".pem") ||
    basename.endsWith(".key") ||
    segments.includes("secrets") ||
    segments.includes("credentials") ||
    segments.includes(".git")
  );
}

function insideWorkspace(workspace, target) {
  const resolvedWorkspace = path.resolve(workspace);
  const resolvedTarget = path.resolve(workspace, target);
  const relative = path.relative(resolvedWorkspace, resolvedTarget);
  return relative === "" || (!relative.startsWith("..") && !path.isAbsolute(relative));
}

const BUILTIN_DEFAULTS = Object.freeze({
  "git-baseline": { enabled: true, priority: 20, failurePolicy: "fail_operation" },
  "permission-guard": { enabled: true, priority: 10, failurePolicy: "fail_operation" },
  "protected-paths": { enabled: true, priority: 0, failurePolicy: "fail_operation" },
  "workspace-boundary": { enabled: true, priority: 0, failurePolicy: "fail_operation" },
  "command-policy": { enabled: true, priority: 0, failurePolicy: "fail_operation" },
  "git-safety": { enabled: true, priority: 0, failurePolicy: "fail_operation" },
  "change-tracker": { enabled: true, priority: 40, failurePolicy: "warn" },
  "execution-logger": { enabled: true, priority: 50, failurePolicy: "warn" },
  "execution-metrics": { enabled: true, priority: 60, failurePolicy: "ignore" },
  "final-summary": { enabled: true, priority: 100, failurePolicy: "warn" },
  "approval-recorder": { enabled: true, priority: -50, failurePolicy: "fail_operation" },
});
export const BUILT_IN_HOOKS = Object.freeze(Object.keys(BUILTIN_DEFAULTS));

function builtinOptions(configuration, name, extra = {}) {
  const override = configuration?.builtins?.[name] ?? {};
  return { ...BUILTIN_DEFAULTS[name], ...override, ...extra };
}

function registerForEvents(manager, name, events, base) {
  for (const event of events) manager.register({ name, event, ...base });
}

export function registerBuiltInHooks(manager, services = {}, configuration = {}) {
  if (services.approvals) {
    manager.register({
      name: "approval-recorder",
      event: "before_task",
      ...builtinOptions(configuration, "approval-recorder"),
      mandatory: true,
      category: "approval",
      description: "Record exact one-time approval phrases submitted through ZCode.",
      permissions: ["read_task_context", "modify_task_context"],
      handler: async (context) => {
        const prompt = context.task?.text ?? "";
        if (typeof prompt !== "string" || !/^APPROVE (RUN|GIT|ROLLBACK) [A-F0-9]{12}$/u.test(prompt.trim())) {
          return defaultResult();
        }
        const recorded = await services.approvals.recordPrompt(prompt);
        const additionalContext =
          `Recorded one-time ${recorded.kind} approval token ${recorded.token}. ` +
          "The orchestrator may now consume it exactly once.";
        return {
          ...defaultResult(),
          status: "modify",
          reason: additionalContext,
          context_patch: { task: { additionalContext } },
        };
      },
    });
  }
  manager.register({
    name: "git-baseline",
    event: "before_task",
    ...builtinOptions(configuration, "git-baseline"),
    mandatory: true,
    category: "git-protection",
    description: "Capture immutable repository state before task execution.",
    permissions: ["read_task_context", "read_git_state", "modify_task_context", "block_operation"],
    handler: async (context) => {
      if (!services.gitTracker || typeof context.task?.workspace !== "string") return defaultResult();
      const baseline = await services.gitTracker.snapshot(context.task.workspace);
      return { ...defaultResult(), status: "modify", context_patch: { gitBaseline: baseline } };
    },
  });

  registerForEvents(manager, "permission-guard", ["before_agent", "before_tool_call"], {
    ...builtinOptions(configuration, "permission-guard"),
    mandatory: true,
    category: "permission",
    description: "Validate agent capabilities and disallowed tools before execution.",
    permissions: ["read_agent_context", "read_tool_metadata", "block_operation"],
    handler: async (context) => {
      if (context.agent?.allowed === false) return { ...defaultResult(), status: "block", reason: "agent capability is not allowed" };
      if (context.tool?.name && Array.isArray(context.agent?.disallowedTools) && context.agent.disallowedTools.includes(context.tool.name)) {
        return { ...defaultResult(), status: "block", reason: `tool is denied for this agent: ${context.tool.name}` };
      }
      return defaultResult();
    },
  });

  registerForEvents(manager, "protected-paths", ["before_file_write", "before_file_delete"], {
    ...builtinOptions(configuration, "protected-paths"),
    mandatory: true,
    category: "security",
    description: "Require explicit approval before protected files can change.",
    permissions: ["read_file_metadata", "request_approval", "block_operation"],
    handler: async (context) => {
      if (!context.file?.path || !isProtectedPath(context.file.path)) return defaultResult();
      if (context.file.explicitlyApproved === true) return defaultResult();
      return {
        ...defaultResult(),
        status: "block",
        reason: `protected path requires explicit user approval: ${context.file.path}`,
        require_approval: true,
        metadata: { risk: "protected-path" },
      };
    },
  });

  registerForEvents(manager, "workspace-boundary", ["before_file_read", "before_file_write", "before_file_delete", "before_command"], {
    ...builtinOptions(configuration, "workspace-boundary"),
    mandatory: true,
    category: "security",
    description: "Reject file and command access outside the active workspace.",
    permissions: ["read_file_metadata", "read_command", "block_operation"],
    handler: async (context) => {
      const workspace = context.file?.workspace ?? context.command?.workspace;
      const target = context.file?.path ?? context.command?.cwd;
      if (!workspace || !target || insideWorkspace(workspace, target)) return defaultResult();
      return { ...defaultResult(), status: "block", reason: `operation escapes workspace boundary: ${target}` };
    },
  });

  manager.register({
    name: "command-policy",
    event: "before_command",
    ...builtinOptions(configuration, "command-policy"),
    mandatory: true,
    category: "security",
    description: "Parse shell structure and block dangerous commands.",
    permissions: ["read_command", "block_operation", "request_approval"],
    handler: async (context) => {
      const decision = inspectCommandPolicy(context.command?.raw ?? "", services.home ?? homedir());
      return decision.status === "continue" ? defaultResult() : { ...defaultResult(), ...decision };
    },
  });

  manager.register({
    name: "git-safety",
    event: "before_git_operation",
    ...builtinOptions(configuration, "git-safety"),
    mandatory: true,
    category: "git-protection",
    description: "Require approval for Git writes and block destructive history operations.",
    permissions: ["read_git_state", "block_operation", "request_approval"],
    handler: async (context) => {
      const operation = context.git?.operation ?? "";
      const args = context.git?.arguments ?? [];
      const destructive =
        (operation === "reset" && args.includes("--hard")) ||
        (operation === "clean" && args.some((argument) => /^-[^-]*f/iu.test(argument))) ||
        (operation === "push" && args.some((argument) => ["--force", "--force-with-lease", "-f"].includes(argument)));
      if (destructive) return { ...defaultResult(), status: "block", reason: `destructive Git operation is blocked: git ${operation}` };
      if (context.git?.mutating && context.git?.approved !== true) {
        return {
          ...defaultResult(),
          status: "block",
          reason: `Git write requires explicit user approval: git ${operation}`,
          require_approval: true,
        };
      }
      return defaultResult();
    },
  });

  registerForEvents(manager, "change-tracker", ["after_agent", "after_file_write", "after_file_delete"], {
    ...builtinOptions(configuration, "change-tracker"),
    category: "validation",
    description: "Record task-owned workspace changes without duplicating GitTracker state logic.",
    permissions: ["read_task_context", "read_agent_context", "read_file_metadata", "read_git_state"],
    handler: async (context) => ({
      ...defaultResult(),
      metadata: {
        changedPaths: context.agent?.detectedChanges ?? (context.file?.path ? [context.file.path] : []),
      },
    }),
  });

  const interceptionEvents = HOOK_EVENTS.filter((event) => INTERCEPTION_EVENTS.has(event));
  const observationEvents = HOOK_EVENTS.filter((event) => !INTERCEPTION_EVENTS.has(event));
  for (const [name, category, description] of [
    ["execution-logger", "logging", "Record sanitized lifecycle and hook execution metadata."],
    ["execution-metrics", "metrics", "Measure task, agent, tool, retry, and hook durations."],
  ]) {
    const options = {
      ...builtinOptions(configuration, name),
      category,
      description,
      permissions: ["write_logs"],
      handler: async () => defaultResult(),
    };
    registerForEvents(manager, name, interceptionEvents, options);
    registerForEvents(manager, name, observationEvents, { ...options, executionMode: "parallel" });
  }

  manager.register({
    name: "final-summary",
    event: "after_task",
    ...builtinOptions(configuration, "final-summary"),
    category: "cleanup",
    description: "Produce a bounded final lifecycle summary.",
    permissions: ["read_task_context", "write_logs"],
    handler: async (context) => ({
      ...defaultResult(),
      metadata: {
        finalSummary: {
          status: context.task?.status ?? "unknown",
          completedUnits: context.task?.completedUnits ?? 0,
          failedUnits: context.task?.failedUnits ?? 0,
        },
      },
    }),
  });
}

function validateBuiltInOverrides(value) {
  if (value === undefined) return {};
  if (!isRecord(value)) throw new HookConfigurationError("hooks.builtins must be an object");
  for (const [name, override] of Object.entries(value)) {
    if (!(name in BUILTIN_DEFAULTS)) throw new HookConfigurationError(`unknown built-in hook: ${name}`);
    if (!isRecord(override)) throw new HookConfigurationError(`built-in hook override must be an object: ${name}`);
    assertOnlyKeys(override, new Set(["enabled", "priority", "failurePolicy", "timeoutMs"]), `${name} override`);
    if (override.enabled !== undefined && typeof override.enabled !== "boolean") throw new HookConfigurationError(`${name}.enabled must be a boolean`);
    if (override.failurePolicy !== undefined && !FAILURE_POLICY_SET.has(override.failurePolicy)) {
      throw new HookConfigurationError(`${name}.failurePolicy is invalid`);
    }
  }
  return cloneJson(value);
}

export function validateHookConfiguration(value) {
  const configuration = value ?? {};
  if (!isRecord(configuration)) throw new HookConfigurationError("hook configuration must be an object");
  assertOnlyKeys(
    configuration,
    new Set(["version", "enabled", "maxDepth", "maxParallel", "unsafeAllowDisableMandatory", "builtins", "events"]),
    "hook configuration",
  );
  if (configuration.version !== undefined && configuration.version !== HOOK_RUNTIME_VERSION) {
    throw new HookConfigurationError(`unsupported hook configuration version: ${String(configuration.version)}`);
  }
  if (configuration.enabled !== undefined && typeof configuration.enabled !== "boolean") {
    throw new HookConfigurationError("hooks.enabled must be a boolean");
  }
  if (configuration.unsafeAllowDisableMandatory !== undefined && typeof configuration.unsafeAllowDisableMandatory !== "boolean") {
    throw new HookConfigurationError("hooks.unsafeAllowDisableMandatory must be a boolean");
  }
  const events = configuration.events ?? {};
  if (!isRecord(events)) throw new HookConfigurationError("hooks.events must be an object");
  for (const [event, entries] of Object.entries(events)) {
    if (!EVENT_SET.has(event)) throw new HookConfigurationError(`unknown configured hook event: ${event}`);
    if (!Array.isArray(entries)) throw new HookConfigurationError(`configured hooks for ${event} must be an array`);
    for (const entry of entries) {
      if (!isRecord(entry)) throw new HookConfigurationError(`configured hook for ${event} must be an object`);
      assertOnlyKeys(
        entry,
        new Set(["name", "command", "args", "enabled", "priority", "executionMode", "timeoutMs", "failurePolicy", "permissions", "description"]),
        `configured hook for ${event}`,
      );
      if (typeof entry.command !== "string" || !path.isAbsolute(entry.command)) {
        throw new HookConfigurationError(`${entry.name ?? event}.command must be an absolute executable path`);
      }
      if (entry.args !== undefined && (!Array.isArray(entry.args) || entry.args.some((argument) => typeof argument !== "string"))) {
        throw new HookConfigurationError(`${entry.name ?? event}.args must contain strings`);
      }
    }
  }
  const unsafeAllowDisableMandatory = configuration.unsafeAllowDisableMandatory === true;
  const builtins = validateBuiltInOverrides(configuration.builtins);
  if (!unsafeAllowDisableMandatory) {
    for (const name of MANDATORY_BUILTINS) {
      if (builtins[name]?.enabled === false) {
        throw new HookConfigurationError(`mandatory hook cannot be disabled: ${name}`);
      }
    }
    if (configuration.enabled === false) {
      throw new HookConfigurationError("disabling all hooks requires unsafeAllowDisableMandatory");
    }
  }
  return {
    version: HOOK_RUNTIME_VERSION,
    enabled: configuration.enabled ?? true,
    maxDepth: normalizeInteger(configuration.maxDepth, 4, 1, 16, "hooks.maxDepth"),
    maxParallel: normalizeInteger(configuration.maxParallel, 4, 1, 32, "hooks.maxParallel"),
    unsafeAllowDisableMandatory,
    builtins,
    events: cloneJson(events),
  };
}

export async function loadHookConfiguration(configPath) {
  if (!configPath) return validateHookConfiguration({});
  try {
    return validateHookConfiguration(JSON.parse(await readFile(configPath, "utf8")));
  } catch (error) {
    if (error instanceof SyntaxError) throw new HookConfigurationError(`invalid hook configuration JSON at ${configPath}: ${error.message}`);
    throw error;
  }
}

function selectEnvironment() {
  return Object.fromEntries(SAFE_ENVIRONMENT_NAMES.flatMap((name) => typeof process.env[name] === "string" ? [[name, process.env[name]]] : []));
}

function commandHookHandler(entry) {
  return async (context, { signal }) => {
    const child = spawn(entry.command, entry.args ?? [], {
      env: selectEnvironment(),
      stdio: ["pipe", "pipe", "pipe"],
      detached: process.platform !== "win32",
    });
    const stdout = [];
    const stderr = [];
    let stdoutSize = 0;
    let stderrSize = 0;
    const maximum = 1024 * 1024;
    child.stdout.on("data", (chunk) => {
      stdoutSize += chunk.length;
      if (stdoutSize <= maximum) stdout.push(chunk);
    });
    child.stderr.on("data", (chunk) => {
      stderrSize += chunk.length;
      if (stderrSize <= maximum) stderr.push(chunk);
    });
    child.stdin.end(`${JSON.stringify(context)}\n`);
    const abort = () => {
      if (child.exitCode !== null) return;
      if (child.pid && process.platform !== "win32") {
        try { process.kill(-child.pid, "SIGTERM"); } catch {}
      } else child.kill("SIGTERM");
    };
    if (signal.aborted) abort();
    else signal.addEventListener("abort", abort, { once: true });
    const result = await new Promise((resolve, reject) => {
      child.once("error", reject);
      child.once("close", (code) => resolve(code));
    });
    signal.removeEventListener("abort", abort);
    if (stdoutSize > maximum || stderrSize > maximum) throw new Error("external hook output exceeded 1 MiB");
    if (result !== 0) throw new Error(`external hook exited with code ${result}: ${boundedString(Buffer.concat(stderr).toString("utf8"))}`);
    const text = Buffer.concat(stdout).toString("utf8").trim();
    return text ? JSON.parse(text) : defaultResult();
  };
}

export async function appendHookExecutionReport(reportFile, records) {
  if (!reportFile || records.length === 0) return;
  await mkdir(path.dirname(reportFile), { recursive: true, mode: 0o700 });
  const rotatedReport = `${reportFile}.1`;
  try {
    if ((await stat(reportFile)).size >= MAX_REPORT_BYTES) {
      await rm(rotatedReport, { force: true });
      await rename(reportFile, rotatedReport).catch((error) => {
        if (error?.code !== "ENOENT") throw error;
      });
      await chmod(rotatedReport, 0o600).catch(() => {});
    }
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
  }
  const lines = records.map((record) => JSON.stringify(redactSensitive(record))).join("\n");
  await appendFile(reportFile, `${lines}\n`, { mode: 0o600 });
  await chmod(reportFile, 0o600).catch(() => {});
}

export async function createHookManager(options = {}) {
  const configuration = options.configuration ?? await loadHookConfiguration(options.configPath);
  const stateDir = options.stateDir ?? path.join(homedir(), ".cache", "zcode-orchestrator");
  const manager = new HookManager({
    ...configuration,
    stateStore: options.stateStore ?? new HookStateStore(stateDir),
    reporter: options.reporter ?? (options.reportFile ? (records) => appendHookExecutionReport(options.reportFile, records) : null),
  });
  registerBuiltInHooks(manager, options.services ?? {}, configuration);
  for (const [event, entries] of Object.entries(configuration.events)) {
    for (const entry of entries) {
      const { command: _command, args: _args, ...definition } = entry;
      manager.register({
        ...definition,
        event,
        handler: commandHookHandler(entry),
      });
    }
  }
  await manager.initialize();
  return manager;
}

function fileEventForTool(toolName, phase) {
  const normalized = String(toolName).toLowerCase();
  if (["read", "glob", "grep"].includes(normalized)) return `${phase}_file_read`;
  if (["write", "edit", "notebookedit"].includes(normalized)) return `${phase}_file_write`;
  if (["delete", "remove"].includes(normalized)) return `${phase}_file_delete`;
  return null;
}

function nativeToolContext(input, environment) {
  const tool = input.tool_input ?? input.toolInput ?? {};
  const workspace = environment.ZCODE_ORCHESTRATOR_WORKSPACE ?? input.cwd ?? process.cwd();
  const filePath = tool.file_path ?? tool.path ?? tool.notebook_path ?? null;
  const rawCommand = typeof tool.command === "string" ? tool.command : "";
  return {
    runId: environment.ZCODE_ORCHESTRATOR_RUN_ID ?? input.session_id ?? input.sessionId ?? null,
    unitId: environment.ZCODE_ORCHESTRATOR_UNIT_ID ?? null,
    taskId: environment.ZCODE_ORCHESTRATOR_RUN_ID ?? input.session_id ?? input.sessionId ?? null,
    agent: {
      role: environment.ZCODE_ORCHESTRATOR_ROLE ?? "primary",
      disallowedTools: [],
      allowed: true,
    },
    tool: {
      name: input.tool_name ?? input.toolName ?? "",
      arguments: redactSensitive(cloneJson(tool)),
      durationMs: input.duration_ms ?? input.durationMs ?? null,
      exitStatus: input.tool_response?.exit_code ?? input.toolResponse?.exitCode ?? null,
      resultMetadata: redactSensitive(cloneJson(input.tool_response?.metadata ?? input.toolResponse?.metadata ?? {})),
    },
    file: filePath ? {
      path: filePath,
      workspace,
      proposedChange: {
        hasContent: typeof tool.content === "string" || typeof tool.new_string === "string",
        contentBytes: typeof tool.content === "string" ? Buffer.byteLength(tool.content) : null,
      },
      explicitlyApproved: false,
    } : null,
    command: rawCommand ? {
      raw: rawCommand,
      parsed: parseShellCommand(rawCommand),
      cwd: tool.cwd ?? workspace,
      workspace,
      environmentMetadata: { suppliedNames: Object.keys(tool.env ?? {}).filter((name) => !SENSITIVE_KEY.test(name)) },
    } : null,
    error: input.error ? { type: "tool", source: "zcode", message: boundedString(input.error), recoverable: false } : null,
  };
}

function mergeDispatchResults(results) {
  const aggregate = { ...defaultResult(), context: {}, executions: [] };
  for (const result of results) {
    aggregate.context = mergeRecords(aggregate.context, result.context ?? {});
    aggregate.context_patch = mergeRecords(aggregate.context_patch, result.context_patch ?? {});
    aggregate.metadata = mergeRecords(aggregate.metadata, result.metadata ?? {});
    aggregate.require_approval ||= result.require_approval;
    aggregate.retry ||= result.retry;
    aggregate.executions.push(...(result.executions ?? []));
    if (RESULT_PRECEDENCE[result.status] > RESULT_PRECEDENCE[aggregate.status]) {
      aggregate.status = result.status;
      aggregate.reason = result.reason;
    }
  }
  return aggregate;
}

export async function dispatchNativeZCodeHook(manager, input, environment = process.env) {
  const nativeEvent = input.hook_event_name ?? input.hookEventName ?? "";
  const context = nativeToolContext(input, environment);
  const results = [];
  const dispatch = async (event, extension = {}) => {
    const result = await manager.dispatch(event, mergeRecords(context, extension));
    results.push(result);
    return result;
  };
  if (nativeEvent === "UserPromptSubmit") {
    await dispatch("before_task", {
      task: { text: input.prompt ?? input.user_prompt ?? "", workspace: input.cwd ?? process.cwd(), status: "running" },
    });
  } else if (nativeEvent === "PreToolUse") {
    await dispatch("before_tool_call");
    const fileEvent = fileEventForTool(context.tool.name, "before");
    if (fileEvent && context.file) await dispatch(fileEvent);
    if (context.command) {
      await dispatch("before_command");
      for (const git of gitOperationsFromCommand(context.command.raw)) {
        await dispatch("before_git_operation", { git: { ...git, repository: context.command.cwd, approved: false } });
      }
    }
  } else if (nativeEvent === "PostToolUse" || nativeEvent === "PostToolUseFailure") {
    const successful = nativeEvent === "PostToolUse";
    const commandTimedOut =
      !successful &&
      (
        input.tool_response?.timed_out === true ||
        input.toolResponse?.timedOut === true ||
        input.error?.timedOut === true ||
        (typeof input.error === "string" && /timed?\s*out|timeout/iu.test(input.error))
      );
    if (context.command) {
      await dispatch(successful ? "on_command_success" : commandTimedOut ? "on_command_timeout" : "on_command_failure");
      await dispatch("after_command");
      for (const git of gitOperationsFromCommand(context.command.raw)) {
        await dispatch(successful ? "on_git_success" : "on_git_failure", { git: { ...git, repository: context.command.cwd } });
        await dispatch("after_git_operation", { git: { ...git, repository: context.command.cwd } });
      }
    }
    const fileEvent = fileEventForTool(context.tool.name, "after");
    if (fileEvent && successful && context.file) await dispatch(fileEvent);
    await dispatch(successful ? "on_tool_success" : "on_tool_failure");
    await dispatch("after_tool_call");
    if (!successful) await dispatch("on_error");
  } else if (nativeEvent === "PermissionRequest") {
    const approval = { operation: context.tool.name, risk: "tool-permission", userControlled: true };
    const permission = await dispatch("before_approval_request", { approval });
    if (["block", "cancel", "skip"].includes(permission.status)) {
      await dispatch("after_approval_denied", { approval: { ...approval, reason: permission.reason } });
    }
  } else if (nativeEvent === "Stop") {
    await dispatch("on_task_success", { task: { status: "completed", workspace: input.cwd ?? process.cwd() } });
    await dispatch("after_task", { task: { status: "completed", workspace: input.cwd ?? process.cwd() } });
  }
  return mergeDispatchResults(results);
}

export function zcodeHookProtocolResult(nativeEvent, result) {
  if (nativeEvent === "PreToolUse") {
    const decision = result.status === "cancel" || result.status === "block" || result.status === "skip"
      ? "deny"
      : result.require_approval ? "ask" : "allow";
    const fields = {
      hookEventName: "PreToolUse",
      permissionDecision: decision,
      permissionDecisionReason: result.reason ?? `Central hook runtime decision: ${result.status}`,
    };
    const updatedArguments = result.context?.tool?.arguments;
    if (result.status === "modify" && isRecord(updatedArguments)) fields.updatedInput = updatedArguments;
    return { hookSpecificOutput: fields };
  }
  if (nativeEvent === "PermissionRequest") {
    const behavior = result.status === "block" || result.status === "cancel" ? "deny" : result.require_approval ? undefined : "allow";
    if (!behavior) return {};
    return {
      hookSpecificOutput: {
        hookEventName: "PermissionRequest",
        decision: { behavior, message: result.reason ?? `Central hook runtime decision: ${result.status}` },
      },
    };
  }
  if (nativeEvent === "UserPromptSubmit" && result.status === "modify") {
    return {
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext:
          result.context?.task?.additionalContext ??
          result.reason ??
          "Central task hooks enriched the task context before execution.",
      },
    };
  }
  return {};
}
