import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { MessageSquare, Search, Send, CheckCheck, Check, Lock, Unlock, Wifi, WifiOff } from 'lucide-react';
import { supportApi } from '../api/supportApi';
import { connectSupportHub, onSupportEvent, isSupportHubLive, sendTyping } from '../api/supportHub';
import { useAuth } from '../context/AuthContext';
import { roleLabels } from '../utils/accountLabels';
import PageHeader from '../components/PageHeader';
import { Spinner, Empty } from '../components/TableBits';

const PAGE_SIZE = 20;

const inputCls =
  'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

/** Short "when" label: time for today, day+month otherwise. */
function shortTime(iso) {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '';
  const today = new Date();
  const sameDay =
    d.getDate() === today.getDate() &&
    d.getMonth() === today.getMonth() &&
    d.getFullYear() === today.getFullYear();
  return sameDay
    ? d.toLocaleTimeString('ar', { hour: '2-digit', minute: '2-digit' })
    : d.toLocaleDateString('ar', { day: 'numeric', month: 'short' });
}

export default function SupportChatPage() {
  const { can } = useAuth();
  const canReply = can('support.reply');

  // ── Conversation list ──────────────────────────────────────────────────────
  const [conversations, setConversations] = useState([]);
  const [unreadTotal, setUnreadTotal] = useState(0);
  const [listLoading, setListLoading] = useState(true);
  const [listError, setListError] = useState(null);
  const [search, setSearch] = useState('');
  const [unreadOnly, setUnreadOnly] = useState(false);

  // ── Open thread ────────────────────────────────────────────────────────────
  const [activeId, setActiveId] = useState(null);
  const [messages, setMessages] = useState([]);
  const [hasMore, setHasMore] = useState(false);
  const [threadLoading, setThreadLoading] = useState(false);
  const [draft, setDraft] = useState('');
  const [sending, setSending] = useState(false);
  const [live, setLive] = useState(false);
  const [peerTyping, setPeerTyping] = useState(false);

  const bottomRef = useRef(null);
  // Read inside hub handlers, which are registered once and would otherwise
  // capture the id from their first render.
  const activeIdRef = useRef(null);
  activeIdRef.current = activeId;

  const active = useMemo(
    () => conversations.find(c => c.id === activeId) ?? null,
    [conversations, activeId],
  );

  const loadConversations = useCallback(async () => {
    setListError(null);
    try {
      const res = await supportApi.conversations({ page: 1, pageSize: PAGE_SIZE, search, unreadOnly });
      const dto = res.data.data;
      setConversations(dto?.conversations?.items ?? []);
      setUnreadTotal(dto?.unreadTotal ?? 0);
    } catch (err) {
      setListError(
        err?.response?.data?.messageAr ||
        err?.response?.data?.message ||
        'تعذّر تحميل المحادثات',
      );
    } finally {
      setListLoading(false);
    }
  }, [search, unreadOnly]);

  // Debounced so typing in the search box doesn't fire a request per keystroke.
  useEffect(() => {
    const t = setTimeout(loadConversations, 300);
    return () => clearTimeout(t);
  }, [loadConversations]);

  // One shared socket for the page; REST stays the source of truth.
  useEffect(() => {
    let alive = true;
    connectSupportHub().then(() => { if (alive) setLive(isSupportHubLive()); });

    const offMessage = onSupportEvent('MessageReceived', ({ conversationId, message }) => {
      if (conversationId !== activeIdRef.current) return;
      // Our own reply already appended optimistically — skip the echo.
      setMessages(prev => (prev.some(m => m.id === message.id) ? prev : [...prev, message]));
      setPeerTyping(false);

      // The thread is on screen, so the line is read the moment it lands —
      // otherwise the server's badge would count a message we are looking at.
      if (!message.fromAdmin) {
        supportApi.markRead(conversationId).catch(() => {});
        setConversations(prev => prev.map(c => (
          c.id === conversationId ? { ...c, unreadForAdmin: 0 } : c
        )));
      }
    });

    const offUpdated = onSupportEvent('ConversationUpdated', (summary) => {
      setConversations(prev => {
        const rest = prev.filter(c => c.id !== summary.id);
        // Newest activity first — the same order the API returns.
        return [summary, ...rest];
      });
    });

    const offRead = onSupportEvent('ConversationRead', ({ conversationId, byAdmin, readAt }) => {
      if (conversationId !== activeIdRef.current || byAdmin) return;
      // The user opened the thread → our replies are now read.
      setMessages(prev => prev.map(m => (m.fromAdmin && !m.readAt ? { ...m, readAt } : m)));
    });

    const offTyping = onSupportEvent('Typing', ({ conversationId, fromAdmin }) => {
      if (fromAdmin || conversationId !== activeIdRef.current) return;
      setPeerTyping(true);
    });

    return () => { alive = false; offMessage(); offUpdated(); offRead(); offTyping(); };
  }, []);

  // The indicator is a hint, not state the server owns — let it lapse.
  useEffect(() => {
    if (!peerTyping) return;
    const t = setTimeout(() => setPeerTyping(false), 4000);
    return () => clearTimeout(t);
  }, [peerTyping]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth', block: 'end' });
  }, [messages, peerTyping]);

  const openConversation = useCallback(async (id) => {
    setActiveId(id);
    setThreadLoading(true);
    setPeerTyping(false);
    try {
      const res = await supportApi.messages(id, { limit: 30 });
      const dto = res.data.data;
      setMessages(dto?.messages ?? []);
      setHasMore(dto?.hasMore ?? false);

      await supportApi.markRead(id);
      setConversations(prev => prev.map(c => (c.id === id ? { ...c, unreadForAdmin: 0 } : c)));
      // Only a thread that actually had unread lines leaves the pending count.
      setUnreadTotal(prev => (
        conversations.find(c => c.id === id)?.unreadForAdmin > 0 ? Math.max(0, prev - 1) : prev
      ));
    } catch {
      setMessages([]);
    } finally {
      setThreadLoading(false);
    }
    // Depends on the list so the unread bookkeeping above reads current counts;
    // it is only called from click handlers, so re-creating it is free.
  }, [conversations]);

  const loadOlder = useCallback(async () => {
    if (!activeId || messages.length === 0) return;
    const res = await supportApi.messages(activeId, { before: messages[0].id, limit: 30 });
    const dto = res.data.data;
    setMessages(prev => [...(dto?.messages ?? []), ...prev]);
    setHasMore(dto?.hasMore ?? false);
  }, [activeId, messages]);

  const send = async (e) => {
    e?.preventDefault();
    const body = draft.trim();
    if (!body || !activeId || sending) return;

    setSending(true);
    try {
      const res = await supportApi.reply(activeId, body);
      const msg = res.data.data;
      setMessages(prev => (prev.some(m => m.id === msg.id) ? prev : [...prev, msg]));
      setDraft('');
      // Keep the list preview in step even when the socket is down.
      setConversations(prev => prev.map(c => (
        c.id === activeId
          ? { ...c, lastMessageText: body, lastMessageAt: msg.sentAt, lastMessageFromAdmin: true, status: 'Open' }
          : c
      )));
    } finally {
      setSending(false);
    }
  };

  const toggleStatus = async () => {
    if (!active) return;
    const next = active.status === 'Closed' ? 'Open' : 'Closed';
    const res = await supportApi.setStatus(active.id, next);
    const summary = res.data.data;
    setConversations(prev => prev.map(c => (c.id === summary.id ? summary : c)));
  };

  return (
    <div>
      <PageHeader
        title="الدردشة والدعم الفني"
        subtitle={unreadTotal > 0 ? `${unreadTotal} محادثة بانتظار الرد` : 'كل المحادثات مقروءة'}
        action={
          <span className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium ${
            live ? 'bg-green-50 text-green-600' : 'bg-gray-100 text-gray-500'
          }`}>
            {live ? <Wifi className="w-3.5 h-3.5" /> : <WifiOff className="w-3.5 h-3.5" />}
            {live ? 'متصل مباشرة' : 'تحديث يدوي'}
          </span>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 h-[calc(100vh-13rem)]">
        {/* ── List ───────────────────────────────────────────────────────── */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 flex flex-col overflow-hidden">
          <div className="p-3 border-b border-gray-100 space-y-2">
            <div className="relative">
              <Search className="w-4 h-4 text-gray-400 absolute top-1/2 -translate-y-1/2 right-3" />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="ابحث بالاسم أو الجوال"
                className={`${inputCls} pr-9`}
              />
            </div>
            <label className="flex items-center gap-2 text-xs text-gray-500 cursor-pointer">
              <input
                type="checkbox"
                checked={unreadOnly}
                onChange={(e) => setUnreadOnly(e.target.checked)}
                className="accent-[#2AB5CE]"
              />
              غير المقروءة فقط
            </label>
          </div>

          <div className="flex-1 overflow-y-auto divide-y divide-gray-50">
            {listLoading ? (
              <Spinner />
            ) : listError ? (
              <div className="text-center py-16 text-red-500 text-sm px-4">{listError}</div>
            ) : conversations.length === 0 ? (
              <Empty icon={MessageSquare} text="لا توجد محادثات" />
            ) : (
              conversations.map(c => (
                <button
                  key={c.id}
                  onClick={() => openConversation(c.id)}
                  className={`w-full text-right p-3.5 hover:bg-gray-50/70 transition flex gap-3 ${
                    c.id === activeId ? 'bg-[#2AB5CE]/10' : ''
                  }`}
                >
                  <Avatar name={c.userName} url={c.userImageUrl} />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <p className="font-semibold text-gray-800 text-sm truncate">
                        {c.userName || `#${c.userId}`}
                      </p>
                      <span className="text-[11px] text-gray-400 shrink-0">{shortTime(c.lastMessageAt)}</span>
                    </div>
                    <p className="text-xs text-gray-500 truncate mt-0.5">
                      {c.lastMessageFromAdmin ? 'أنت: ' : ''}{c.lastMessageText || '—'}
                    </p>
                    <div className="flex items-center gap-1.5 mt-1.5">
                      {(c.userRoles ?? []).map(r => (
                        <span key={r} className="px-1.5 py-0.5 rounded bg-gray-100 text-gray-500 text-[10px]">
                          {roleLabels[r] ?? r}
                        </span>
                      ))}
                      {c.status === 'Closed' && (
                        <span className="px-1.5 py-0.5 rounded bg-gray-100 text-gray-400 text-[10px]">مغلقة</span>
                      )}
                      {c.unreadForAdmin > 0 && (
                        <span className="mr-auto min-w-5 h-5 px-1.5 rounded-full bg-[#2AB5CE] text-white text-[11px] font-bold flex items-center justify-center">
                          {c.unreadForAdmin}
                        </span>
                      )}
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>

        {/* ── Thread ─────────────────────────────────────────────────────── */}
        <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 flex flex-col overflow-hidden">
          {!active ? (
            <div className="flex-1 flex items-center justify-center text-gray-400">
              <div className="text-center">
                <MessageSquare className="w-12 h-12 mx-auto mb-3 opacity-30" />
                <p className="text-sm">اختر محادثة لعرضها</p>
              </div>
            </div>
          ) : (
            <>
              <div className="p-4 border-b border-gray-100 flex items-center gap-3">
                <Avatar name={active.userName} url={active.userImageUrl} />
                <div className="min-w-0 flex-1">
                  <p className="font-semibold text-gray-800 text-sm truncate">
                    {active.userName || `#${active.userId}`}
                  </p>
                  <p className="text-xs text-gray-400">
                    {peerTyping ? 'يكتب الآن…' : active.userPhone || '—'}
                  </p>
                </div>
                {canReply && (
                  <button
                    onClick={toggleStatus}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium border border-gray-200 text-gray-600 hover:bg-gray-50 transition"
                  >
                    {active.status === 'Closed'
                      ? <><Unlock className="w-3.5 h-3.5" /> إعادة فتح</>
                      : <><Lock className="w-3.5 h-3.5" /> إغلاق</>}
                  </button>
                )}
              </div>

              <div className="flex-1 overflow-y-auto p-4 space-y-2 bg-gray-50/40">
                {threadLoading ? (
                  <Spinner />
                ) : (
                  <>
                    {hasMore && (
                      <button
                        onClick={loadOlder}
                        className="mx-auto block px-3 py-1.5 rounded-lg bg-white border border-gray-200 text-xs text-gray-500 hover:bg-gray-50"
                      >
                        عرض الرسائل الأقدم
                      </button>
                    )}
                    {messages.map(m => <Bubble key={m.id} msg={m} />)}
                    {peerTyping && (
                      <div className="text-xs text-gray-400 px-1">يكتب الآن…</div>
                    )}
                    <div ref={bottomRef} />
                  </>
                )}
              </div>

              {canReply ? (
                <form onSubmit={send} className="p-3 border-t border-gray-100 flex items-center gap-2">
                  <input
                    value={draft}
                    onChange={(e) => {
                      setDraft(e.target.value);
                      sendTyping(active.id, active.userId);
                    }}
                    placeholder="اكتب ردك…"
                    maxLength={4000}
                    className={inputCls}
                  />
                  <button
                    type="submit"
                    disabled={!draft.trim() || sending}
                    className="shrink-0 w-11 h-11 rounded-xl bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:opacity-40 text-white flex items-center justify-center transition"
                  >
                    <Send className="w-4 h-4" />
                  </button>
                </form>
              ) : (
                <div className="p-3 border-t border-gray-100 text-center text-xs text-gray-400">
                  لا تملك صلاحية الرد على المحادثات
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}

function Avatar({ name, url }) {
  if (url) {
    return <img src={url} alt="" className="w-10 h-10 rounded-full object-cover shrink-0" />;
  }
  const initial = (name ?? '').trim().charAt(0) || '؟';
  return (
    <div className="w-10 h-10 rounded-full bg-[#2AB5CE]/15 text-[#2AB5CE] font-bold flex items-center justify-center shrink-0">
      {initial}
    </div>
  );
}

function Bubble({ msg }) {
  const mine = msg.fromAdmin;
  return (
    <div className={`flex ${mine ? 'justify-start' : 'justify-end'}`}>
      <div
        className={`max-w-[75%] rounded-2xl px-3.5 py-2 text-sm ${
          mine ? 'bg-[#2AB5CE] text-white' : 'bg-white border border-gray-100 text-gray-700'
        }`}
      >
        <p className="whitespace-pre-wrap break-words">{msg.body}</p>
        <div className={`flex items-center gap-1 mt-1 text-[10px] ${mine ? 'text-white/70' : 'text-gray-400'}`}>
          <span>{shortTime(msg.sentAt)}</span>
          {mine && (msg.readAt ? <CheckCheck className="w-3 h-3" /> : <Check className="w-3 h-3" />)}
        </div>
      </div>
    </div>
  );
}
