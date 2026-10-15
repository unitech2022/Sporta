import { useState } from 'react';
import { Bell, Send, X, Users, User, Save, Trash2 } from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { useAuth } from '../context/AuthContext';
import { useApi } from '../hooks/useApi';
import PageHeader from '../components/PageHeader';
import Pagination from '../components/Pagination';
import { Spinner, Empty } from '../components/TableBits';

const PAGE_SIZE = 20;
const inputCls =
  'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

function timeAgo(iso) {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '';
  return d.toLocaleString('ar', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
}

export default function NotificationsPage() {
  const { can } = useAuth();
  const canDelete = can('notifications.delete');
  const [page, setPage] = useState(1);
  const [compose, setCompose] = useState(false);
  const [selected, setSelected] = useState(() => new Set());
  // الإشعارات المطلوب حذفها (بانتظار التأكيد) — null = لا حوار.
  const [pendingDelete, setPendingDelete] = useState(null);
  const { data, loading, error, refetch } = useApi(
    () => adminApi.getNotifications({ page, pageSize: PAGE_SIZE }), [page]);

  const items = data?.items ?? [];
  const total = data?.total ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const allOnPage = items.length > 0 && items.every((n) => selected.has(n.id));

  const toggle = (id) => setSelected((s) => {
    const next = new Set(s);
    if (next.has(id)) next.delete(id); else next.add(id);
    return next;
  });
  const toggleAll = () => setSelected((s) => {
    const next = new Set(s);
    items.forEach((n) => (allOnPage ? next.delete(n.id) : next.add(n.id)));
    return next;
  });
  const changePage = (p) => { setSelected(new Set()); setPage(p); };

  const onDeleted = () => {
    setPendingDelete(null);
    setSelected(new Set());
    // آخر صفحة قد تفرغ بعد الحذف — نعود لما قبلها.
    if (page > 1 && items.length > 0 && items.every((n) => pendingDelete?.some((d) => d.id === n.id))) {
      setPage(page - 1);
    } else {
      refetch();
    }
  };

  return (
    <div>
      <PageHeader
        title="الإشعارات"
        subtitle={`${total} إشعار مُرسل (البث العام يُحسب مرة واحدة)`}
        action={
          <button onClick={() => setCompose(true)}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
            <Send className="w-4 h-4" /> إرسال إشعار
          </button>
        }
      />

      {loading ? (
        <Spinner />
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : items.length === 0 ? (
        <Empty icon={Bell} text="لا توجد إشعارات" />
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          {canDelete && (
            <div className="flex items-center justify-between gap-3 px-4 py-3 border-b border-gray-100 bg-gray-50/60">
              <label className="flex items-center gap-2 text-sm text-gray-600 cursor-pointer select-none">
                <input type="checkbox" checked={allOnPage} onChange={toggleAll}
                  className="w-4 h-4 accent-[#2AB5CE]" />
                تحديد الكل في هذه الصفحة
              </label>
              <button
                disabled={selected.size === 0}
                onClick={() => setPendingDelete(items.filter((n) => selected.has(n.id)))}
                className="flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-medium transition bg-red-50 text-red-600 hover:bg-red-100 disabled:bg-gray-100 disabled:text-gray-400">
                <Trash2 className="w-4 h-4" />
                {selected.size > 0 ? `حذف المحدد (${selected.size})` : 'حذف المحدد'}
              </button>
            </div>
          )}
          <div className="divide-y divide-gray-50">
            {items.map((n) => (
              <div key={n.id} className={`flex items-start gap-3 p-4 hover:bg-gray-50/50 ${selected.has(n.id) ? 'bg-[#2AB5CE]/5' : ''}`}>
                {canDelete && (
                  <input type="checkbox" checked={selected.has(n.id)} onChange={() => toggle(n.id)}
                    className="w-4 h-4 mt-2.5 accent-[#2AB5CE] shrink-0 cursor-pointer" />
                )}
                <div className={`w-9 h-9 rounded-full flex items-center justify-center shrink-0 ${n.isRead ? 'bg-gray-100 text-gray-400' : 'bg-[#2AB5CE]/15 text-[#2AB5CE]'}`}>
                  <Bell className="w-4 h-4" />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <p className="font-semibold text-gray-800 text-sm truncate">{n.title}</p>
                    <span className="text-xs text-gray-400 shrink-0">{timeAgo(n.createdAt)}</span>
                  </div>
                  <p className="text-sm text-gray-600 mt-0.5">{n.body}</p>
                  <p className="text-xs text-gray-400 mt-1">
                    {n.isBroadcast
                      ? `إلى: الجميع · ${n.recipientCount} مستخدم · قرأه ${n.readCount}`
                      : `إلى: ${n.userName || `#${n.userId}`}`}
                  </p>
                </div>
                {canDelete && (
                  <button onClick={() => setPendingDelete([n])} title="حذف"
                    className="w-8 h-8 flex items-center justify-center rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 shrink-0 transition">
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            ))}
          </div>
          <div className="px-5 py-4 border-t border-gray-100">
            <Pagination page={page} totalPages={totalPages} onPageChange={changePage} totalItems={total} pageSize={PAGE_SIZE} />
          </div>
        </div>
      )}

      {compose && (
        <ComposeModal onClose={() => setCompose(false)} onSent={() => { setCompose(false); setPage(1); refetch(); }} />
      )}
      {pendingDelete && (
        <DeleteModal items={pendingDelete} onClose={() => setPendingDelete(null)} onDeleted={onDeleted} />
      )}
    </div>
  );
}

/** تأكيد الحذف. البث العام سطر واحد يمثّل نسخ كل المستخدمين، فيُحذف منهم جميعاً. */
function DeleteModal({ items, onClose, onDeleted }) {
  const broadcastRecipients = items
    .filter((n) => n.isBroadcast)
    .reduce((sum, n) => sum + (n.recipientCount || 0), 0);
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);

  const submit = async () => {
    setSaving(true); setErr(null);
    try {
      await adminApi.deleteNotifications({
        ids: items.map((n) => n.id),
        wholeBroadcast: broadcastRecipients > 0,
      });
      onDeleted();
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحذف');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6">
        <div className="w-12 h-12 rounded-full bg-red-50 text-red-600 flex items-center justify-center mx-auto mb-3">
          <Trash2 className="w-5 h-5" />
        </div>
        <h3 className="font-bold text-gray-800 text-lg text-center">
          {items.length === 1 ? 'حذف الإشعار؟' : `حذف ${items.length} إشعارات؟`}
        </h3>
        <p className="text-sm text-gray-500 text-center mt-1">
          يختفي من قائمة إشعارات المستخدم في التطبيق، ولا يمكن التراجع.
        </p>
        {broadcastRecipients > 0 && (
          <p className="mt-4 p-3 rounded-xl bg-amber-50 text-sm text-amber-800 text-center">
            إشعار عام — سيُحذف من جميع مستلميه ({broadcastRecipients} مستخدم)
          </p>
        )}
        {err && <p className="text-sm text-red-500 mt-3 text-center">{err}</p>}
        <div className="flex gap-3 mt-5">
          <button type="button" onClick={onClose}
            className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">إلغاء</button>
          <button type="button" onClick={submit} disabled={saving}
            className="flex-1 py-2.5 bg-red-600 hover:bg-red-700 disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm">
            {saving ? 'جارٍ الحذف...' : 'حذف'}
          </button>
        </div>
      </div>
    </div>
  );
}

function ComposeModal({ onClose, onSent }) {
  const [mode, setMode] = useState('broadcast'); // 'broadcast' | 'user'
  const [form, setForm] = useState({ userId: '', title: '', body: '' });
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);

  const valid = form.title.trim() && form.body.trim() &&
    (mode === 'broadcast' || String(form.userId).trim());

  const submit = async (e) => {
    e.preventDefault();
    if (!valid || saving) return;
    setSaving(true); setErr(null);
    try {
      if (mode === 'broadcast') {
        await adminApi.broadcast({ title: form.title, body: form.body });
      } else {
        await adminApi.sendToUser({ userId: Number(form.userId), title: form.title, body: form.body });
      }
      onSent();
    } catch (e2) {
      setErr(e2?.response?.data?.messageAr || 'تعذّر الإرسال');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">إرسال إشعار</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        <form onSubmit={submit} className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-2">
            {[['broadcast', 'للجميع', Users], ['user', 'لمستخدم محدد', User]].map(([v, l, Icon]) => (
              <button type="button" key={v} onClick={() => setMode(v)}
                className={`flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-medium border transition ${mode === v ? 'bg-[#2AB5CE] text-white border-[#2AB5CE]' : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'}`}>
                <Icon className="w-4 h-4" /> {l}
              </button>
            ))}
          </div>
          {mode === 'user' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">رقم المستخدم (ID)</label>
              <input type="number" className={inputCls} value={form.userId}
                onChange={(e) => setForm((f) => ({ ...f, userId: e.target.value }))} placeholder="مثال: 9" />
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">العنوان</label>
            <input className={inputCls} value={form.title}
              onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))} />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">النص</label>
            <textarea rows={3} className={`${inputCls} resize-none`} value={form.body}
              onChange={(e) => setForm((f) => ({ ...f, body: e.target.value }))} />
          </div>
          {err && <p className="text-sm text-red-500">{err}</p>}
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose}
              className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">إلغاء</button>
            <button type="submit" disabled={!valid || saving}
              className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
              <Save className="w-4 h-4" /> {saving ? 'جارٍ الإرسال...' : 'إرسال'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
