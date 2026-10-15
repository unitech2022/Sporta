import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Wallet, ArrowDownLeft, ArrowUpRight, TrendingUp, Landmark, Clock,
  Search, Eye, RefreshCw, Receipt, CreditCard, FileText,
} from 'lucide-react';
import { financeApi } from '../api/financeApi';
import { adminApi } from '../api/adminApi';
import PageHeader from '../components/PageHeader';
import StatusBadge from '../components/StatusBadge';
import Pagination from '../components/Pagination';
import { LoadingTable, ErrorState } from '../components/ApiState';
import TransactionDetailModal from '../components/finance/TransactionDetailModal';
import WithdrawalModal from '../components/finance/WithdrawalModal';
import {
  TX_TYPE_OPTIONS, TX_STATUS, TX_STATUS_OPTIONS,
  txLabel, money, fmtDateTime, fmtDate, WITHDRAWAL_STATUS,
} from '../components/finance/financeMeta';

const PAGE_SIZE = 15;

const TABS = [
  { key: 'overview',    label: 'نظرة عامة',    icon: TrendingUp },
  { key: 'transactions', label: 'المعاملات',    icon: CreditCard },
  { key: 'withdrawals', label: 'طلبات السحب',   icon: Landmark },
  { key: 'invoices',    label: 'الفواتير',      icon: Receipt },
];

export default function FinancePage() {
  const [tab, setTab] = useState('overview');

  return (
    <div>
      <PageHeader title="المالية" subtitle="التعاملات، طلبات السحب، والإحصاءات المالية للمنصة" />

      {/* Tabs */}
      <div className="flex gap-2 mb-6 flex-wrap">
        {TABS.map(({ key, label, icon: Icon }) => (
          <button key={key} onClick={() => setTab(key)}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium transition ${
              tab === key ? 'bg-[#2AB5CE] text-white shadow' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
            }`}>
            <Icon className="w-4 h-4" /> {label}
          </button>
        ))}
      </div>

      {tab === 'overview'     && <OverviewTab />}
      {tab === 'transactions' && <TransactionsTab />}
      {tab === 'withdrawals'  && <WithdrawalsTab />}
      {tab === 'invoices'     && <InvoicesTab />}
    </div>
  );
}

// ── Overview ────────────────────────────────────────────────────────────────

function StatCard({ label, value, icon: Icon, light, text, hint }) {
  return (
    <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-200">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs text-gray-500 mb-2 font-medium">{label}</p>
          <p className="text-2xl font-bold text-gray-800">{value ?? '—'}</p>
          {hint && <p className="text-xs text-gray-400 mt-1">{hint}</p>}
        </div>
        <div className="p-2.5 rounded-xl" style={{ backgroundColor: light }}>
          <Icon className="w-5 h-5" style={{ color: text }} />
        </div>
      </div>
    </div>
  );
}

function OverviewTab() {
  const [stats, setStats]     = useState(null);
  const [points, setPoints]   = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(null);

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const res = await financeApi.getStats();
      setStats(res.data.data ?? res.data);
      // إجماليات نقاط الولاء — عرض مساند، لا يعطّل بقية الصفحة عند فشله.
      try {
        const p = await adminApi.getPointsStats();
        setPoints(p.data.data ?? p.data);
      } catch { /* ignore */ }
    } catch (err) {
      setError(err?.response?.data?.messageAr || err?.response?.data?.message || 'تعذّر تحميل الإحصاءات');
    } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  if (loading) return <LoadingTable rows={4} cols={4} />;
  if (error)   return <ErrorState message={error} onRetry={load} />;

  const cards = [
    { label: 'إجمالي الوارد', value: money(stats.totalIncoming), icon: ArrowDownLeft, light: '#ECFDF5', text: '#059669', hint: 'شحن المحافظ' },
    { label: 'إجمالي الصادر', value: money(stats.totalOutgoing), icon: ArrowUpRight, light: '#FEF2F2', text: '#DC2626', hint: 'سحوبات مدفوعة' },
    { label: 'صافي التدفق', value: money(stats.netFlow), icon: TrendingUp, light: '#EFF6FF', text: '#2563EB', hint: 'وارد − صادر' },
    { label: 'أرصدة المحافظ', value: money(stats.totalWalletBalance), icon: Wallet, light: '#F5F3FF', text: '#7C3AED', hint: 'المحتجز حالياً' },
    { label: 'سحوبات قيد المراجعة', value: stats.pendingWithdrawalsCount, icon: Clock, light: '#FFF7ED', text: '#EA580C', hint: money(stats.pendingWithdrawalsAmount) },
    { label: 'أرباح المدربين/الملاعب', value: money(stats.totalEarnings), icon: Landmark, light: '#F0FDFA', text: '#0D9488' },
    { label: 'المبالغ المستردة', value: money(stats.totalRefunds), icon: RefreshCw, light: '#FEFCE8', text: '#CA8A04' },
    { label: 'عدد المعاملات', value: Number(stats.transactionCount).toLocaleString('en-US'), icon: CreditCard, light: '#E0F7FA', text: '#2AB5CE' },
    ...(points ? [
      { label: 'نقاط ولاء صادرة', value: Number(points.totalEarned).toLocaleString('en-US'), icon: TrendingUp, light: '#FFFBEB', text: '#D97706', hint: 'إجمالي المكتسب' },
      { label: 'نقاط مستبدلة', value: Number(points.totalRedeemed).toLocaleString('en-US'), icon: RefreshCw, light: '#FFFBEB', text: '#B45309', hint: 'حُوّلت لرصيد محافظ' },
      { label: 'نقاط قائمة بذمة المنصة', value: Number(points.outstandingBalance).toLocaleString('en-US'), icon: Wallet, light: '#FFFBEB', text: '#92400E', hint: 'أرصدة المستخدمين الحالية' },
    ] : []),
  ];

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
        {cards.map((c) => <StatCard key={c.label} {...c} />)}
      </div>

      {/* Breakdown by type */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800">توزيع المبالغ حسب نوع العملية</h3>
        </div>
        {(stats.byType ?? []).length === 0 ? (
          <p className="text-center py-12 text-gray-400 text-sm">لا توجد معاملات بعد</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <th className="text-right px-5 py-3 font-semibold text-gray-600">نوع العملية</th>
                  <th className="text-right px-4 py-3 font-semibold text-gray-600">العدد</th>
                  <th className="text-right px-4 py-3 font-semibold text-gray-600">إجمالي المبلغ</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {stats.byType.map((b) => (
                  <tr key={b.type} className="hover:bg-gray-50/50 transition">
                    <td className="px-5 py-3 text-gray-700">{txLabel(b.type)}</td>
                    <td className="px-4 py-3 text-gray-500">{Number(b.count).toLocaleString('en-US')}</td>
                    <td className="px-4 py-3 font-semibold text-gray-800">{money(b.amount)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Transactions ────────────────────────────────────────────────────────────

function TransactionsTab() {
  const [rows, setRows]       = useState([]);
  const [total, setTotal]     = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(null);
  const [type, setType]       = useState('');
  const [status, setStatus]   = useState('');
  const [search, setSearch]   = useState('');
  const [page, setPage]       = useState(1);
  const [selected, setSelected] = useState(null);

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const params = { page, pageSize: PAGE_SIZE };
      if (type) params.type = type;
      if (status) params.status = status;
      if (search.trim()) params.search = search.trim();
      const res = await financeApi.getTransactions(params);
      const result = res.data.data ?? res.data;
      setRows(result.items ?? []);
      setTotal(result.total ?? 0);
    } catch (err) {
      setError(err?.response?.data?.messageAr || err?.response?.data?.message || 'تعذّر تحميل المعاملات');
    } finally { setLoading(false); }
  }, [page, type, status, search]);

  useEffect(() => { load(); }, [load]);

  const totalPages = Math.ceil(total / PAGE_SIZE);

  return (
    <div>
      <div className="flex flex-col sm:flex-row gap-3 mb-5 flex-wrap">
        <div className="relative flex-1 min-w-52">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            placeholder="بحث باسم المستخدم أو الجوال أو معرّف الدفع..."
            className="w-full pr-9 pl-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white" />
        </div>
        <select value={type}
          onChange={(e) => { setType(e.target.value); setPage(1); }}
          className="px-4 py-2.5 border border-gray-200 rounded-xl text-sm bg-white focus:outline-none focus:ring-2 focus:ring-[#2AB5CE]">
          {TX_TYPE_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
        </select>
        <select value={status}
          onChange={(e) => { setStatus(e.target.value); setPage(1); }}
          className="px-4 py-2.5 border border-gray-200 rounded-xl text-sm bg-white focus:outline-none focus:ring-2 focus:ring-[#2AB5CE]">
          {TX_STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
        </select>
        <button onClick={load} disabled={loading}
          className="flex items-center gap-2 px-4 py-2.5 bg-white border border-gray-200 text-gray-600 hover:bg-gray-50 rounded-xl text-sm font-medium transition disabled:opacity-50">
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} /> تحديث
        </button>
      </div>

      {loading ? <LoadingTable rows={8} cols={8} />
      : error ? <ErrorState message={error} onRetry={load} />
      : rows.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <CreditCard className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>لا توجد معاملات مطابقة</p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <th className="text-right px-5 py-3.5 font-semibold text-gray-600">المرجع</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">المستخدم</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">النوع</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الحالة</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">المبلغ</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">معرّف الدفع</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">التاريخ</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">إجراء</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {rows.map((t) => (
                  <tr key={t.id} className="hover:bg-gray-50/50 transition">
                    <td className="px-5 py-4"><span className="font-mono text-gray-500 text-xs">{t.internalReference}</span></td>
                    <td className="px-4 py-4">
                      <p className="text-gray-700">{t.userName || '-'}</p>
                      <p className="text-xs text-gray-400 font-mono">{t.userPhone}</p>
                    </td>
                    <td className="px-4 py-4 text-gray-600">{txLabel(t.type)}</td>
                    <td className="px-4 py-4">
                      <span className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        (TX_STATUS[t.status] ?? TX_STATUS.completed).cls}`}>
                        {(TX_STATUS[t.status] ?? TX_STATUS.completed).label}
                      </span>
                    </td>
                    {/* A failed attempt moved no money — greyed out and struck
                        through so it never reads as a real debit. */}
                    <td className={`px-4 py-4 font-semibold ${
                      t.status === 'failed'
                        ? 'text-gray-400 line-through'
                        : t.direction === 'in' ? 'text-green-600' : 'text-red-500'}`}>
                      {money(t.amount)}
                    </td>
                    <td className="px-4 py-4">
                      {t.paymentReference
                        ? <span className="font-mono text-xs text-gray-500">{t.paymentReference}</span>
                        : <span className="text-gray-300 text-xs">—</span>}
                    </td>
                    <td className="px-4 py-4 text-gray-500 text-xs">{fmtDateTime(t.createdAt)}</td>
                    <td className="px-4 py-4">
                      <button onClick={() => setSelected(t)}
                        className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition text-xs font-medium">
                        <Eye className="w-3.5 h-3.5" /> تفاصيل
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="px-5 py-4 border-t border-gray-100">
            <Pagination page={page} totalPages={totalPages} onPageChange={setPage} totalItems={total} pageSize={PAGE_SIZE} />
          </div>
        </div>
      )}

      <TransactionDetailModal tx={selected} onClose={() => setSelected(null)} />
    </div>
  );
}

// ── Withdrawals ─────────────────────────────────────────────────────────────

const W_STATUS_OPTIONS = [
  { value: '', label: 'الكل' },
  { value: 'Pending',  label: 'قيد المراجعة' },
  { value: 'Approved', label: 'موافق عليه' },
  { value: 'Rejected', label: 'مرفوض' },
];

function WithdrawalsTab() {
  const [rows, setRows]       = useState([]);
  const [total, setTotal]     = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(null);
  const [status, setStatus]   = useState('');
  const [page, setPage]       = useState(1);
  const [selected, setSelected] = useState(null);
  const [processing, setProcessing] = useState(false);

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const params = { page, pageSize: PAGE_SIZE };
      if (status) params.status = status;
      const res = await financeApi.getWithdrawals(params);
      const result = res.data.data ?? res.data;
      setRows(result.items ?? []);
      setTotal(result.total ?? 0);
    } catch (err) {
      setError(err?.response?.data?.messageAr || err?.response?.data?.message || 'تعذّر تحميل طلبات السحب');
    } finally { setLoading(false); }
  }, [page, status]);

  useEffect(() => { load(); }, [load]);

  const process = async (id, body) => {
    setProcessing(true);
    try {
      await financeApi.processWithdrawal(id, body);
      setSelected(null);
      await load();
    } catch (err) {
      alert(err?.response?.data?.messageAr || err?.response?.data?.message || 'تعذّرت معالجة الطلب');
    } finally { setProcessing(false); }
  };

  const totalPages = Math.ceil(total / PAGE_SIZE);

  return (
    <div>
      <div className="flex gap-2 mb-5 flex-wrap">
        {W_STATUS_OPTIONS.map(({ value, label }) => (
          <button key={value} onClick={() => { setStatus(value); setPage(1); }}
            className={`px-4 py-2.5 rounded-xl text-sm font-medium transition ${
              status === value ? 'bg-[#2AB5CE] text-white shadow' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
            }`}>
            {label}
          </button>
        ))}
      </div>

      {loading ? <LoadingTable rows={6} cols={6} />
      : error ? <ErrorState message={error} onRetry={load} />
      : rows.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <Landmark className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>لا توجد طلبات سحب</p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50">
                  <th className="text-right px-5 py-3.5 font-semibold text-gray-600">رقم الطلب</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">المستخدم</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">المبلغ</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">البنك</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">التاريخ</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الحالة</th>
                  <th className="text-right px-4 py-3.5 font-semibold text-gray-600">إجراء</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {rows.map((w) => {
                  const st = WITHDRAWAL_STATUS[w.status] ?? { label: w.status, badge: 'pending' };
                  return (
                    <tr key={w.id} className="hover:bg-gray-50/50 transition">
                      <td className="px-5 py-4"><span className="font-mono text-gray-500 text-xs">#{w.id}</span></td>
                      <td className="px-4 py-4">
                        <p className="text-gray-700">{w.userName || '-'}</p>
                        <p className="text-xs text-gray-400 font-mono">{w.userPhone}</p>
                      </td>
                      <td className="px-4 py-4 font-semibold text-orange-600">{money(w.amount)}</td>
                      <td className="px-4 py-4 text-gray-600 text-xs">{w.bankName}</td>
                      <td className="px-4 py-4 text-gray-500 text-xs">{fmtDate(w.createdAt)}</td>
                      <td className="px-4 py-4"><StatusBadge status={st.badge} label={st.label} /></td>
                      <td className="px-4 py-4">
                        <button onClick={() => setSelected(w)}
                          className={`flex items-center gap-1 px-3 py-1.5 rounded-lg transition text-xs font-medium ${
                            w.status === 'pending' ? 'bg-green-50 text-green-700 hover:bg-green-100' : 'bg-blue-50 text-blue-600 hover:bg-blue-100'
                          }`}>
                          <Eye className="w-3.5 h-3.5" /> {w.status === 'pending' ? 'مراجعة' : 'تفاصيل'}
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <div className="px-5 py-4 border-t border-gray-100">
            <Pagination page={page} totalPages={totalPages} onPageChange={setPage} totalItems={total} pageSize={PAGE_SIZE} />
          </div>
        </div>
      )}

      <WithdrawalModal request={selected} onClose={() => setSelected(null)} onProcess={process} processing={processing} />
    </div>
  );
}

// ── Invoices (court bookings) ───────────────────────────────────────────────

const INV_STATUS = { Pending: 'pending', Confirmed: 'active', Cancelled: 'inactive', Completed: 'completed' };

function InvoicesTab() {
  const navigate = useNavigate();
  const [rows, setRows]       = useState([]);
  const [total, setTotal]     = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(null);
  const [page, setPage]       = useState(1);

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const res = await adminApi.getBookings({ page, pageSize: PAGE_SIZE });
      const result = res.data.data ?? res.data;
      setRows(result.items ?? []);
      setTotal(result.total ?? 0);
    } catch (err) {
      setError(err?.response?.data?.messageAr || err?.response?.data?.message || 'تعذّر تحميل الفواتير');
    } finally { setLoading(false); }
  }, [page]);

  useEffect(() => { load(); }, [load]);

  const totalPages = Math.ceil(total / PAGE_SIZE);

  if (loading) return <LoadingTable rows={8} cols={6} />;
  if (error)   return <ErrorState message={error} onRetry={load} />;
  if (rows.length === 0) return (
    <div className="text-center py-20 text-gray-400">
      <FileText className="w-12 h-12 mx-auto mb-3 opacity-30" />
      <p>لا توجد فواتير</p>
    </div>
  );

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-100 bg-gray-50">
              <th className="text-right px-5 py-3.5 font-semibold text-gray-600">رقم الفاتورة</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">اللاعب</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الملعب</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">التاريخ</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">المبلغ</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الدفع</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">إجراء</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {rows.map((b) => (
              <tr key={b.id} className="hover:bg-gray-50/50 transition">
                <td className="px-5 py-4"><span className="font-mono text-gray-500 text-xs">#{b.id}</span></td>
                <td className="px-4 py-4 text-gray-700">{b.userName || '-'}</td>
                <td className="px-4 py-4">
                  <p className="font-semibold text-gray-800">{b.courtName || '-'}</p>
                  <p className="text-xs text-gray-400">{b.venueName || ''}</p>
                </td>
                <td className="px-4 py-4 text-gray-500 text-xs">{fmtDate(b.startTime)}</td>
                <td className="px-4 py-4 font-semibold text-green-700">{money(b.totalPrice)}</td>
                <td className="px-4 py-4">
                  <StatusBadge status={b.paidFullAmount ? 'paid' : 'pending'} label={b.paidFullAmount ? 'مدفوع' : 'غير مدفوع'} />
                </td>
                <td className="px-4 py-4">
                  <button onClick={() => navigate(`/invoices/${b.id}`)}
                    className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition text-xs font-medium">
                    <Eye className="w-3.5 h-3.5" /> عرض
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="px-5 py-4 border-t border-gray-100">
        <Pagination page={page} totalPages={totalPages} onPageChange={setPage} totalItems={total} pageSize={PAGE_SIZE} />
      </div>
    </div>
  );
}
