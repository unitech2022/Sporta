import { useState, useEffect, useCallback } from 'react';
import {
  Plus, Edit3, Trash2, Save, X, Trophy, Star, TrendingUp, BarChart3, Check,
} from 'lucide-react';
import { adminApi } from '../api/adminApi';
import { settingsApi } from '../api/settingsApi';
import PageHeader from '../components/PageHeader';
import ConfirmModal from '../components/ConfirmModal';
import { Spinner } from '../components/TableBits';

const inputCls =
  'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

// قيم النقاط تعيش في SystemSettings (نفس المفاتيح التي يقرأها الخادم في
// PointsService). الصفحة تعرض المجموعتين وتحفظ كل مفتاح على حدة.
const REWARD_KEYS = [
  ['reward_points_booking', 'حجز ملعب'],
  ['reward_points_coach_session', 'حجز تدريب'],
  ['reward_points_match_created', 'إنشاء مباراة'],
  ['reward_points_americano', 'تنظيم أمريكانو'],
  ['reward_points_tournament', 'تنظيم بطولة'],
  ['reward_points_invite_friend', 'دعوة صديق للتطبيق'],
  ['reward_points_rate_court', 'تقييم ملعب'],
  ['reward_points_rate_coach', 'تقييم مدرب'],
  // خصم لا كسب: يُطرح من رصيد المكافآت عند كل انسحاب (بسقف الرصيد).
  ['points_withdrawal_penalty', 'خصم: الانسحاب من مباراة/أمريكانو/بطولة'],
];
const REDEEM_KEYS = [
  ['points_redeem_per_riyal', 'نقاط مقابل ريال واحد عند الاستبدال'],
  ['points_min_redeem', 'الحد الأدنى لاستبدال النقاط'],
];
const LEVEL_KEYS = [
  ['level_points_win_same', 'فوز على خصم بنفس المستوى'],
  ['level_points_win_higher_half', 'فوز على خصم أعلى بـ 0.5'],
  ['level_points_win_higher_full', 'فوز على خصم أعلى بـ 1.0+'],
  ['level_points_win_lower_half', 'فوز على خصم أقل بـ 0.5'],
  ['level_points_win_lower_full', 'فوز على خصم أقل بـ 1.0+'],
  ['level_points_loss_same', 'خسارة أمام خصم بنفس المستوى'],
  ['level_points_loss_higher_half', 'خسارة أمام خصم أعلى بـ 0.5'],
  ['level_points_loss_higher_full', 'خسارة أمام خصم أعلى بـ 1.0+'],
  ['level_points_loss_lower_half', 'خسارة أمام خصم أقل بـ 0.5'],
  ['level_points_loss_lower_full', 'خسارة أمام خصم أقل بـ 1.0+'],
];
const COACH_KEY = 'level_points_require_coach';

export default function LevelsPointsPage() {
  const [levels, setLevels] = useState([]);
  const [settings, setSettings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [modal, setModal] = useState(null); // 'new' | level
  const [confirm, setConfirm] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [lv, st] = await Promise.all([
        adminApi.getLevelDefinitions(),
        settingsApi.getAll(),
      ]);
      setLevels(lv.data.data);
      setSettings(st.data.data);
    } catch (err) {
      setError(err?.response?.data?.messageAr || 'تعذّر تحميل البيانات');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const saveLevel = async (form) => {
    if (modal === 'new') await adminApi.createLevelDefinition(form);
    else await adminApi.updateLevelDefinition(modal.id, form);
    setModal(null);
    load();
  };

  const deleteLevel = async () => {
    await adminApi.deleteLevelDefinition(confirm.id);
    setConfirm(null);
    load();
  };

  const byKey = (key) => settings.find((s) => s.key === key);

  const saveSetting = async (key, value) => {
    const s = byKey(key);
    if (!s) throw new Error('missing');
    await settingsApi.update(s.id, {
      key: s.key, nameAr: s.nameAr, nameEn: s.nameEn, type: s.type,
      valueAr: String(value), valueEn: String(value), isSensitive: s.isSensitive,
    });
    setSettings((prev) => prev.map((x) => (x.key === key
      ? { ...x, valueAr: String(value), valueEn: String(value) } : x)));
  };

  return (
    <div>
      <PageHeader
        title="المستويات والنقاط"
        subtitle="سُلَّم المستويات المعروض في التطبيق، وقيم نقاط المكافآت ونقاط المستوى"
        action={
          <button onClick={() => setModal('new')}
            className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition">
            <Plus className="w-4 h-4" /> مستوى جديد
          </button>
        }
      />

      {loading ? (
        <Spinner />
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : (
        <div className="space-y-8">
          <Section icon={BarChart3} title="سُلَّم المستويات" subtitle="القيمة الرقمية والتصنيف والوصف كما تظهر للاعب">
            <LevelsTable levels={levels} onEdit={setModal} onDelete={setConfirm} />
          </Section>

          <div className="grid lg:grid-cols-2 gap-8">
            <Section icon={Star} title="نقاط المكافآت" subtitle="نقاط ثابتة لكل نشاط، تُستبدل برصيد محفظة">
              <PointsGrid rows={REWARD_KEYS} byKey={byKey} onSave={saveSetting} />
              <div className="mt-5 pt-5 border-t border-gray-100">
                <p className="text-sm font-semibold text-gray-700 mb-3">الاستبدال</p>
                <PointsGrid rows={REDEEM_KEYS} byKey={byKey} onSave={saveSetting} />
                <RedeemHint byKey={byKey} />
              </div>
            </Section>

            <Section icon={TrendingUp} title="نقاط المستوى" subtitle="تُحسب من نتيجة المباراة بحسب فرق المستوى (في الزوجي بمتوسط الفريقين)">
              <CoachToggle setting={byKey(COACH_KEY)} onSave={saveSetting} />
              <PointsGrid rows={LEVEL_KEYS} byKey={byKey} onSave={saveSetting} signed />
            </Section>
          </div>
        </div>
      )}

      {modal && (
        <LevelFormModal
          initial={modal === 'new' ? null : modal}
          onSave={saveLevel}
          onClose={() => setModal(null)}
        />
      )}

      <ConfirmModal
        open={!!confirm}
        title="حذف المستوى"
        message={`هل أنت متأكد من حذف "${confirm?.titleAr}" (${confirm?.value})؟`}
        onConfirm={deleteLevel}
        onCancel={() => setConfirm(null)}
      />
    </div>
  );
}

function Section({ icon: Icon, title, subtitle, children }) {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
      <div className="flex items-center gap-3 mb-5">
        <div className="w-10 h-10 bg-[#2AB5CE]/10 rounded-xl flex items-center justify-center shrink-0">
          <Icon className="w-5 h-5 text-[#2AB5CE]" />
        </div>
        <div>
          <h3 className="font-bold text-gray-800">{title}</h3>
          {subtitle && <p className="text-xs text-gray-400 mt-0.5">{subtitle}</p>}
        </div>
      </div>
      {children}
    </div>
  );
}

// ── سُلَّم المستويات ──────────────────────────────────────────────────────────

function LevelsTable({ levels, onEdit, onDelete }) {
  if (levels.length === 0) {
    return (
      <div className="text-center py-16 text-gray-400">
        <Trophy className="w-12 h-12 mx-auto mb-3 opacity-30" />
        <p>لا توجد مستويات بعد</p>
      </div>
    );
  }
  return (
    <div className="overflow-x-auto -mx-6 -mb-6">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-y border-gray-100 bg-gray-50">
            <th className="text-right px-6 py-3.5 font-semibold text-gray-600">المستوى</th>
            <th className="text-right px-4 py-3.5 font-semibold text-gray-600">التصنيف</th>
            <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الوصف</th>
            <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الحالة</th>
            <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الإجراءات</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-50">
          {levels.map((l) => (
            <tr key={l.id} className="hover:bg-gray-50/50 transition">
              <td className="px-6 py-4">
                <span className="inline-flex min-w-12 h-9 px-2 items-center justify-center rounded-lg bg-[#2AB5CE]/10 text-[#2AB5CE] font-bold">
                  {Number(l.value).toFixed(1)}
                </span>
              </td>
              <td className="px-4 py-4">
                <p className="font-semibold text-gray-800">{l.titleAr}</p>
                <p className="text-xs text-gray-400">{l.titleEn}</p>
              </td>
              <td className="px-4 py-4 text-gray-600 max-w-md">{l.descriptionAr}</td>
              <td className="px-4 py-4">
                <span className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-medium ${l.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                  {l.isActive ? 'مفعّل' : 'معطّل'}
                </span>
              </td>
              <td className="px-4 py-4">
                <div className="flex items-center gap-2 shrink-0">
                  <button onClick={() => onEdit(l)}
                    className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-gray-50 text-gray-600 hover:bg-gray-100 transition text-xs font-medium">
                    <Edit3 className="w-3.5 h-3.5" /> تعديل
                  </button>
                  <button onClick={() => onDelete(l)}
                    className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition text-xs font-medium">
                    <Trash2 className="w-3.5 h-3.5" /> حذف
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function LevelFormModal({ initial, onSave, onClose }) {
  const [form, setForm] = useState(
    initial
      ? {
          value: initial.value,
          titleAr: initial.titleAr,
          titleEn: initial.titleEn,
          descriptionAr: initial.descriptionAr ?? '',
          descriptionEn: initial.descriptionEn ?? '',
          sortOrder: initial.sortOrder,
          isActive: initial.isActive,
        }
      : {
          value: 3.0, titleAr: '', titleEn: '', descriptionAr: '', descriptionEn: '',
          sortOrder: 1, isActive: true,
        },
  );
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);
  const valid = form.titleAr.trim() && form.titleEn.trim() && form.value !== '';

  const submit = async () => {
    if (!valid || saving) return;
    setSaving(true);
    setErr(null);
    try {
      await onSave({
        ...form,
        value: Number(form.value),
        sortOrder: Number(form.sortOrder),
      });
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ');
      setSaving(false);
    }
  };

  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{initial ? 'تعديل المستوى' : 'مستوى جديد'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Field label="القيمة الرقمية (خطوة 0.5)">
              <input type="number" step="0.5" min="0" max="10" className={inputCls}
                value={form.value} onChange={set('value')} />
            </Field>
            <Field label="الترتيب">
              <input type="number" className={inputCls} value={form.sortOrder} onChange={set('sortOrder')} />
            </Field>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Field label="التصنيف (عربي)">
              <input className={inputCls} value={form.titleAr} onChange={set('titleAr')} placeholder="متوسط" />
            </Field>
            <Field label="التصنيف (إنجليزي)">
              <input className={inputCls} value={form.titleEn} onChange={set('titleEn')} placeholder="Intermediate" />
            </Field>
          </div>
          <Field label="الوصف (عربي)">
            <textarea rows={2} className={inputCls} value={form.descriptionAr} onChange={set('descriptionAr')} />
          </Field>
          <Field label="الوصف (إنجليزي)">
            <textarea rows={2} className={inputCls} value={form.descriptionEn} onChange={set('descriptionEn')} />
          </Field>
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" checked={form.isActive}
              onChange={(e) => setForm((f) => ({ ...f, isActive: e.target.checked }))}
              className="w-4 h-4 accent-[#2AB5CE]" />
            <span className="text-sm text-gray-700">مفعّل (يظهر في التطبيق)</span>
          </label>
          {err && <p className="text-sm text-red-500">{err}</p>}
        </div>
        <div className="flex gap-3 px-6 py-4 border-t border-gray-100">
          <button onClick={onClose}
            className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">
            إلغاء
          </button>
          <button onClick={submit} disabled={!valid || saving}
            className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
            <Save className="w-4 h-4" />
            {saving ? 'جارٍ الحفظ...' : initial ? 'حفظ التعديلات' : 'إضافة'}
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({ label, children }) {
  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1.5">{label}</label>
      {children}
    </div>
  );
}

// ── قيم النقاط (SystemSettings) ───────────────────────────────────────────────

function PointsGrid({ rows, byKey, onSave, signed = false }) {
  return (
    <div className="divide-y divide-gray-50">
      {rows.map(([key, label]) => (
        <PointsRow key={key} label={label} setting={byKey(key)} onSave={(v) => onSave(key, v)} signed={signed} />
      ))}
    </div>
  );
}

function PointsRow({ label, setting, onSave, signed }) {
  const current = setting?.valueAr ?? '';
  const [value, setValue] = useState(current);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [err, setErr] = useState(null);

  useEffect(() => { setValue(current); }, [current]);

  if (!setting) {
    return (
      <div className="flex items-center justify-between py-2.5 text-sm text-gray-400">
        <span>{label}</span>
        <span className="text-xs">الإعداد غير مزروع بعد — أعد تشغيل الخادم</span>
      </div>
    );
  }

  const dirty = String(value) !== String(current);
  const n = Number(value);
  const positive = signed ? n > 0 : true;
  const negative = signed && n < 0;

  const save = async () => {
    if (!dirty || saving || Number.isNaN(n)) return;
    setSaving(true);
    setErr(null);
    try {
      await onSave(n);
      setSaved(true);
      setTimeout(() => setSaved(false), 1500);
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="flex items-center gap-3 py-2.5">
      <span className="flex-1 text-sm text-gray-700">{label}</span>
      <div className="flex items-center gap-2">
        <input
          type="number"
          value={value}
          onChange={(e) => setValue(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter') save(); }}
          className={`w-24 px-3 py-1.5 border rounded-lg text-sm text-center font-bold focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] ${
            negative ? 'border-red-200 bg-red-50 text-red-600'
              : positive ? 'border-green-200 bg-green-50 text-green-700'
              : 'border-gray-200 bg-gray-50 text-gray-700'}`}
        />
        <button
          onClick={save}
          disabled={!dirty || saving}
          title="حفظ"
          className={`w-8 h-8 flex items-center justify-center rounded-lg text-xs transition ${
            saved ? 'bg-green-100 text-green-600'
              : dirty ? 'bg-[#2AB5CE] text-white hover:bg-[#1E9AB0]'
              : 'bg-gray-100 text-gray-300'}`}
        >
          {saved ? <Check className="w-4 h-4" /> : <Save className="w-4 h-4" />}
        </button>
      </div>
      {err && <span className="text-xs text-red-500">{err}</span>}
    </div>
  );
}

function RedeemHint({ byKey }) {
  const per = Number(byKey('points_redeem_per_riyal')?.valueAr);
  const min = Number(byKey('points_min_redeem')?.valueAr);
  if (!per || !min) return null;
  return (
    <p className="mt-3 text-xs text-gray-400">
      {min} نقطة تتحول إلى {(min / per).toFixed(0)} ريال رصيداً في المحفظة
    </p>
  );
}

function CoachToggle({ setting, onSave }) {
  const [saving, setSaving] = useState(false);
  if (!setting) return null;
  const on = setting.valueAr === 'true';
  const toggle = async () => {
    if (saving) return;
    setSaving(true);
    try { await onSave(on ? 'false' : 'true'); } finally { setSaving(false); }
  };
  return (
    <label className="flex items-center justify-between gap-3 mb-4 p-3 rounded-xl bg-gray-50 border border-gray-100 cursor-pointer">
      <div>
        <p className="text-sm font-medium text-gray-700">اشتراط اعتماد مدرب للمستوى</p>
        <p className="text-xs text-gray-400 mt-0.5">لا تُحتسب نقاط المستوى للاعب لم يعتمد مدرب مستواه</p>
      </div>
      <button onClick={toggle} disabled={saving}
        className={`relative w-11 h-6 rounded-full transition ${on ? 'bg-[#2AB5CE]' : 'bg-gray-300'}`}>
        <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition ${on ? 'right-0.5' : 'right-[22px]'}`} />
      </button>
    </label>
  );
}
