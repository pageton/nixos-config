#!/usr/bin/env node

import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { promisify } from "node:util";
import test from "node:test";
import {
  ApprovalStore,
  GitTracker,
  Orchestrator,
  ProcessRunner,
  WorkspaceWriterLock,
  ZCodeAgentRunner,
  buildExecutionPlan,
  classifyTask,
  createRuntimeConfig,
  isTransientAgentError,
  extractJsonObject,
  normalizeAgentResult,
  parsePorcelainStatus,
  validateExecutionPlan,
} from "./zcode-orchestrator-core.mjs";

const executeFile = promisify(execFile);
const serverScript = new URL("./zcode-orchestrator.mjs", import.meta.url).pathname;
const temporaryDirectories = [];

async function temporaryDirectory(prefix) {
  const directory = await mkdtemp(path.join(tmpdir(), prefix));
  temporaryDirectories.push(directory);
  return directory;
}

async function command(commandName, args, options = {}) {
  return executeFile(commandName, args, {
    cwd: options.cwd,
    env: options.env,
    encoding: "utf8",
    maxBuffer: 8 * 1024 * 1024,
  });
}

async function git(repository, ...args) {
  return command("git", ["-C", repository, ...args]);
}

async function initializeRepository() {
  const repository = await temporaryDirectory("zcode-orchestrator-repo-");
  await git(repository, "init", "-q");
  await git(repository, "config", "user.name", "ZCode Test");
  await git(repository, "config", "user.email", "zcode-test@example.invalid");
  await git(repository, "config", "core.hooksPath", "/dev/null");
  await writeFile(path.join(repository, "baseline.txt"), "baseline\n");
  await git(repository, "add", "baseline.txt");
  await git(repository, "-c", "commit.gpgsign=false", "commit", "-q", "-m", "test: initialize repository");
  return repository;
}

function completedResult(summary = "completed") {
  return {
    status: "completed",
    summary,
    findings: [],
    changes: [],
    commands: [],
    blockers: [],
    nextActions: [],
    schemaValid: true,
  };
}

function testConfig(stateDir, overrides = {}) {
  return {
    ...createRuntimeConfig({
      HOME: process.env.HOME,
      PATH: process.env.PATH,
      ZCODE_ORCHESTRATOR_STATE_DIR: stateDir,
      ZCODE_ORCHESTRATOR_MAX_READERS: "4",
      ZCODE_ORCHESTRATOR_MAX_RUNS: "2",
      ZCODE_ORCHESTRATOR_AGENT_TIMEOUT_MS: "10000",
      ZCODE_ORCHESTRATOR_RUN_TIMEOUT_MS: "30000",
    }),
    ...overrides,
  };
}

async function waitForTerminal(orchestrator, runId) {
  let run = await orchestrator.get(runId, 30_000);
  for (let attempt = 0; !["completed", "partial", "blocked", "failed", "cancelled"].includes(run.status); attempt += 1) {
    assert.ok(attempt < 100, `run ${runId} did not terminate`);
    await new Promise((resolve) => setTimeout(resolve, 10));
    run = await orchestrator.get(runId, 100);
  }
  return run;
}

process.on("exit", () => {
  for (const directory of temporaryDirectories) {
    try {
      process.getBuiltinModule("node:fs").rmSync(directory, { recursive: true, force: true });
    } catch {
      // Best-effort test cleanup.
    }
  }
});

test("task classification selects relevant roles without enabling every specialist", () => {
  const feature = classifyTask("Implement a documented authentication fix and verify it");
  assert.equal(feature.mutating, true);
  assert.equal(feature.security, true);
  assert.equal(feature.documentation, true);
  assert.deepEqual(feature.roles, [
    "explorer",
    "debug",
    "security",
    "implementation",
    "test",
    "documentation",
    "code-review",
  ]);
  assert.equal(feature.risk, "high");

  const explanation = classifyTask("Explain how configuration loading works");
  assert.deepEqual(explanation.roles, ["explorer"]);
  assert.equal(explanation.risk, "low");

  const readOnlyDocumentation = classifyTask(
    "Read README.txt and report its content. Do not modify files.",
  );
  assert.deepEqual(readOnlyDocumentation.roles, ["explorer"]);
  assert.equal(readOnlyDocumentation.mutating, false);
  assert.equal(readOnlyDocumentation.documentation, false);

  const performance = classifyTask("Profile request latency", { forcePerformance: true });
  assert.ok(performance.roles.includes("performance"));
  assert.ok(!performance.roles.includes("implementation"));

  const secureFeature = classifyTask("Implement a secure feature");
  assert.equal(secureFeature.security, true);
  assert.ok(secureFeature.roles.includes("security"));
  assert.equal(isTransientAgentError("getaddrinfo EAI_AGAIN api.z.ai"), true);
  assert.equal(isTransientAgentError("401 invalid API key"), false);
});

test("execution plans serialize writers behind analysis and end with review", () => {
  const plan = buildExecutionPlan(
    classifyTask("Implement and document a security fix with tests"),
  );
  const byRole = new Map(plan.units.map((unit) => [unit.role, unit]));
  assert.deepEqual(byRole.get("implementation").dependencies.sort(), [
    "debug-1",
    "explorer-1",
    "security-1",
  ]);
  assert.deepEqual(byRole.get("test").dependencies, ["implementation-1"]);
  assert.deepEqual(byRole.get("documentation").dependencies, ["test-1"]);
  assert.deepEqual(byRole.get("code-review").dependencies, ["documentation-1"]);
  assert.equal(validateExecutionPlan(plan.units), true);
  assert.throws(
    () =>
      validateExecutionPlan([
        { id: "explorer-1", role: "explorer", dependencies: ["debug-1"] },
        { id: "debug-1", role: "debug", dependencies: ["explorer-1"] },
      ]),
    /cyclic execution plan/u,
  );
});

test("structured result parsing is bounded and fails closed", () => {
  assert.deepEqual(extractJsonObject('diagnostic\n{"status":"completed"}\ntrailer'), {
    status: "completed",
  });
  const invalid = normalizeAgentResult("not an object", { raw: "unstructured response" });
  assert.equal(invalid.status, "partial");
  assert.equal(invalid.schemaValid, false);
  assert.match(invalid.blockers[0], /invalid structured/u);

  const valid = normalizeAgentResult({
    status: "completed",
    summary: "ok",
    findings: [],
    changes: [],
    commands: [],
    blockers: [],
    nextActions: [],
  });
  assert.equal(valid.status, "completed");
  assert.equal(valid.schemaValid, true);

  const malformedNestedItem = normalizeAgentResult(
    {
      status: "completed",
      summary: "claims success while dropping malformed findings",
      findings: ["not a finding object"],
      changes: [],
      commands: [],
      blockers: [],
      nextActions: [],
    },
    { raw: "malformed nested result" },
  );
  assert.equal(malformedNestedItem.status, "partial");
  assert.equal(malformedNestedItem.schemaValid, false);

  const inconsistentCompletion = normalizeAgentResult({
    status: "completed",
    summary: "claims success with a blocker",
    findings: [],
    changes: [],
    commands: [],
    blockers: ["still blocked"],
    nextActions: [],
  });
  assert.equal(inconsistentCompletion.status, "partial");
  assert.equal(inconsistentCompletion.schemaValid, false);
});

test("porcelain status parser preserves staged, unstaged, untracked, and renamed paths", () => {
  const parsed = parsePorcelainStatus(
    "M  staged.txt\0 M unstaged.txt\0?? untracked.txt\0R  renamed.txt\0old.txt\0",
  );
  assert.deepEqual(parsed.dirtyPaths, [
    "old.txt",
    "renamed.txt",
    "staged.txt",
    "unstaged.txt",
    "untracked.txt",
  ]);
  assert.deepEqual(parsed.stagedPaths, ["old.txt", "renamed.txt", "staged.txt"]);
  assert.deepEqual(parsed.unstagedPaths, ["unstaged.txt", "untracked.txt"]);
});

test("workspace writer lock never permits concurrent writers", async () => {
  const lock = new WorkspaceWriterLock();
  let active = 0;
  let maximum = 0;
  const operations = Array.from({ length: 8 }, (_, index) =>
    lock.withLock("/workspace", async () => {
      active += 1;
      maximum = Math.max(maximum, active);
      await new Promise((resolve) => setTimeout(resolve, 5 + (index % 2)));
      active -= 1;
      return index;
    }),
  );
  assert.deepEqual(await Promise.all(operations), [0, 1, 2, 3, 4, 5, 6, 7]);
  assert.equal(maximum, 1);
  assert.equal(lock.activeCount("/workspace"), 0);
});

test("process cancellation terminates the complete descendant process group", async () => {
  const directory = await temporaryDirectory("zcode-orchestrator-process-group-");
  const marker = path.join(directory, "descendant-survived");
  const descendant = [
    "const { writeFileSync } = require('node:fs');",
    `setTimeout(() => writeFileSync(${JSON.stringify(marker)}, 'survived'), 300);`,
    "setInterval(() => {}, 1000);",
  ].join("");
  const parent = [
    "const { spawn } = require('node:child_process');",
    `spawn(process.execPath, ['-e', ${JSON.stringify(descendant)}], { stdio: 'ignore' });`,
    "setInterval(() => {}, 1000);",
  ].join("");
  const controller = new AbortController();
  const pending = new ProcessRunner().run(process.execPath, ["-e", parent], {
    signal: controller.signal,
    timeoutMs: 5_000,
  });
  setTimeout(() => controller.abort(new Error("test cancellation")), 50);
  const result = await pending;
  assert.equal(result.aborted, true);
  await new Promise((resolve) => setTimeout(resolve, 400));
  await assert.rejects(() => readFile(marker), { code: "ENOENT" });
});

test("approval tokens require an exact prompt and are single-use", async () => {
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-approval-");
  const approvals = new ApprovalStore(stateDirectory);
  const approval = await approvals.create("RUN", { runId: "run_example" });
  assert.equal(await approvals.recordPrompt(`please ${approval.phrase}`), null);
  await approvals.recordPrompt(approval.phrase);
  assert.deepEqual(await approvals.consume(approval.token, "RUN"), { runId: "run_example" });
  await assert.rejects(() => approvals.consume(approval.token, "RUN"), /already consumed/u);

  const concurrent = await approvals.create("GIT", { runId: "run_concurrent" });
  await approvals.recordPrompt(concurrent.phrase);
  const attempts = await Promise.allSettled([
    approvals.consume(concurrent.token, "GIT"),
    approvals.consume(concurrent.token, "GIT"),
  ]);
  assert.equal(attempts.filter((attempt) => attempt.status === "fulfilled").length, 1);
  assert.equal(attempts.filter((attempt) => attempt.status === "rejected").length, 1);
});

test("agent gate denies Git mutations and strips provider credentials from safe Bash", async () => {
  const denied = await new ProcessRunner().run(process.execPath, [serverScript, "--agent-gate"], {
    stdin: "not-json",
    timeoutMs: 5_000,
  });
  assert.equal(denied.code, 2, "invalid hook input must fail closed");

  const mutation = await new ProcessRunner().run(process.execPath, [serverScript, "--agent-gate"], {
    stdin: JSON.stringify({ tool_name: "Bash", tool_input: { command: "git commit -m unsafe" } }),
    timeoutMs: 5_000,
  });
  assert.equal(mutation.code, 2);
  const mutationOutput = JSON.parse(mutation.stdout);
  assert.equal(mutationOutput.hookSpecificOutput.permissionDecision, "deny");

  const optionMutation = await new ProcessRunner().run(process.execPath, [serverScript, "--agent-gate"], {
    stdin: JSON.stringify({ tool_name: "Bash", tool_input: { command: "git -C . add feature.txt" } }),
    timeoutMs: 5_000,
  });
  assert.equal(optionMutation.code, 2);
  assert.equal(JSON.parse(optionMutation.stdout).hookSpecificOutput.permissionDecision, "deny");

  const safe = await new ProcessRunner().run(process.execPath, [serverScript, "--agent-gate"], {
    stdin: JSON.stringify({ tool_name: "Bash", tool_input: { command: "printf safe" } }),
    timeoutMs: 5_000,
  });
  assert.equal(safe.code, 0);
  const safeOutput = JSON.parse(safe.stdout);
  assert.equal(safeOutput.hookSpecificOutput.permissionDecision, "allow");
  assert.match(safeOutput.hookSpecificOutput.updatedInput.command, /^unset ANTHROPIC_API_KEY/u);
  assert.match(safeOutput.hookSpecificOutput.updatedInput.command, /printf safe$/u);
});

test("writer sandbox remounts protected baseline files read-only", async () => {
  const repository = await initializeRepository();
  const protectedFile = path.join(repository, "baseline.txt");
  await writeFile(protectedFile, "pre-existing user change\n");
  const tracker = new GitTracker();
  const baseline = await tracker.snapshot(repository);
  const agentHome = await temporaryDirectory("zcode-orchestrator-sandbox-home-");
  const bwrap = (await executeFile("which", ["bwrap"])).stdout.trim();
  const runner = new ZCodeAgentRunner({
    bwrap,
    zcodeCli: process.execPath,
  });
  const script = [
    "const { readFileSync, writeFileSync } = require('node:fs');",
    "if (readFileSync('/etc/resolv.conf', 'utf8').trim().length === 0) process.exit(3);",
    `try { writeFileSync(${JSON.stringify(protectedFile)}, 'overwritten'); process.exit(2); }`,
    "catch (error) { if (!['EACCES', 'EPERM', 'EROFS'].includes(error.code)) throw error; }",
    `writeFileSync(${JSON.stringify(path.join(repository, "feature.txt"))}, 'task-owned\\n');`,
  ].join("");
  const sandboxArguments = await runner.sandboxArguments(
    repository,
    agentHome,
    { kind: "writer" },
    baseline,
    ["-e", script],
  );
  const execution = await new ProcessRunner().run(bwrap, sandboxArguments, {
    timeoutMs: 5_000,
  });
  assert.equal(execution.code, 0, execution.stderr);
  assert.equal(await readFile(protectedFile, "utf8"), "pre-existing user change\n");
  assert.equal(await readFile(path.join(repository, "feature.txt"), "utf8"), "task-owned\n");
});

test("writer sandbox fails closed when a protected path disappears before launch", async () => {
  const repository = await initializeRepository();
  const protectedFile = path.join(repository, "protected.txt");
  await writeFile(protectedFile, "pre-existing user change\n");
  const tracker = new GitTracker();
  const baseline = await tracker.snapshot(repository);
  await rm(protectedFile);
  const runner = new ZCodeAgentRunner({
    bwrap: process.execPath,
    zcodeCli: process.execPath,
  });
  const agentHome = await temporaryDirectory("zcode-orchestrator-missing-path-home-");
  await assert.rejects(
    () =>
      runner.sandboxArguments(
        repository,
        agentHome,
        { kind: "writer" },
        baseline,
        ["-e", ""],
      ),
    /protected path disappeared/u,
  );
});

test("agent runner redacts provider credentials from structured output and diagnostics", async () => {
  const repository = await initializeRepository();
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-redaction-");
  const agentDirectory = await temporaryDirectory("zcode-orchestrator-profiles-");
  const apiKeyFile = path.join(stateDirectory, "api-key");
  const apiKey = "secret-agent-test-key";
  await writeFile(apiKeyFile, `${apiKey}\n`);
  const tracker = new GitTracker();
  const processRunner = {
    async run() {
      return {
        code: 0,
        signal: null,
        stdout: JSON.stringify({
          response: JSON.stringify({
            status: "completed",
            summary: `provider output contained ${apiKey}`,
            findings: [],
            changes: [],
            commands: [],
            blockers: [],
            nextActions: [],
          }),
          usage: {},
        }),
        stderr: `diagnostic contained ${apiKey}`,
        durationMs: 1,
        timedOut: false,
        aborted: false,
        outputExceeded: false,
        spawnError: null,
      };
    },
  };
  const runner = new ZCodeAgentRunner(
    testConfig(stateDirectory, {
      agentDir: agentDirectory,
      apiKeyFile,
      bwrap: process.execPath,
      zcodeCli: process.execPath,
      node: process.execPath,
      entryScript: serverScript,
    }),
    { processRunner },
  );
  const result = await runner.run({
    role: "explorer",
    task: "Inspect the repository",
    workspace: repository,
    dependencyContext: [],
    protectedPaths: [],
    gitSnapshot: await tracker.snapshot(repository),
  });
  assert.equal(result.schemaValid, true);
  assert.match(result.summary, /\[REDACTED\]/u);
  assert.match(result.runtime.stderr, /\[REDACTED\]/u);
  assert.ok(!JSON.stringify(result).includes(apiKey));
});

test("Git tracker distinguishes task-owned changes from protected baseline changes", async () => {
  const repository = await initializeRepository();
  await writeFile(path.join(repository, "baseline.txt"), "user change\n");
  const tracker = new GitTracker();
  const baseline = await tracker.snapshot(repository);
  await writeFile(path.join(repository, "baseline.txt"), "agent overwrote user change\n");
  await writeFile(path.join(repository, "feature.txt"), "feature\n");
  const ownership = tracker.compare(baseline, await tracker.snapshot(repository));
  assert.deepEqual(ownership.agentCreatedPaths, ["feature.txt"]);
  assert.deepEqual(ownership.protectedTouchedPaths, ["baseline.txt"]);
  assert.deepEqual(ownership.protectedClearedPaths, []);
  assert.equal(ownership.ownershipAmbiguous, false);
});

test("orchestrator canonicalizes repository workspaces and rejects writer tasks outside Git", async () => {
  const repository = await initializeRepository();
  const nestedWorkspace = path.join(repository, "nested", "workspace");
  await mkdir(nestedWorkspace, { recursive: true });
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-workspace-root-");
  const agentRunner = {
    async run(input) {
      return completedResult(input.role);
    },
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory), { agentRunner });
  const planned = await orchestrator.start({
    task: "Implement a feature",
    workspace: nestedWorkspace,
    mode: "plan",
  });
  assert.equal(planned.workspace, repository);

  const nonRepository = await temporaryDirectory("zcode-orchestrator-non-repository-");
  await assert.rejects(
    () => orchestrator.start({ task: "Implement a feature", workspace: nonRepository }),
    /Git repository/u,
  );
});

test("concurrent starts reserve one canonical workspace exactly once", async () => {
  const repository = await initializeRepository();
  const nestedWorkspace = path.join(repository, "nested");
  await mkdir(nestedWorkspace);
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-reservation-");
  let releaseAgent;
  let announceAgentStart;
  const agentStarted = new Promise((resolve) => {
    announceAgentStart = resolve;
  });
  const agentRunner = {
    async run(input) {
      announceAgentStart();
      return new Promise((resolve) => {
        releaseAgent = () => resolve(completedResult(input.role));
      });
    },
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory, { maxActiveRuns: 2 }), { agentRunner });
  const attempts = await Promise.allSettled([
    orchestrator.start({ task: "Explain the repository", workspace: repository }),
    orchestrator.start({ task: "Explain the repository", workspace: nestedWorkspace }),
  ]);
  assert.equal(attempts.filter((attempt) => attempt.status === "fulfilled").length, 1);
  assert.equal(attempts.filter((attempt) => attempt.status === "rejected").length, 1);
  assert.match(attempts.find((attempt) => attempt.status === "rejected").reason.message, /workspace already/u);
  await agentStarted;
  releaseAgent();
  const accepted = attempts.find((attempt) => attempt.status === "fulfilled").value;
  assert.equal((await waitForTerminal(orchestrator, accepted.id)).status, "completed");
});

test("independent reader units execute in parallel", async () => {
  const repository = await initializeRepository();
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-parallel-readers-");
  let activeReaders = 0;
  let maximumReaders = 0;
  const agentRunner = {
    async run(input) {
      if (["explorer", "security"].includes(input.role)) {
        activeReaders += 1;
        maximumReaders = Math.max(maximumReaders, activeReaders);
        await new Promise((resolve) => setTimeout(resolve, 25));
        activeReaders -= 1;
      }
      return completedResult(input.role);
    },
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory), { agentRunner });
  const started = await orchestrator.start({
    task: "Review authentication security boundaries",
    workspace: repository,
  });
  assert.equal((await waitForTerminal(orchestrator, started.id)).status, "completed");
  assert.equal(maximumReaders, 2);
});

test("dependency context excludes private sub-agent runtime fields", async () => {
  const repository = await initializeRepository();
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-context-");
  let implementationContext;
  const agentRunner = {
    async run(input) {
      if (input.role === "implementation") implementationContext = input.dependencyContext;
      return {
        ...completedResult(input.role),
        privateTranscript: "must not propagate",
        runtime: { stderr: "must not propagate" },
      };
    },
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory), { agentRunner });
  const started = await orchestrator.start({ task: "Implement a feature", workspace: repository });
  assert.equal((await waitForTerminal(orchestrator, started.id)).status, "completed");
  assert.equal(implementationContext.length, 1);
  assert.deepEqual(Object.keys(implementationContext[0]).sort(), [
    "blockers",
    "changes",
    "commands",
    "findings",
    "id",
    "role",
    "status",
    "summary",
  ]);
  assert.ok(!JSON.stringify(implementationContext).includes("must not propagate"));
});

test("orchestration deadline cancels the active unit", async () => {
  const repository = await initializeRepository();
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-timeout-");
  const agentRunner = {
    run(input) {
      return new Promise((resolve, reject) => {
        const abort = () => reject(input.signal.reason ?? new Error("cancelled"));
        if (input.signal.aborted) abort();
        else input.signal.addEventListener("abort", abort, { once: true });
      });
    },
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory, { runTimeoutMs: 30 }), { agentRunner });
  const started = await orchestrator.start({ task: "Explain the repository", workspace: repository });
  const run = await waitForTerminal(orchestrator, started.id);
  assert.equal(run.status, "failed");
  assert.equal(run.plan.units[0].status, "cancelled");
  assert.match(run.plan.units[0].error, /timed out/u);
});

test("orchestrator executes dependent roles and preserves a pre-existing dirty path", async () => {
  const repository = await initializeRepository();
  await writeFile(path.join(repository, "baseline.txt"), "user change\n");
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-run-");
  const calls = [];
  let activeWriters = 0;
  let maximumWriters = 0;
  const agentRunner = {
    async run(input) {
      calls.push(input.role);
      if (["implementation", "test", "documentation"].includes(input.role)) {
        activeWriters += 1;
        maximumWriters = Math.max(maximumWriters, activeWriters);
        if (input.role === "implementation") {
          await writeFile(path.join(input.workspace, "feature.txt"), "implemented\n");
        }
        await new Promise((resolve) => setTimeout(resolve, 5));
        activeWriters -= 1;
      }
      return completedResult(input.role);
    },
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory), { agentRunner });
  const started = await orchestrator.start({
    task: "Implement and document a verified feature",
    workspace: repository,
  });
  const run = await waitForTerminal(orchestrator, started.id);
  assert.equal(run.status, "completed");
  assert.equal(maximumWriters, 1);
  assert.ok(calls.indexOf("implementation") < calls.indexOf("test"));
  assert.ok(calls.indexOf("test") < calls.indexOf("documentation"));
  assert.ok(calls.indexOf("documentation") < calls.indexOf("code-review"));
  assert.deepEqual(run.agentCreatedPaths, ["feature.txt"]);
  assert.deepEqual(run.violations, []);
  assert.equal(await readFile(path.join(repository, "baseline.txt"), "utf8"), "user change\n");
});

test("reader failure is isolated and transient failures retry once", async () => {
  const repository = await initializeRepository();
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-failure-");
  const attempts = new Map();
  const agentRunner = {
    async run(input) {
      const count = (attempts.get(input.role) ?? 0) + 1;
      attempts.set(input.role, count);
      if (input.role === "explorer" && count === 1) {
        const error = new Error("temporary network failure");
        error.transient = true;
        throw error;
      }
      if (input.role === "security") throw new Error("scanner unavailable");
      return completedResult(input.role);
    },
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory), { agentRunner });
  const started = await orchestrator.start({ task: "Review security boundaries", workspace: repository });
  const run = await waitForTerminal(orchestrator, started.id);
  assert.equal(run.status, "partial");
  assert.equal(attempts.get("explorer"), 2);
  assert.equal(run.plan.units.find((unit) => unit.role === "explorer").status, "completed");
  assert.equal(run.plan.units.find((unit) => unit.role === "security").status, "failed");
});

test("failed dependencies skip downstream units without running them", async () => {
  const repository = await initializeRepository();
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-dependency-failure-");
  const calls = [];
  const agentRunner = {
    async run(input) {
      calls.push(input.role);
      if (input.role === "explorer") throw new Error("exploration failed");
      return completedResult(input.role);
    },
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory), { agentRunner });
  const started = await orchestrator.start({ task: "Implement a feature", workspace: repository });
  const run = await waitForTerminal(orchestrator, started.id);
  assert.equal(run.status, "partial");
  assert.deepEqual(calls, ["explorer"]);
  assert.equal(run.plan.units.find((unit) => unit.role === "explorer").status, "failed");
  for (const role of ["implementation", "test", "code-review"]) {
    assert.equal(run.plan.units.find((unit) => unit.role === role).status, "skipped");
  }
});

test("reader workspace mutation blocks subsequent writers", async () => {
  const repository = await initializeRepository();
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-reader-violation-");
  const agentRunner = {
    async run(input) {
      if (input.role === "explorer") {
        await writeFile(path.join(input.workspace, "rogue.txt"), "reader mutation\n");
      }
      return completedResult(input.role);
    },
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory), { agentRunner });
  const started = await orchestrator.start({ task: "Implement a feature", workspace: repository });
  const run = await waitForTerminal(orchestrator, started.id);
  assert.equal(run.status, "blocked");
  assert.match(run.violations.join("\n"), /workspace changed during read-only/u);
  assert.equal(run.plan.units.find((unit) => unit.role === "implementation").status, "skipped");
});

test("active orchestration can be cancelled", async () => {
  const repository = await initializeRepository();
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-cancel-");
  const agentRunner = {
    run(input) {
      return new Promise((resolve, reject) => {
        const abort = () => reject(input.signal.reason ?? new Error("cancelled"));
        if (input.signal.aborted) abort();
        else input.signal.addEventListener("abort", abort, { once: true });
      });
    },
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory), { agentRunner });
  const started = await orchestrator.start({ task: "Explain the repository", workspace: repository });
  const run = await orchestrator.cancel(started.id);
  assert.equal(run.status, "cancelled");
  assert.equal(run.plan.units[0].status, "cancelled");
});

test("signed exact-path commit and local push preserve pre-existing changes", async () => {
  const repository = await initializeRepository();
  const remote = await temporaryDirectory("zcode-orchestrator-remote-");
  await git(remote, "init", "--bare", "-q");
  await git(repository, "remote", "add", "origin", remote);
  await git(repository, "push", "-q", "-u", "origin", "HEAD");

  const signingDirectory = await temporaryDirectory("zcode-orchestrator-signing-");
  const signingKey = path.join(signingDirectory, "signing-key");
  await command("ssh-keygen", ["-q", "-t", "ed25519", "-N", "", "-f", signingKey]);
  const publicKey = (await readFile(`${signingKey}.pub`, "utf8")).trim();
  const allowedSigners = path.join(signingDirectory, "allowed-signers");
  await writeFile(allowedSigners, `zcode-test@example.invalid ${publicKey}\n`);
  await git(repository, "config", "gpg.format", "ssh");
  await git(repository, "config", "user.signingkey", signingKey);
  await git(repository, "config", "gpg.ssh.allowedSignersFile", allowedSigners);
  await git(repository, "config", "commit.gpgsign", "true");

  await writeFile(path.join(repository, "baseline.txt"), "pre-existing user change\n");
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-git-");
  const agentRunner = {
    async run(input) {
      if (input.role === "implementation") {
        await writeFile(path.join(input.workspace, "feature.txt"), "signed feature\n");
      }
      return completedResult(input.role);
    },
  };
  const tracker = new GitTracker();
  const gitOperations = [];
  const runGitCommand = tracker.command.bind(tracker);
  tracker.command = async (workspace, args, options) => {
    gitOperations.push(args[0]);
    return runGitCommand(workspace, args, options);
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory), { agentRunner, gitTracker: tracker });
  const started = await orchestrator.start({ task: "Implement signed feature", workspace: repository });
  const run = await waitForTerminal(orchestrator, started.id);
  assert.equal(run.status, "completed");
  assert.deepEqual(run.agentCreatedPaths, ["feature.txt"]);

  const prepared = await orchestrator.prepareGit({
    runId: run.id,
    paths: ["feature.txt"],
    message: "feat: add signed feature",
    push: true,
  });
  await orchestrator.approvals.recordPrompt(prepared.phrase);
  const applied = await orchestrator.applyGit(prepared.token).catch((error) => {
    const diagnostics = error?.result
      ? `${error.result.stdout ?? ""}\n${error.result.stderr ?? ""}`
      : "";
    throw new Error(`${error instanceof Error ? error.message : String(error)}\n${diagnostics}`);
  });
  assert.equal(applied.status, "completed");
  assert.equal(applied.signatureVerified, true);
  assert.equal(applied.pushed, true);
  const verifyPosition = gitOperations.lastIndexOf("verify-commit");
  const updatePosition = gitOperations.lastIndexOf("update-ref");
  assert.notEqual(verifyPosition, -1);
  assert.notEqual(updatePosition, -1);
  assert.ok(verifyPosition < updatePosition, "the signature must be verified before HEAD is updated");
  assert.deepEqual(applied.residual.staged, []);
  assert.deepEqual(applied.residual.unstaged, ["baseline.txt"]);

  const remoteHead = (await git(remote, "rev-parse", "HEAD")).stdout.trim();
  assert.equal(remoteHead, applied.head);
  const committedPaths = (await git(repository, "show", "--format=", "--name-only", "HEAD")).stdout
    .trim()
    .split("\n")
    .filter(Boolean);
  assert.deepEqual(committedPaths, ["feature.txt"]);
  assert.equal(await readFile(path.join(repository, "baseline.txt"), "utf8"), "pre-existing user change\n");
});

test("rollback removes only prepared task-owned paths", async () => {
  const repository = await initializeRepository();
  await writeFile(path.join(repository, "baseline.txt"), "pre-existing user change\n");
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-rollback-");
  const agentRunner = {
    async run(input) {
      if (input.role === "implementation") {
        await writeFile(path.join(input.workspace, "temporary-feature.txt"), "temporary\n");
      }
      return completedResult(input.role);
    },
  };
  const orchestrator = new Orchestrator(testConfig(stateDirectory), { agentRunner });
  const started = await orchestrator.start({ task: "Implement temporary feature", workspace: repository });
  const run = await waitForTerminal(orchestrator, started.id);
  const prepared = await orchestrator.prepareRollback({ runId: run.id });
  await orchestrator.approvals.recordPrompt(prepared.phrase);
  const rolledBack = await orchestrator.applyRollback(prepared.token);
  assert.equal(rolledBack.status, "completed");
  assert.deepEqual(rolledBack.removed, ["temporary-feature.txt"]);
  await assert.rejects(() => readFile(path.join(repository, "temporary-feature.txt")), /ENOENT/u);
  assert.equal(await readFile(path.join(repository, "baseline.txt"), "utf8"), "pre-existing user change\n");
});

test("MCP server initializes and lists the complete orchestration tool surface", async () => {
  const stateDirectory = await temporaryDirectory("zcode-orchestrator-mcp-");
  const input = [
    { jsonrpc: "2.0", id: 1, method: "initialize", params: { protocolVersion: "2025-06-18" } },
    { jsonrpc: "2.0", method: "notifications/initialized", params: {} },
    { jsonrpc: "2.0", id: 2, method: "tools/list", params: {} },
  ]
    .map((message) => JSON.stringify(message))
    .join("\n");
  const execution = await new ProcessRunner().run(process.execPath, [serverScript], {
    stdin: `${input}\n`,
    env: {
      ...process.env,
      ZCODE_ORCHESTRATOR_STATE_DIR: stateDirectory,
    },
    timeoutMs: 5_000,
  });
  assert.equal(execution.code, 0, execution.stderr);
  const messages = execution.stdout
    .trim()
    .split("\n")
    .map((line) => JSON.parse(line));
  assert.equal(messages[0].result.serverInfo.name, "zcode-orchestrator");
  assert.deepEqual(
    messages[1].result.tools.map((tool) => tool.name),
    [
      "orchestrate",
      "orchestration_status",
      "orchestration_cancel",
      "orchestration_approve",
      "git_prepare",
      "git_apply",
      "rollback_prepare",
      "rollback_apply",
    ],
  );
});

test.after(async () => {
  for (const directory of temporaryDirectories.splice(0)) {
    await rm(directory, { recursive: true, force: true });
  }
});
