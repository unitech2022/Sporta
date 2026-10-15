import { useState, useEffect, useCallback } from 'react';
import {
  Plus, Edit3, Trash2, Save, X, GripVertical, BarChart3, ListChecks,
} from 'lucide-react';
import { assessmentApi } from '../api/assessmentApi';
import { adminApi } from '../api/adminApi';
import PageHeader from '../components/PageHeader';
import ConfirmModal from '../components/ConfirmModal';

const inputCls =
  'w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50';

export default function AssessmentPage() {
  // الألعاب من الـ API (بدل قائمة ثابتة) — نفس مصدر صفحة "الألعاب".
  const [sports, setSports] = useState([]);
  const [sport, setSport] = useState(null);
  const [tab, setTab] = useState('levels');

  const [levels, setLevels] = useState([]);
  const [questions, setQuestions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [levelModal, setLevelModal] = useState(null); // 'new' | level
  const [questionModal, setQuestionModal] = useState(null);
  const [confirm, setConfirm] = useState(null); // {kind, item}

  useEffect(() => {
    adminApi
      .getSports()
      .then((res) => {
        const list = res.data.data ?? [];
        setSports(list);
        setSport((s) => s ?? list[0]?.key ?? null);
        if (list.length === 0) setLoading(false);
      })
      .catch((err) => {
        setError(
          err?.response?.data?.messageAr ||
            err?.response?.data?.message ||
            'تعذّر تحميل الألعاب',
        );
        setLoading(false);
      });
  }, []);

  const load = useCallback(async () => {
    if (!sport) return;
    setLoading(true);
    setError(null);
    try {
      const [lv, qs] = await Promise.all([
        assessmentApi.getLevels(sport),
        assessmentApi.getQuestions(sport),
      ]);
      setLevels(lv.data.data);
      setQuestions(qs.data.data);
    } catch (err) {
      setError(
        err?.response?.data?.messageAr ||
          err?.response?.data?.message ||
          'تعذّر تحميل البيانات',
      );
    } finally {
      setLoading(false);
    }
  }, [sport]);

  useEffect(() => {
    load();
  }, [load]);

  const saveLevel = async (form) => {
    const body = { ...form, sport };
    if (levelModal === 'new') await assessmentApi.createLevel(body);
    else await assessmentApi.updateLevel(levelModal.id, body);
    setLevelModal(null);
    load();
  };

  const saveQuestion = async (form) => {
    const body = { ...form, sport };
    if (questionModal === 'new') await assessmentApi.createQuestion(body);
    else await assessmentApi.updateQuestion(questionModal.id, body);
    setQuestionModal(null);
    load();
  };

  const handleConfirm = async () => {
    const { kind, item } = confirm;
    if (kind === 'level') await assessmentApi.deleteLevel(item.id);
    else await assessmentApi.deleteQuestion(item.id);
    setConfirm(null);
    load();
  };

  return (
    <div>
      <PageHeader
        title="المستويات وأسئلة التقييم"
        subtitle="تحكّم في مستويات اللاعبين وأسئلة تحديد المستوى لكل لعبة"
        action={
          <button
            onClick={() =>
              tab === 'levels' ? setLevelModal('new') : setQuestionModal('new')
            }
            className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] text-white rounded-xl text-sm font-medium shadow transition"
          >
            <Plus className="w-4 h-4" />
            {tab === 'levels' ? 'مستوى جديد' : 'سؤال جديد'}
          </button>
        }
      />

      {/* Sport selector — من قاعدة البيانات */}
      <div className="flex flex-wrap gap-2 mb-5">
        {sports.map((s) => (
          <button
            key={s.key}
            onClick={() => setSport(s.key)}
            className={`px-4 py-2 rounded-xl text-sm font-medium transition ${
              sport === s.key
                ? 'bg-[#0A2540] text-white shadow'
                : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
            }`}
          >
            {s.name}
            {!s.isActive && <span className="mr-1 text-xs opacity-60">(موقوفة)</span>}
          </button>
        ))}
        {sports.length === 0 && !loading && (
          <p className="text-sm text-gray-400">لا توجد ألعاب — أضف لعبة من صفحة "الألعاب" أولًا</p>
        )}
      </div>

      {/* Tabs */}
      <div className="flex gap-2 mb-5 border-b border-gray-100">
        {[
          ['levels', 'المستويات', BarChart3],
          ['questions', 'الأسئلة', ListChecks],
        ].map(([k, label, Icon]) => (
          <button
            key={k}
            onClick={() => setTab(k)}
            className={`flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition ${
              tab === k
                ? 'border-[#2AB5CE] text-[#2AB5CE]'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <Icon className="w-4 h-4" />
            {label}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex justify-center py-20">
          <div className="w-10 h-10 border-4 border-green-200 border-t-[#2AB5CE] rounded-full animate-spin" />
        </div>
      ) : error ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : tab === 'levels' ? (
        <LevelsTable
          levels={levels}
          onEdit={setLevelModal}
          onDelete={(item) => setConfirm({ kind: 'level', item })}
        />
      ) : (
        <QuestionsList
          questions={questions}
          onEdit={setQuestionModal}
          onDelete={(item) => setConfirm({ kind: 'question', item })}
        />
      )}

      {levelModal && (
        <LevelFormModal
          initial={levelModal === 'new' ? null : levelModal}
          onSave={saveLevel}
          onClose={() => setLevelModal(null)}
        />
      )}
      {questionModal && (
        <QuestionFormModal
          initial={questionModal === 'new' ? null : questionModal}
          onSave={saveQuestion}
          onClose={() => setQuestionModal(null)}
        />
      )}
      <ConfirmModal
        open={!!confirm}
        title={confirm?.kind === 'level' ? 'حذف المستوى' : 'حذف السؤال'}
        message={
          confirm?.kind === 'level'
            ? `هل أنت متأكد من حذف "${confirm?.item?.nameAr}"؟`
            : `هل أنت متأكد من حذف هذا السؤال؟`
        }
        onConfirm={handleConfirm}
        onCancel={() => setConfirm(null)}
      />
    </div>
  );
}

// ── Levels ────────────────────────────────────────────────────────────────────

function LevelsTable({ levels, onEdit, onDelete }) {
  if (levels.length === 0) {
    return (
      <div className="text-center py-20 text-gray-400">
        <BarChart3 className="w-12 h-12 mx-auto mb-3 opacity-30" />
        <p>لا توجد مستويات لهذه اللعبة بعد</p>
      </div>
    );
  }
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-100 bg-gray-50">
              <th className="text-right px-5 py-3.5 font-semibold text-gray-600">الترتيب</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الاسم</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">عتبة الدرجة</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الحالة</th>
              <th className="text-right px-4 py-3.5 font-semibold text-gray-600">الإجراءات</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {levels.map((l) => (
              <tr key={l.id} className="hover:bg-gray-50/50 transition">
                <td className="px-5 py-4">
                  <span className="inline-flex w-8 h-8 items-center justify-center rounded-lg bg-[#2AB5CE]/10 text-[#2AB5CE] font-bold">
                    {l.sortOrder}
                  </span>
                </td>
                <td className="px-4 py-4">
                  <p className="font-semibold text-gray-800">{l.nameAr}</p>
                  <p className="text-xs text-gray-400">{l.nameEn}</p>
                </td>
                <td className="px-4 py-4 text-gray-600">{l.minScore}</td>
                <td className="px-4 py-4">
                  <span className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-medium ${l.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                    {l.isActive ? 'مفعّل' : 'معطّل'}
                  </span>
                </td>
                <td className="px-4 py-4">
                  <RowActions onEdit={() => onEdit(l)} onDelete={() => onDelete(l)} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function LevelFormModal({ initial, onSave, onClose }) {
  const [form, setForm] = useState(
    initial
      ? {
          nameAr: initial.nameAr,
          nameEn: initial.nameEn,
          descriptionAr: initial.descriptionAr ?? '',
          descriptionEn: initial.descriptionEn ?? '',
          minScore: initial.minScore,
          sortOrder: initial.sortOrder,
          isActive: initial.isActive,
        }
      : {
          nameAr: '', nameEn: '', descriptionAr: '', descriptionEn: '',
          minScore: 0, sortOrder: 1, isActive: true,
        },
  );
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);
  const valid = form.nameAr.trim() && form.nameEn.trim();

  const submit = async () => {
    if (!valid || saving) return;
    setSaving(true);
    setErr(null);
    try {
      await onSave({
        ...form,
        minScore: Number(form.minScore),
        sortOrder: Number(form.sortOrder),
      });
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ');
      setSaving(false);
    }
  };

  return (
    <ModalShell title={initial ? 'تعديل المستوى' : 'مستوى جديد'} onClose={onClose}>
      <div className="p-6 space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <Field label="الاسم (عربي)">
            <input className={inputCls} value={form.nameAr}
              onChange={(e) => setForm((f) => ({ ...f, nameAr: e.target.value }))} placeholder="متقدم" />
          </Field>
          <Field label="الاسم (إنجليزي)">
            <input className={inputCls} value={form.nameEn}
              onChange={(e) => setForm((f) => ({ ...f, nameEn: e.target.value }))} placeholder="Advanced" />
          </Field>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <Field label="عتبة الدرجة (Min Score)">
            <input type="number" className={inputCls} value={form.minScore}
              onChange={(e) => setForm((f) => ({ ...f, minScore: e.target.value }))} />
          </Field>
          <Field label="الترتيب">
            <input type="number" className={inputCls} value={form.sortOrder}
              onChange={(e) => setForm((f) => ({ ...f, sortOrder: e.target.value }))} />
          </Field>
        </div>
        <label className="flex items-center gap-2 cursor-pointer">
          <input type="checkbox" checked={form.isActive}
            onChange={(e) => setForm((f) => ({ ...f, isActive: e.target.checked }))}
            className="w-4 h-4 accent-[#2AB5CE]" />
          <span className="text-sm text-gray-700">مفعّل</span>
        </label>
        {err && <p className="text-sm text-red-500">{err}</p>}
      </div>
      <ModalFooter saving={saving} valid={valid} onClose={onClose} onSubmit={submit} edit={!!initial} />
    </ModalShell>
  );
}

// ── Questions ─────────────────────────────────────────────────────────────────

function QuestionsList({ questions, onEdit, onDelete }) {
  if (questions.length === 0) {
    return (
      <div className="text-center py-20 text-gray-400">
        <ListChecks className="w-12 h-12 mx-auto mb-3 opacity-30" />
        <p>لا توجد أسئلة لهذه اللعبة بعد</p>
      </div>
    );
  }
  return (
    <div className="space-y-3">
      {questions.map((q, i) => (
        <div key={q.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
          <div className="flex items-start justify-between gap-4">
            <div className="min-w-0">
              <p className="font-semibold text-gray-800">
                {i + 1}. {q.textAr}
                {!q.isActive && (
                  <span className="mr-2 text-xs text-gray-400">(معطّل)</span>
                )}
              </p>
              <p className="text-xs text-gray-400 mt-0.5">{q.textEn}</p>
            </div>
            <RowActions onEdit={() => onEdit(q)} onDelete={() => onDelete(q)} />
          </div>
          <div className="flex flex-wrap gap-2 mt-3">
            {q.options.map((o) => (
              <span key={o.id ?? o.textAr}
                className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-gray-50 border border-gray-100 text-xs text-gray-600">
                {o.textAr}
                <span className="font-bold text-[#2AB5CE]">{o.score}</span>
              </span>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function QuestionFormModal({ initial, onSave, onClose }) {
  const [form, setForm] = useState(
    initial
      ? {
          textAr: initial.textAr,
          textEn: initial.textEn,
          sortOrder: initial.sortOrder,
          isActive: initial.isActive,
          options: initial.options.map((o) => ({
            textAr: o.textAr, textEn: o.textEn, score: o.score,
          })),
        }
      : {
          textAr: '', textEn: '', sortOrder: 1, isActive: true,
          options: [
            { textAr: '', textEn: '', score: 0 },
            { textAr: '', textEn: '', score: 1 },
          ],
        },
  );
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState(null);

  const valid =
    form.textAr.trim() &&
    form.textEn.trim() &&
    form.options.length >= 2 &&
    form.options.every((o) => o.textAr.trim() && o.textEn.trim());

  const setOption = (i, key, value) =>
    setForm((f) => ({
      ...f,
      options: f.options.map((o, j) => (j === i ? { ...o, [key]: value } : o)),
    }));

  const addOption = () =>
    setForm((f) => ({ ...f, options: [...f.options, { textAr: '', textEn: '', score: 0 }] }));

  const removeOption = (i) =>
    setForm((f) =>
      f.options.length <= 2
        ? f
        : { ...f, options: f.options.filter((_, j) => j !== i) },
    );

  const submit = async () => {
    if (!valid || saving) return;
    setSaving(true);
    setErr(null);
    try {
      await onSave({
        textAr: form.textAr,
        textEn: form.textEn,
        sortOrder: Number(form.sortOrder),
        isActive: form.isActive,
        options: form.options.map((o) => ({ ...o, score: Number(o.score) })),
      });
    } catch (e) {
      setErr(e?.response?.data?.messageAr || 'تعذّر الحفظ');
      setSaving(false);
    }
  };

  return (
    <ModalShell title={initial ? 'تعديل السؤال' : 'سؤال جديد'} onClose={onClose} wide>
      <div className="p-6 space-y-4 max-h-[65vh] overflow-y-auto">
        <Field label="نص السؤال (عربي)">
          <input className={inputCls} value={form.textAr}
            onChange={(e) => setForm((f) => ({ ...f, textAr: e.target.value }))} />
        </Field>
        <Field label="نص السؤال (إنجليزي)">
          <input className={inputCls} value={form.textEn}
            onChange={(e) => setForm((f) => ({ ...f, textEn: e.target.value }))} />
        </Field>
        <div className="grid grid-cols-2 gap-4">
          <Field label="الترتيب">
            <input type="number" className={inputCls} value={form.sortOrder}
              onChange={(e) => setForm((f) => ({ ...f, sortOrder: e.target.value }))} />
          </Field>
          <label className="flex items-center gap-2 cursor-pointer mt-7">
            <input type="checkbox" checked={form.isActive}
              onChange={(e) => setForm((f) => ({ ...f, isActive: e.target.checked }))}
              className="w-4 h-4 accent-[#2AB5CE]" />
            <span className="text-sm text-gray-700">مفعّل</span>
          </label>
        </div>

        <div className="flex items-center justify-between pt-2">
          <p className="font-semibold text-gray-800 text-sm">الخيارات والدرجات</p>
          <button onClick={addOption}
            className="flex items-center gap-1 text-sm text-[#2AB5CE] hover:underline">
            <Plus className="w-4 h-4" /> إضافة خيار
          </button>
        </div>
        {form.options.map((o, i) => (
          <div key={i} className="rounded-xl border border-gray-100 p-3 bg-gray-50/50">
            <div className="flex items-center gap-2 mb-2 text-xs text-gray-500">
              <GripVertical className="w-4 h-4" />
              خيار {i + 1}
              {form.options.length > 2 && (
                <button onClick={() => removeOption(i)} className="mr-auto text-red-400 hover:text-red-600">
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-[1fr_1fr_90px] gap-2">
              <input className={inputCls} placeholder="النص (عربي)" value={o.textAr}
                onChange={(e) => setOption(i, 'textAr', e.target.value)} />
              <input className={inputCls} placeholder="Text (English)" value={o.textEn}
                onChange={(e) => setOption(i, 'textEn', e.target.value)} />
              <input type="number" className={inputCls} placeholder="درجة" value={o.score}
                onChange={(e) => setOption(i, 'score', e.target.value)} />
            </div>
          </div>
        ))}
        {err && <p className="text-sm text-red-500">{err}</p>}
      </div>
      <ModalFooter saving={saving} valid={valid} onClose={onClose} onSubmit={submit} edit={!!initial} />
    </ModalShell>
  );
}

// ── Shared bits ───────────────────────────────────────────────────────────────

function RowActions({ onEdit, onDelete }) {
  return (
    <div className="flex items-center gap-2 shrink-0">
      <button onClick={onEdit}
        className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-gray-50 text-gray-600 hover:bg-gray-100 transition text-xs font-medium">
        <Edit3 className="w-3.5 h-3.5" /> تعديل
      </button>
      <button onClick={onDelete}
        className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition text-xs font-medium">
        <Trash2 className="w-3.5 h-3.5" /> حذف
      </button>
    </div>
  );
}

function ModalShell({ title, onClose, wide, children }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className={`bg-white rounded-2xl shadow-2xl w-full ${wide ? 'max-w-lg' : 'max-w-md'}`}>
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{title}</h3>
          <button onClick={onClose}
            className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

function ModalFooter({ saving, valid, onClose, onSubmit, edit }) {
  return (
    <div className="flex gap-3 px-6 py-4 border-t border-gray-100">
      <button onClick={onClose}
        className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">
        إلغاء
      </button>
      <button onClick={onSubmit} disabled={!valid || saving}
        className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2">
        <Save className="w-4 h-4" />
        {saving ? 'جارٍ الحفظ...' : edit ? 'حفظ التعديلات' : 'إضافة'}
      </button>
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
