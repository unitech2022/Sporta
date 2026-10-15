/**
 * SignalR connection to the support-chat hub (/hubs/support-chat).
 *
 * One connection is shared by the whole tab: the hub already puts every
 * connection in the caller's own group and, for admin/staff, in the
 * support-admins group, so a second socket would only duplicate events.
 * Subscribers filter what they care about.
 *
 * Server → client events:
 *   MessageReceived     { conversationId, message }
 *   ConversationUpdated { ...conversation summary }
 *   ConversationRead    { conversationId, byAdmin, readAt }
 *   Typing              { conversationId, fromAdmin, userId? }
 *
 * Usage:
 *   const off = onSupportEvent('MessageReceived', payload => { ... })
 *   connectSupportHub()          // idempotent — safe from every mount
 *   ...
 *   off()                        // on unmount
 */
import {
  HubConnectionBuilder,
  HubConnectionState,
  LogLevel,
} from '@microsoft/signalr';
import { BASE_URL } from './apiClient';

const EVENTS = ['MessageReceived', 'ConversationUpdated', 'ConversationRead', 'Typing'];

let connection = null;
let startPromise = null;
let currentToken = null;
// event name → Set of listeners
const listeners = new Map(EVENTS.map(e => [e, new Set()]));

/** Subscribe to one hub event. Returns the unsubscribe function. */
export function onSupportEvent(event, handler) {
  const set = listeners.get(event);
  if (!set) return () => {};
  set.add(handler);
  return () => set.delete(handler);
}

function dispatch(event, payload) {
  for (const fn of listeners.get(event) ?? []) {
    // One bad subscriber must not stop the others from getting the event.
    try { fn(payload); } catch { /* ignore */ }
  }
}

/**
 * Opens (or reuses) the connection for the stored token. Returns the
 * connection, or null when there is no token / the handshake failed — callers
 * fall back to REST, which already holds the full history.
 */
export async function connectSupportHub() {
  const token = localStorage.getItem('access_token');
  if (!token) return null;

  // A different account signed in — drop the old socket first.
  if (connection && currentToken !== token) await disconnectSupportHub();

  if (connection && connection.state === HubConnectionState.Connected) return connection;
  if (startPromise) return startPromise;

  currentToken = token;
  connection = new HubConnectionBuilder()
    .withUrl(`${BASE_URL}/hubs/support-chat`, {
      accessTokenFactory: () => localStorage.getItem('access_token') ?? token,
      // The JS client sends credentials by default, which an
      // `Access-Control-Allow-Origin: *` API must reject — the browser then
      // reports the negotiate as "Failed to fetch". We authenticate with the
      // bearer token, so cookies are not needed.
      withCredentials: false,
    })
    .withAutomaticReconnect([0, 2000, 5000, 10000, 20000])
    .configureLogging(LogLevel.Warning)
    .build();

  for (const evt of EVENTS) connection.on(evt, payload => dispatch(evt, payload));

  startPromise = connection.start()
    .then(() => connection)
    .catch(() => {
      // Hub unreachable (old API build, proxy without WebSocket support, …).
      // The UI stays usable over REST; a later mount retries.
      connection = null;
      currentToken = null;
      return null;
    })
    .finally(() => { startPromise = null; });

  return startPromise;
}

export async function disconnectSupportHub() {
  const c = connection;
  connection = null;
  currentToken = null;
  if (!c) return;
  try { await c.stop(); } catch { /* already gone */ }
}

/** True while messages are arriving live; false means the UI is REST-only. */
export function isSupportHubLive() {
  return !!connection && connection.state === HubConnectionState.Connected;
}

/**
 * Fire-and-forget "typing…" ping; never throws. Throttled to one call per 1.5s
 * so a fast typist doesn't flood the hub (the receiver's indicator self-expires
 * after a few seconds anyway).
 */
let lastTypingAt = 0;
export function sendTyping(conversationId, targetUserId = 0) {
  if (!isSupportHubLive()) return;
  const now = Date.now();
  if (now - lastTypingAt < 1500) return;
  lastTypingAt = now;
  connection.invoke('Typing', Number(conversationId) || 0, Number(targetUserId) || 0)
    .catch(() => {});
}
