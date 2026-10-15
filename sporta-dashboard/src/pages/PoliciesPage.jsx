import { useState, useEffect, useCallback, useMemo } from 'react';
import { Save, ScrollText, Eye, Pencil, Check } from 'lucide-react';
import { policiesApi } from '../api/policiesApi';
import PageHeader from '../components/PageHeader';
import Markdown from '../components/Markdown';

// Friendly Arabic tab labels + accent per policy key.
const META = {
  terms_conditions: { label: 'الشروط والأحكام', hint: 'Terms & Conditions' },
  privacy_policy: { label: 'سياسة الخصوصية', hint: 'Privacy Policy' },
  refund_policy: { label: 'سياسة الاسترجاع', hint: 'Refund Policy' },
};

const MD_HELP =
  'صيغة الكتابة (Markdown): ابدأ عنوان القسم بـ ## ، والعنوان الفرعي بـ ### ، والنقطة بـ - ، واترك سطراً فارغاً بين الفقرات.';

export default function PoliciesPage() {
  const [policies, setPolicies] = useState([]);
  const [drafts, setDrafts] = useState({}); // key -> { valueAr, valueEn }
  const [activeKey, setActiveKey] = useState(null);
  const [lang, setLang] = useState('ar'); // 'ar' | 'en'
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [saving, setSaving] = useState(false);
  const [savedKey, setSavedKey] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const items = await policiesApi.list();
      setPolicies(items);
      setDrafts(
        Object.fromEntries(
          items.map((s) => [s.key, { valueAr: s.valueAr ?? '', valueEn: s.valueEn ?? '' }]),
        ),
      );
      setActiveKey((prev) => prev ?? items[0]?.key ?? null);
    } catch (err) {
      setError(err?.response?.data?.messageAr || 'تعذّر تحميل السياسات');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const active = useMemo(
    () => policies.find((p) => p.key === activeKey) ?? null,
    [policies, activeKey],
  );
  const draft = drafts[activeKey] ?? { valueAr: '', valueEn: '' };
  const field = lang === 'ar' ? 'valueAr' : 'valueEn';

  const dirty =
    active &&
    (draft.valueAr !== (active.valueAr ?? '') || draft.valueEn !== (active.valueEn ?? ''));

  const setDraftValue = (value) =>
    setDrafts((d) => ({ ...d, [activeKey]: { ...d[activeKey], [field]: value } }));

  const save = async () => {
    if (!active || saving || !dirty) return;
    setSaving(true);
    setError(null);
    try {
      await policiesApi.update(active, draft);
      setPolicies((ps) =>
        ps.map((p) =>
          p.key === activeKey ? { ...p, valueAr: draft.valueAr, valueEn: draft.valueEn } : p,
        ),
      );
      setSavedKey(activeKey);
      setTimeout(() => setSavedKey(null), 2500);
    } catch (err) {
      setError(err?.response?.data?.messageAr || 'تعذّر حفظ التعديلات');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <PageHeader
        title="السياسات"
        subtitle="تحرير الشروط والأحكام وسياسة الخصوصية وسياسة الاسترجاع — عربي وإنجليزي — كما تظهر داخل التطبيق."
      />

      {loading ? (
        <div className="flex justify-center py-20">
          <div className="w-10 h-10 border-4 border-green-200 border-t-[#2AB5CE] rounded-full animate-spin" />
        </div>
      ) : error && !policies.length ? (
        <div className="text-center py-16 text-red-500 text-sm">{error}</div>
      ) : (
        <>
          {/* Policy tabs */}
          <div className="flex flex-wrap gap-2 mb-5">
            {policies.map((p) => {
              const meta = META[p.key] ?? { label: p.nameAr, hint: p.nameEn };
              const isActive = p.key === activeKey;
              return (
                <button
                  key={p.key}
                  onClick={() => setActiveKey(p.key)}
                  className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium transition
                    ${isActive
                      ? 'bg-[#0A2540] text-white shadow'
                      : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
                    }`}
                >
                  <ScrollText className="w-4 h-4" />
                  <span>{meta.label}</span>
                  {savedKey === p.key && <Check className="w-4 h-4 text-green-400" />}
                </button>
              );
            })}
          </div>

          {active && (
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
              {/* Toolbar: language toggle + save */}
              <div className="flex flex-wrap items-center justify-between gap-3 px-5 py-4 border-b border-gray-100 bg-gray-50/60">
                <div className="inline-flex rounded-xl border border-gray-200 bg-white p-1">
                  {[
                    { id: 'ar', label: 'عربي' },
                    { id: 'en', label: 'English' },
                  ].map((l) => (
                    <button
                      key={l.id}
                      onClick={() => setLang(l.id)}
                      className={`px-4 py-1.5 rounded-lg text-sm font-medium transition
                        ${lang === l.id ? 'bg-[#2AB5CE] text-white' : 'text-gray-500 hover:text-gray-700'}`}
                    >
                      {l.label}
                    </button>
                  ))}
                </div>

                <div className="flex items-center gap-3">
                  {savedKey === activeKey && (
                    <span className="flex items-center gap-1 text-sm text-green-600">
                      <Check className="w-4 h-4" /> تم الحفظ
                    </span>
                  )}
                  {error && policies.length > 0 && (
                    <span className="text-sm text-red-500">{error}</span>
                  )}
                  <button
                    onClick={save}
                    disabled={!dirty || saving}
                    className="flex items-center gap-2 px-4 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white rounded-xl text-sm font-medium shadow transition"
                  >
                    <Save className="w-4 h-4" />
                    {saving ? 'جارٍ الحفظ...' : 'حفظ التعديلات'}
                  </button>
                </div>
              </div>

              {/* Editor + live preview */}
              <div className="grid grid-cols-1 lg:grid-cols-2 divide-y lg:divide-y-0 lg:divide-x lg:divide-x-reverse divide-gray-100">
                {/* Editor */}
                <div className="p-5">
                  <div className="flex items-center gap-2 mb-2 text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    <Pencil className="w-3.5 h-3.5" /> المحرّر ({lang === 'ar' ? 'عربي' : 'English'})
                  </div>
                  <textarea
                    dir={lang === 'ar' ? 'rtl' : 'ltr'}
                    value={draft[field]}
                    onChange={(e) => setDraftValue(e.target.value)}
                    spellCheck={false}
                    className="w-full h-[60vh] resize-y px-4 py-3 border border-gray-200 rounded-xl text-sm leading-relaxed font-mono focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50"
                    placeholder="## 1. العنوان\n\nنص الفقرة...\n\n- نقطة\n- نقطة"
                  />
                  <p className="mt-2 text-xs text-gray-400 leading-relaxed">{MD_HELP}</p>
                </div>

                {/* Preview */}
                <div className="p-5 bg-gray-50/40">
                  <div className="flex items-center gap-2 mb-2 text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    <Eye className="w-3.5 h-3.5" /> المعاينة
                  </div>
                  <div className="h-[60vh] overflow-y-auto bg-white border border-gray-200 rounded-xl p-5">
                    <Markdown text={draft[field]} dir={lang === 'ar' ? 'rtl' : 'ltr'} />
                  </div>
                </div>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
