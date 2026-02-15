import path from 'path';
import fs from 'fs';
import os from 'os';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const stripFrontmatter = (content) => {
  const match = content.match(/^---\n[\s\S]*?\n---\n([\s\S]*)$/);
  return match ? match[1] : content;
};

const normalizePath = (p, homeDir) => {
  if (!p || typeof p !== 'string') return null;
  let normalized = p.trim();
  if (!normalized) return null;
  if (normalized.startsWith('~/')) {
    normalized = path.join(homeDir, normalized.slice(2));
  } else if (normalized === '~') {
    normalized = homeDir;
  }
  return path.resolve(normalized);
};

const safeReadUtf8 = (filePath) => {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch {
    return null;
  }
};

const listDirNames = (dirPath) => {
  try {
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });
    return entries
      .filter((e) => e.isDirectory())
      .map((e) => e.name)
      .sort((a, b) => a.localeCompare(b));
  } catch {
    return [];
  }
};

const LOOP_COMMAND = 'pensieve-loop';
const LOOP_CANCEL_COMMAND = 'pensieve-cancel';
const LOOP_STATUS_COMMAND = 'pensieve-status';

const DEFAULT_COMPLETION_PROMISE = 'DONE';
const DEFAULT_MAX_ITERATIONS = 100;

const loopBySessionId = new Map();

const roleByMessageId = new Map();
const textPartsByMessageId = new Map();
const hasSyntheticTextByMessageId = new Map();

const getMessageText = (messageID) => {
  const parts = textPartsByMessageId.get(messageID);
  if (!parts) return '';
  return Array.from(parts.values()).join('\n\n');
};

const rememberTextPart = (part) => {
  const id = part.id || '__text__';
  const existing = textPartsByMessageId.get(part.messageID);
  const map = existing || new Map();
  map.set(id, part.text || '');
  if (!existing) textPartsByMessageId.set(part.messageID, map);

  if (part.synthetic || part.metadata?.ralphLoop || part.metadata?.pensieveLoop)
    hasSyntheticTextByMessageId.set(part.messageID, true);
};

const unquote = (s) => {
  const trimmed = (s || '').trim();
  if (
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  ) {
    return trimmed.slice(1, -1);
  }
  return trimmed;
};

const tokenizeArgs = (raw) => {
  if (!raw || typeof raw !== 'string') return [];
  const matches = raw.match(/"[^"]*"|'[^']*'|\S+/g);
  return (matches || []).map(unquote).filter(Boolean);
};

const parseBoolean = (value) => {
  const s = String(value || '')
    .trim()
    .toLowerCase();
  if (s === '1' || s === 'true' || s === 'yes' || s === 'on') return true;
  if (s === '0' || s === 'false' || s === 'no' || s === 'off') return false;
  return null;
};

const parseLoopArgs = (rawArgs) => {
  let tokens = tokenizeArgs(rawArgs);

  // Some callers wrap the entire argument string in quotes.
  // If that happens, we may see a single token that still contains flags.
  if (tokens.length === 1 && /--(completion-promise|max-iterations|debug)\b/.test(tokens[0])) {
    tokens = tokenizeArgs(tokens[0]);
  }

  let completionPromise = DEFAULT_COMPLETION_PROMISE;
  let maxIterations = DEFAULT_MAX_ITERATIONS;
  let debug = false;
  const taskTokens = [];

  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i];

    if (t.startsWith('--completion-promise=')) {
      completionPromise = t.slice('--completion-promise='.length) || completionPromise;
      continue;
    }
    if (t === '--completion-promise' && i + 1 < tokens.length) {
      completionPromise = tokens[i + 1] || completionPromise;
      i++;
      continue;
    }

    if (t.startsWith('--max-iterations=')) {
      const v = Number.parseInt(t.slice('--max-iterations='.length), 10);
      if (Number.isFinite(v) && v > 0) maxIterations = v;
      continue;
    }
    if (t === '--max-iterations' && i + 1 < tokens.length) {
      const v = Number.parseInt(tokens[i + 1], 10);
      if (Number.isFinite(v) && v > 0) maxIterations = v;
      i++;
      continue;
    }

    if (t === '--debug') {
      debug = true;
      continue;
    }
    if (t.startsWith('--debug=')) {
      const parsed = parseBoolean(t.slice('--debug='.length));
      debug = parsed === null ? true : parsed;
      continue;
    }

    taskTokens.push(t);
  }

  const task = taskTokens.join(' ').trim();
  return {
    task,
    completionPromise: (completionPromise || DEFAULT_COMPLETION_PROMISE).trim(),
    maxIterations,
    debug,
  };
};

const tryLog = async (client, directory, level, message, extra) => {
  try {
    await client.app.log({
      query: { directory },
      body: {
        service: 'pensieve.loop',
        level,
        message,
        extra,
      },
    });
  } catch (err) {
    console.error('[pensieve.loop] log failed:', err);
  }
};

const tryToast = async (client, directory, variant, message, title) => {
  try {
    await client.tui.showToast({
      query: { directory },
      body: {
        title,
        message,
        variant,
        duration: 4000,
      },
    });
  } catch (err) {
    await tryLog(client, directory, 'debug', 'toast failed', {
      error: err instanceof Error ? err.message : String(err),
      variant,
      title,
    });
  }
};

const debugLog = async (client, directory, state, level, message, extra) => {
  if (!state?.debug) return;
  await tryLog(client, directory, level, message, extra);
};

const buildContinuePrompt = ({ task, completionPromise, attempt, maxIterations }) => {
  const safeTask = (task || '').trim() || '(no task provided)';
  const promise = completionPromise || DEFAULT_COMPLETION_PROMISE;

  return `[SYSTEM DIRECTIVE: PENSIEVE LOOP ${attempt}/${maxIterations}]

Your previous attempt did not output the completion promise. Continue working on the task.

IMPORTANT:
- Review your progress so far
- Continue from where you left off
- When FULLY complete, output: <promise>${promise}</promise>
- Do not stop until the task is truly done

Original task:
${safeTask}
`;
};

export const PensievePlugin = async ({ client, directory, worktree }) => {
  const homeDir = os.homedir();
  const envConfigDir = normalizePath(process.env.OPENCODE_CONFIG_DIR, homeDir);
  const configDir = envConfigDir || path.join(homeDir, '.config/opencode');

  const pluginRoot = path.resolve(__dirname, '../..');
  const systemSkillRoot = path.join(pluginRoot, 'skills', 'pensieve');

  const projectRoot = worktree || directory;
  const userDataRoot = projectRoot ? path.join(projectRoot, '.claude', 'pensieve') : null;

  const getSkillBootstrapBody = () => {
    const skillPath = path.join(systemSkillRoot, 'SKILL.md');
    const full = safeReadUtf8(skillPath);
    if (!full) return null;
    return stripFrontmatter(full).trim();
  };

  const getRoutesContext = () => {
    const toolsRoot = path.join(systemSkillRoot, 'tools');
    const knowledgeRoot = path.join(systemSkillRoot, 'knowledge');

    const tools = listDirNames(toolsRoot);
    const knowledge = listDirNames(knowledgeRoot);

    const lines = [];
    lines.push('# Pensieve available resources');
    lines.push('');
    lines.push('## Paths');
    lines.push('');
    lines.push(`- Plugin root (system capability): \`${pluginRoot}\``);
    lines.push(`- <SYSTEM_SKILL_ROOT>: \`${systemSkillRoot}\``);
    if (userDataRoot) {
      lines.push(`- <USER_DATA_ROOT>: \`${userDataRoot}\``);
    } else {
      lines.push('- <USER_DATA_ROOT>: (unknown)');
    }
    lines.push('');

    if (tools.length) {
      lines.push('## System Tools');
      lines.push('');
      for (const t of tools) lines.push(`- \`${t}/\``);
      lines.push('');
    }

    if (knowledge.length) {
      lines.push('## System Knowledge');
      lines.push('');
      for (const k of knowledge) lines.push(`- \`${k}/\``);
      lines.push('');
    }

    lines.push('## OpenCode Notes');
    lines.push('');
    lines.push('- Claude Code hooks (SessionStart/Stop) are not available in OpenCode.');
    lines.push('- This plugin injects route variables on each request via `experimental.chat.system.transform`.');
    lines.push(`- OpenCode config dir: \`${configDir}\``);
    lines.push('');
    lines.push('Quick init (project root):');
    lines.push('');
    lines.push('```bash');
    lines.push('bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-project-data.sh');
    lines.push('```');

    return lines.join('\n');
  };

  const getBootstrapContent = () => {
    const routes = getRoutesContext();
    const skillBody = getSkillBootstrapBody();

    const parts = [];
    parts.push('<PENSIEVE>');
    parts.push(routes);
    if (skillBody) {
      parts.push('');
      parts.push('---');
      parts.push('');
      parts.push('# Pensieve Skill (bootstrap)');
      parts.push('');
      parts.push(skillBody);
    }
    parts.push('</PENSIEVE>');

    return parts.join('\n');
  };

  return {
    'experimental.chat.system.transform': async (_input, output) => {
      const bootstrap = getBootstrapContent();
      if (bootstrap) {
        (output.system ||= []).push(bootstrap);
      }
    },
    'command.execute.before': async ({ command, sessionID, arguments: args }, _output) => {
      if (!sessionID || !command) return;

      if (command === LOOP_COMMAND) {
        const parsed = parseLoopArgs(args || '');
        if (!parsed.task) {
          await tryToast(
            client,
            directory,
            'error',
            'Missing task. Usage: /pensieve-loop <task> [--completion-promise=TEXT] [--max-iterations=N] [--debug]',
            'Pensieve Loop',
          );
          return;
        }

        loopBySessionId.set(sessionID, {
          active: true,
          task: parsed.task,
          completionPromise: parsed.completionPromise || DEFAULT_COMPLETION_PROMISE,
          maxIterations: parsed.maxIterations || DEFAULT_MAX_ITERATIONS,
          attempt: 0,
          debug: Boolean(parsed.debug),
          continueInFlight: false,
          startMessageID: null,
          lastCompletedAssistantMessageID: null,
          pendingContinueAfterMessageID: null,
          agent: null,
          model: null,
          startedAt: Date.now(),
        });

        await debugLog(client, directory, loopBySessionId.get(sessionID), 'info', 'loop started', {
          sessionID,
          parsed,
        });

        await tryToast(
          client,
          directory,
          'success',
          `Started. Promise=<promise>${parsed.completionPromise || DEFAULT_COMPLETION_PROMISE}</promise>, max=${parsed.maxIterations || DEFAULT_MAX_ITERATIONS}.`,
          'Pensieve Loop',
        );
        return;
      }

      if (command === LOOP_CANCEL_COMMAND) {
        const state = loopBySessionId.get(sessionID);
        if (state?.active) {
          state.active = false;
          state.pendingContinueAfterMessageID = null;
          await tryToast(client, directory, 'info', 'Cancelled. Auto-continuation stopped.', 'Pensieve Loop');
        } else {
          await tryToast(client, directory, 'info', 'No active loop in this session.', 'Pensieve Loop');
        }
        return;
      }

      if (command === LOOP_STATUS_COMMAND) {
        const state = loopBySessionId.get(sessionID);
        if (!state) {
          await tryToast(client, directory, 'info', 'No loop state for this session.', 'Pensieve Loop');
          return;
        }
        await tryToast(
          client,
          directory,
          state.active ? 'info' : 'success',
          `active=${Boolean(state.active)} attempts=${state.attempt}/${state.maxIterations} promise=${state.completionPromise}`,
          'Pensieve Loop',
        );
      }
    },
    'experimental.session.compacting': async ({ sessionID }, output) => {
      const state = loopBySessionId.get(sessionID);
      if (!state?.active) return;

      output.context.push(
        [
          '## Pensieve Loop (plugin state)',
          `active: true`,
          `attempts_completed: ${state.attempt}`,
          `max_iterations: ${state.maxIterations}`,
          `completion_promise: ${state.completionPromise}`,
          state.task ? `task: ${state.task}` : 'task: (none)',
          state.pendingContinueAfterMessageID ? `pending_continue_after: ${state.pendingContinueAfterMessageID}` : '',
        ]
          .filter(Boolean)
          .join('\n'),
      );
    },
    event: async ({ event }) => {
      if (!event || typeof event !== 'object') return;

      if (event.type === 'message.updated') {
        const info = event.properties?.info;
        if (!info?.id || !info?.sessionID || !info?.role) return;

        roleByMessageId.set(info.id, info.role);

        const state = loopBySessionId.get(info.sessionID);
        if (!state?.active) return;

        await debugLog(client, directory, state, 'debug', 'message.updated', {
          id: info.id,
          sessionID: info.sessionID,
          role: info.role,
          time: info.time,
        });

        if (info.role === 'user') {
          if (!state.startMessageID) {
            state.startMessageID = info.id;
            await debugLog(client, directory, state, 'info', 'startMessageID set', {
              sessionID: info.sessionID,
              startMessageID: info.id,
            });
          }
          if (typeof info.agent === 'string') state.agent = info.agent;
          if (info.model && typeof info.model === 'object') state.model = info.model;
        }

      if (info.role !== 'assistant') return;
        if (!info.time || !info.time.completed) return;
        if (state.lastCompletedAssistantMessageID === info.id) return;

        state.lastCompletedAssistantMessageID = info.id;
        state.attempt += 1;

        const text = getMessageText(info.id);
        const promise = state.completionPromise || DEFAULT_COMPLETION_PROMISE;
        const doneMarker = `<promise>${promise}</promise>`;

        if (text.includes(doneMarker)) {
          state.active = false;
          state.pendingContinueAfterMessageID = null;
          await debugLog(client, directory, state, 'info', 'loop completed', {
            sessionID: info.sessionID,
            attempt: state.attempt,
          });
          await tryToast(client, directory, 'success', `Completed after ${state.attempt} attempt(s).`, 'Pensieve Loop');
          return;
        }

        if (state.attempt >= state.maxIterations) {
          state.active = false;
          state.pendingContinueAfterMessageID = null;
          await debugLog(client, directory, state, 'warning', 'max iterations reached', {
            sessionID: info.sessionID,
            attempt: state.attempt,
            maxIterations: state.maxIterations,
          });
          await tryToast(client, directory, 'warning', `Stopped after reaching max iterations (${state.maxIterations}).`, 'Pensieve Loop');
          return;
        }

        const nextAttempt = state.attempt + 1;
        const prompt = buildContinuePrompt({
          task: state.task,
          completionPromise: state.completionPromise,
          attempt: nextAttempt,
          maxIterations: state.maxIterations,
        });

        if (state.continueInFlight) return;
        state.continueInFlight = true;

        try {
          await debugLog(client, directory, state, 'info', 'continuing', {
            sessionID: info.sessionID,
            afterMessageID: info.id,
            nextAttempt,
            maxIterations: state.maxIterations,
          });

          await client.session.promptAsync({
            query: { directory },
            path: { id: info.sessionID },
            body: {
              agent: state.agent || undefined,
              model: state.model || undefined,
              parts: [
                {
                  type: 'text',
                  synthetic: true,
                  text: prompt,
                  metadata: {
                    pensieveLoop: {
                      attempt: nextAttempt,
                      maxIterations: state.maxIterations,
                      completionPromise: state.completionPromise,
                    },
                  },
                },
              ],
            },
          });

          await debugLog(client, directory, state, 'info', 'promptAsync enqueued', {
            sessionID: info.sessionID,
            nextAttempt,
          });
          await tryToast(client, directory, 'info', `Continuing (next attempt ${nextAttempt}/${state.maxIterations})`, 'Pensieve Loop');
        } catch (err) {
          state.pendingContinueAfterMessageID = info.id;
          await debugLog(client, directory, state, 'warning', 'promptAsync failed; will wait for idle', {
            sessionID: info.sessionID,
            error: err instanceof Error ? err.message : String(err),
          });
          await tryToast(
            client,
            directory,
            'info',
            `Attempt ${state.attempt}/${state.maxIterations} incomplete; will continue on session idle.`,
            'Pensieve Loop',
          );
        } finally {
          state.continueInFlight = false;
        }
        return;
      }

      if (event.type === 'message.part.updated') {
        const part = event.properties?.part;
        if (!part || part.type !== 'text') return;

        rememberTextPart(part);

        const sessionID = part.sessionID;
        const state = loopBySessionId.get(sessionID);
        if (!state?.active) return;

        const role = roleByMessageId.get(part.messageID);
        const isSynthetic = Boolean(part.synthetic || hasSyntheticTextByMessageId.get(part.messageID));
        await debugLog(client, directory, state, 'debug', 'message.part.updated', {
          sessionID,
          messageID: part.messageID,
          role,
          synthetic: part.synthetic,
          isSynthetic,
        });
        if (role === 'user' && !isSynthetic && part.messageID !== state.startMessageID) {
          state.active = false;
          state.pendingContinueAfterMessageID = null;
          await debugLog(client, directory, state, 'warning', 'cancelled due to user message', {
            sessionID,
            messageID: part.messageID,
          });
          await tryToast(client, directory, 'warning', 'Cancelled due to user message (manual intervention).', 'Pensieve Loop');
        }

        return;
      }

      if (event.type === 'session.idle') {
        const sessionID = event.properties?.sessionID;
        if (!sessionID) return;

        const state = loopBySessionId.get(sessionID);
        if (!state?.active) return;
        if (!state.pendingContinueAfterMessageID) return;
        if (state.continueInFlight) return;

        state.continueInFlight = true;

        await debugLog(client, directory, state, 'info', 'session idle; continuing', {
          sessionID,
          afterMessageID: state.pendingContinueAfterMessageID,
          attempt: state.attempt,
        });

        const nextAttempt = state.attempt + 1;
        const prompt = buildContinuePrompt({
          task: state.task,
          completionPromise: state.completionPromise,
          attempt: nextAttempt,
          maxIterations: state.maxIterations,
        });

        state.pendingContinueAfterMessageID = null;

        try {
          await debugLog(client, directory, state, 'debug', 'calling promptAsync', {
            sessionID,
            nextAttempt,
          });
          await client.session.promptAsync({
            query: { directory },
            path: { id: sessionID },
            body: {
              agent: state.agent || undefined,
              model: state.model || undefined,
              parts: [
                {
                  type: 'text',
                  synthetic: true,
                  text: prompt,
                  metadata: {
                    pensieveLoop: {
                      attempt: nextAttempt,
                      maxIterations: state.maxIterations,
                      completionPromise: state.completionPromise,
                    },
                  },
                },
              ],
            },
          });

          await debugLog(client, directory, state, 'info', 'promptAsync enqueued', {
            sessionID,
            nextAttempt,
          });
          await tryToast(client, directory, 'info', `Continuing (next attempt ${nextAttempt}/${state.maxIterations})`, 'Pensieve Loop');
        } catch (err) {
          state.active = false;
          await debugLog(client, directory, state, 'error', 'promptAsync failed', {
            sessionID,
            error: err instanceof Error ? err.message : String(err),
          });
          await tryToast(
            client,
            directory,
            'error',
            `Failed to continue: ${err instanceof Error ? err.message : String(err)}`,
            'Pensieve Loop',
          );
        } finally {
          state.continueInFlight = false;
        }

        return;
      }
    },
  };
};
