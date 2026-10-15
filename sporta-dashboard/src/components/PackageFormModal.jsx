import { useState, useEffect } from 'react';
import { X, Save, Plus, Trash2 } from 'lucide-react';

export default function PackageFormModal({ open, initial, onSave, onClose }) {
  const empty = { name: '', price: '', period: 'monthly', features: [''], pointsMultiplier: 1, bookingDiscountPercent: 0, welcomePoints: 0, commissionDiscountPercent: 0, commissionPercent: 0 };
  const [form, setForm] = useState(empty);

  useEffect(() => {
    if (initial) {
      setForm({
        name: initial.name, price: initial.price, period: initial.period ?? 'monthly',
        features: [...initial.features],
        pointsMultiplier: initial.pointsMultiplier ?? 1,
        bookingDiscountPercent: initial.bookingDiscountPercent ?? 0,
        welcomePoints: initial.welcomePoints ?? 0,
        commissionDiscountPercent: initial.commissionDiscountPercent ?? 0,
        commissionPercent: initial.commissionPercent ?? 0,
      });
    } else {
      setForm(empty);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [initial, open]);

  if (!open) return null;

  // «بالنسبة» بلا سعر مقدَّم — المطلوب فيه نسبة سبورتا بدل السعر.
  const isCommission = form.period === 'commission';
  const isValid = form.name.trim()
    && (isCommission ? Number(form.commissionPercent) > 0 : !!form.price)
    && form.features.some(f => f.trim());

  const updateFeature = (i, val) => setForm(f => {
    const features = [...f.features];
    features[i] = val;
    return { ...f, features };
  });

  const addFeature = () => setForm(f => ({ ...f, features: [...f.features, ''] }));
  const removeFeature = (i) => setForm(f => ({ ...f, features: f.features.filter((_, fi) => fi !== i) }));

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md max-h-[90vh] flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-gray-800 text-lg">{initial ? 'تعديل الاشتراك' : 'اشتراك جديد'}</h3>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 text-gray-400">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="overflow-y-auto flex-1 p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">اسم الاشتراك</label>
            <input
              value={form.name}
              onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
              placeholder="مثال: اشتراك سنوي"
              className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">
                {isCommission ? 'نسبة سبورتا من كل عملية %' : 'السعر (ر.س)'}
              </label>
              <input
                type="number"
                value={isCommission ? form.commissionPercent : form.price}
                onChange={e => setForm(f => (isCommission
                  ? { ...f, commissionPercent: Number(e.target.value) }
                  : { ...f, price: Number(e.target.value) }))}
                placeholder="0"
                min="0"
                max={isCommission ? 100 : undefined}
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">نوع الاشتراك</label>
              <select
                value={form.period}
                onChange={e => setForm(f => ({ ...f, period: e.target.value }))}
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50"
              >
                <option value="monthly">شهري (30 يوم)</option>
                <option value="yearly">سنوي (365 يوم)</option>
                <option value="commission">بالنسبة (بلا مدة)</option>
              </select>
            </div>
          </div>

          {/* مزايا مهيكلة تُطبَّق فعليًا على المشتركين */}
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">مضاعف النقاط</label>
              <input
                type="number"
                value={form.pointsMultiplier}
                onChange={e => setForm(f => ({ ...f, pointsMultiplier: Number(e.target.value) }))}
                min="1" step="0.5"
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">خصم الحجوزات %</label>
              <input
                type="number"
                value={form.bookingDiscountPercent}
                onChange={e => setForm(f => ({ ...f, bookingDiscountPercent: Number(e.target.value) }))}
                min="0" max="100"
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">نقاط ترحيبية</label>
              <input
                type="number"
                value={form.welcomePoints}
                onChange={e => setForm(f => ({ ...f, welcomePoints: Number(e.target.value) }))}
                min="0"
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50"
              />
            </div>
          </div>
          <p className="text-xs text-gray-400 -mt-2">خصم الحجوزات يُقتطع من عمولة سبورتا فقط ولا يمس مستحقات الملعب.</p>

          {isCommission ? (
            <p className="text-xs text-gray-500 bg-amber-50 border border-amber-100 rounded-xl p-3">
              اشتراك «بالنسبة» بلا رسوم مقدَّمة وبلا تاريخ انتهاء: سبورتا تأخذ النسبة
              أعلاه من كل عملية للمشترك بدل نسبة المنصة الافتراضية، ويستمر حتى يلغيه.
            </p>
          ) : (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">خصم عمولة سبورتا %</label>
            <input
              type="number"
              value={form.commissionDiscountPercent}
              onChange={e => setForm(f => ({ ...f, commissionDiscountPercent: Number(e.target.value) }))}
              min="0" max="100"
              className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50"
            />
            <p className="text-xs text-gray-400 mt-1.5">
              نسبة تُخصم من عمولة المنصة على المشترك (مدرب أو ملعب) طوال مدة اشتراكه —
              مثلاً 40% تجعل عمولة 5% تصير 3%.
            </p>
          </div>
          )}

          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-sm font-medium text-gray-700">المميزات</label>
              <button type="button" onClick={addFeature}
                className="flex items-center gap-1 text-xs text-[#2AB5CE] hover:text-green-700 font-medium">
                <Plus className="w-3.5 h-3.5" /> إضافة
              </button>
            </div>
            <div className="space-y-2">
              {form.features.map((f, i) => (
                <div key={i} className="flex gap-2">
                  <input
                    value={f}
                    onChange={e => updateFeature(i, e.target.value)}
                    placeholder={`ميزة ${i + 1}...`}
                    className="flex-1 px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-gray-50"
                  />
                  {form.features.length > 1 && (
                    <button onClick={() => removeFeature(i)}
                      className="w-9 flex items-center justify-center rounded-xl bg-red-50 text-red-400 hover:bg-red-100 transition">
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="flex gap-3 px-6 py-4 border-t border-gray-100">
          <button onClick={onClose}
            className="flex-1 py-2.5 border border-gray-200 rounded-xl text-gray-600 font-medium hover:bg-gray-50 transition text-sm">
            إلغاء
          </button>
          <button
            onClick={() => isValid && onSave({ ...form, features: form.features.filter(f => f.trim()) })}
            disabled={!isValid}
            className="flex-1 py-2.5 bg-[#2AB5CE] hover:bg-[#1E9AB0] disabled:bg-gray-200 disabled:text-gray-400 text-white font-medium rounded-xl transition text-sm flex items-center justify-center gap-2"
          >
            <Save className="w-4 h-4" />
            {initial ? 'حفظ التعديلات' : 'إنشاء الاشتراك'}
          </button>
        </div>
      </div>
    </div>
  );
}
