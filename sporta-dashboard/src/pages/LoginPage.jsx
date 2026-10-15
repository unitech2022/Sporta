import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Eye, EyeOff, Lock, Phone, AlertCircle } from 'lucide-react';

/** أرقام الجوال السعودية `05xxxxxxxx` — نفس حدّ التطبيق (`phone_input.dart`). */
const PHONE_LENGTH = 10;
const normalizePhone = (v) => v.replace(/\D/g, '').slice(0, PHONE_LENGTH);

export default function LoginPage() {
  const [phone, setPhone]       = useState('');
  const [password, setPassword] = useState('');
  const [showPass, setShowPass] = useState(false);
  const [error, setError]       = useState('');
  const [loading, setLoading]   = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    if (phone.length !== PHONE_LENGTH) {
      setError(`رقم الهاتف يجب أن يكون ${PHONE_LENGTH} أرقام (05xxxxxxxx)`);
      return;
    }
    setLoading(true);
    try {
      await login(phone, password);
      navigate('/');
    } catch (err) {
      setError(
        err?.messageAr ||
        err?.response?.data?.messageAr ||
        err?.response?.data?.message ||
        'رقم الهاتف أو كلمة المرور غير صحيحة'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex">
      {/* Left panel — brand */}
      <div
        className="hidden lg:flex flex-col items-center justify-center w-1/2 relative overflow-hidden"
        style={{ background: 'linear-gradient(135deg, #0A2540 0%, #0d3460 60%, #1a4a7a 100%)' }}
      >
        {/* Decorative circles */}
        <div className="absolute -top-32 -right-32 w-96 h-96 rounded-full opacity-10"
          style={{ background: '#2AB5CE' }} />
        <div className="absolute -bottom-40 -left-20 w-80 h-80 rounded-full opacity-10"
          style={{ background: '#2AB5CE' }} />
        <div className="absolute top-1/2 right-0 w-2 h-32 rounded-l-full opacity-40"
          style={{ background: '#2AB5CE' }} />

        <div className="relative z-10 text-center px-12">
          <img src="/logo.png" alt="Sporta" className="h-24 w-auto object-contain mx-auto mb-8 drop-shadow-2xl" />
          <h1 className="text-4xl font-bold text-white mb-3">سبورتا</h1>
          <p className="text-white/60 text-lg leading-relaxed">
            منصة إدارة الملاعب والمباريات<br />الرياضية المتكاملة
          </p>

          <div className="mt-12 grid grid-cols-3 gap-6 text-center">
            {[['🏟️','الملاعب'],['🏆','المباريات'],['👥','اللاعبون']].map(([icon, label]) => (
              <div key={label} className="bg-white/5 border border-white/10 rounded-2xl p-4">
                <div className="text-2xl mb-1">{icon}</div>
                <p className="text-white/60 text-xs">{label}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Right panel — form */}
      <div className="flex-1 flex items-center justify-center p-6 bg-[#F8F9FA]">
        <div className="w-full max-w-sm">
          {/* Logo (mobile only) */}
          <div className="lg:hidden text-center mb-8">
            <img src="/logo.png" alt="Sporta" className="h-16 w-auto object-contain mx-auto mb-3" />
            <h1 className="text-2xl font-bold text-[#0A2540]">سبورتا</h1>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
            <div className="mb-7">
              <h2 className="text-2xl font-bold text-[#0A2540]">تسجيل الدخول</h2>
              <p className="text-sm text-gray-400 mt-1">أدخل بياناتك للوصول إلى لوحة التحكم</p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-5">
              {/* Phone */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">رقم الهاتف</label>
                <div className="relative">
                  <Phone className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <input
                    type="tel"
                    inputMode="numeric"
                    value={phone}
                    onChange={e => setPhone(normalizePhone(e.target.value))}
                    placeholder="05xxxxxxxx"
                    maxLength={PHONE_LENGTH}
                    required
                    className="w-full pr-10 pl-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:border-[#2AB5CE] focus:ring-2 focus:ring-[#2AB5CE]/20 text-right bg-gray-50 transition"
                  />
                </div>
              </div>

              {/* Password */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">كلمة المرور</label>
                <div className="relative">
                  <Lock className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <input
                    type={showPass ? 'text' : 'password'}
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    placeholder="••••••••"
                    required
                    className="w-full pr-10 pl-10 py-3 border border-gray-200 rounded-xl focus:outline-none focus:border-[#2AB5CE] focus:ring-2 focus:ring-[#2AB5CE]/20 text-right bg-gray-50 transition"
                  />
                  <button type="button" onClick={() => setShowPass(!showPass)}
                    className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                    {showPass ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Error */}
              {error && (
                <div className="flex items-center gap-2 text-red-600 bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{error}</span>
                </div>
              )}

              {/* Submit */}
              <button
                type="submit"
                disabled={loading}
                className="w-full py-3 text-white font-semibold rounded-xl transition-all flex items-center justify-center gap-2 shadow-lg disabled:opacity-70"
                style={{ background: loading ? '#1E9AB0' : 'linear-gradient(135deg, #2AB5CE, #1E9AB0)' }}
              >
                {loading ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    <span>جاري الدخول...</span>
                  </>
                ) : 'دخول'}
              </button>
            </form>
          </div>

          <p className="text-center text-gray-400 text-xs mt-6">
            © 2025 Sporta — جميع الحقوق محفوظة
          </p>
        </div>
      </div>
    </div>
  );
}
