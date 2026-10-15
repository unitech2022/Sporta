import { useRef, useState } from 'react';
import { ImagePlus, Loader2, X } from 'lucide-react';
import { BASE_URL } from '../api/apiClient';
import { adminApi } from '../api/adminApi';

/** Resolves a possibly-relative upload URL against the API base URL. */
export function resolveImageUrl(url) {
  if (!url) return null;
  return url.startsWith('http') ? url : `${BASE_URL}${url}`;
}

/**
 * Square image picker: click to choose a file from the device, uploads it to
 * `/api/uploads/image`, and reports the returned URL via onChange.
 */
export default function ImageUploadField({ label, value, onChange }) {
  const inputRef = useRef(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');

  const pick = () => inputRef.current?.click();

  const handleFile = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = ''; // allow re-selecting the same file later
    if (!file) return;

    setError('');
    setUploading(true);
    try {
      const res = await adminApi.uploadImage(file);
      onChange(res.data.data.url);
    } catch (err) {
      setError(
        err?.response?.data?.messageAr ||
        err?.response?.data?.message ||
        'تعذّر رفع الصورة'
      );
    } finally {
      setUploading(false);
    }
  };

  return (
    <div>
      {label && (
        <label className="block text-sm font-medium text-gray-700 mb-1.5">{label}</label>
      )}
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={pick}
          disabled={uploading}
          className="relative w-20 h-20 shrink-0 rounded-xl border-2 border-dashed border-gray-200 bg-gray-50 flex items-center justify-center overflow-hidden hover:border-[#2AB5CE] transition disabled:opacity-60"
        >
          {uploading ? (
            <Loader2 className="w-6 h-6 text-gray-400 animate-spin" />
          ) : value ? (
            <img src={resolveImageUrl(value)} alt="" className="w-full h-full object-cover" />
          ) : (
            <ImagePlus className="w-6 h-6 text-gray-300" />
          )}
        </button>
        <div className="flex flex-col gap-1.5">
          <button
            type="button"
            onClick={pick}
            disabled={uploading}
            className="text-sm font-medium text-[#2AB5CE] hover:underline disabled:opacity-60 text-right"
          >
            {value ? 'تغيير الصورة' : 'اختيار صورة من الجهاز'}
          </button>
          {value && (
            <button
              type="button"
              onClick={() => onChange(null)}
              className="flex items-center gap-1 text-xs text-red-500 hover:underline w-fit"
            >
              <X className="w-3.5 h-3.5" /> إزالة الصورة
            </button>
          )}
          {error && <p className="text-xs text-red-500">{error}</p>}
        </div>
      </div>
      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={handleFile}
      />
    </div>
  );
}
