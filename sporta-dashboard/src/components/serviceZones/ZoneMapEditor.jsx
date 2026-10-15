import { useEffect, useMemo, useRef, useState } from 'react';
import {
  MapContainer, TileLayer, Polygon, Marker, Polyline, Tooltip, useMap, useMapEvents,
} from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Pencil, Hand, Crosshair, Undo2, Trash2, ZoomIn, Search } from 'lucide-react';

const RIYADH_CENTER = [24.7136, 46.6753];
const DEFAULT_ZOOM = 11;

// رأس المضلّع: دائرة صغيرة قابلة للسحب (أنماط داخلية — لا CSS عام).
const vertexIcon = (color) =>
  L.divIcon({
    className: '',
    html: `<span style="display:block;width:14px;height:14px;border-radius:50%;background:${color};border:2px solid #fff;box-shadow:0 0 0 1px rgba(0,0,0,.35)"></span>`,
    iconSize: [14, 14],
    iconAnchor: [7, 7],
  });

const testIcon = L.divIcon({
  className: '',
  html: '<span style="font-size:24px;line-height:1">📍</span>',
  iconSize: [24, 24],
  iconAnchor: [12, 24],
});

/** يلتقط النقر: إضافة رأس (وضع الرسم) أو اختبار نقطة (وضع الاختبار). */
function ClickCapture({ mode, onAddPoint, onTestPoint }) {
  useMapEvents({
    click(e) {
      const p = { lat: e.latlng.lat, lng: e.latlng.lng };
      if (mode === 'draw') onAddPoint(p);
      else if (mode === 'test') onTestPoint?.(p);
    },
  });
  return null;
}

/** يضبط حجم الخريطة بعد الظهور ويطير إلى الحدود المطلوبة. */
function MapController({ fitTo, flyTo }) {
  const map = useMap();
  useEffect(() => {
    const t = setTimeout(() => map.invalidateSize(), 150);
    return () => clearTimeout(t);
  }, [map]);
  useEffect(() => {
    if (fitTo && fitTo.length >= 2) {
      map.fitBounds(fitTo.map((p) => [p.lat, p.lng]), { padding: [30, 30] });
    }
  }, [map, fitTo]);
  useEffect(() => {
    if (flyTo) map.flyTo([flyTo.lat, flyTo.lng], flyTo.zoom || 14);
  }, [map, flyTo]);
  return null;
}

const modeBtn = (active) =>
  `flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition ${
    active ? 'bg-[#2AB5CE] text-white shadow' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
  }`;

const toolBtn =
  'flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-white border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed';

/**
 * محرّر مضلّع منطقة الخدمة.
 *  - points: [{lat,lng}] رؤوس المضلّع، onChange(points) عند أي تعديل
 *  - otherZones: مناطق أخرى تُعرض للمقارنة
 *  - testPoint / onTestPoint: نقطة اختبار (وضع الاختبار)
 */
export default function ZoneMapEditor({
  points = [],
  onChange,
  color = '#2AB5CE',
  otherZones = [],
  testPoint = null,
  onTestPoint,
  readOnly = false,
  height = 480,
}) {
  const [mode, setMode] = useState(readOnly ? 'pan' : 'draw'); // draw | pan | test
  const [search, setSearch] = useState('');
  const [searching, setSearching] = useState(false);
  const [results, setResults] = useState([]);
  const [flyTo, setFlyTo] = useState(null);
  const [fitTo, setFitTo] = useState(null);
  const lastSearchAt = useRef(0);

  // عند فتح منطقة موجودة نطير إلى حدودها مرة واحدة عند التركيب فقط — لا
  // نتابع [points] حتى لا تقفز الخريطة تحت يد الراسم بعد كل نقطة.
  useEffect(() => {
    if (points.length >= 2) setFitTo([...points]);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const setPoints = (next) => {
    if (!readOnly) onChange?.(next);
  };
  const addPoint = (p) => setPoints([...points, p]);
  const movePoint = (index, p) => setPoints(points.map((pt, i) => (i === index ? p : pt)));
  const removePoint = (index) => setPoints(points.filter((_, i) => i !== index));

  // بحث بالاسم عبر Nominatim (مجاني بلا مفتاح، طلب واحد في الثانية).
  const doSearch = async () => {
    const q = search.trim();
    if (!q) return;
    const wait = Math.max(0, 1100 - (Date.now() - lastSearchAt.current));
    setSearching(true);
    try {
      if (wait) await new Promise((r) => setTimeout(r, wait));
      lastSearchAt.current = Date.now();
      const url = `https://nominatim.openstreetmap.org/search?format=json&limit=6&accept-language=ar&q=${encodeURIComponent(q)}`;
      const res = await fetch(url, { headers: { Accept: 'application/json' } });
      const data = await res.json();
      setResults(Array.isArray(data) ? data : []);
    } catch {
      setResults([]);
    } finally {
      setSearching(false);
    }
  };

  const pickResult = (r) => {
    setResults([]);
    setFlyTo({ lat: parseFloat(r.lat), lng: parseFloat(r.lon), zoom: 14, t: Date.now() });
  };

  const positions = useMemo(() => points.map((p) => [p.lat, p.lng]), [points]);

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        {!readOnly && (
          <div className="flex gap-1.5">
            <button type="button" className={modeBtn(mode === 'draw')} onClick={() => setMode('draw')}>
              <Pencil className="w-3.5 h-3.5" /> رسم
            </button>
            <button type="button" className={modeBtn(mode === 'pan')} onClick={() => setMode('pan')}>
              <Hand className="w-3.5 h-3.5" /> تحريك
            </button>
            <button type="button" className={modeBtn(mode === 'test')} onClick={() => setMode('test')}>
              <Crosshair className="w-3.5 h-3.5" /> اختبار نقطة
            </button>
          </div>
        )}

        {/* ليس <form>: المحرّر نفسه داخل نموذج الحفظ، والنماذج المتداخلة تجعل
            Enter في البحث يحفظ المنطقة. */}
        <div className="relative flex-1 min-w-[220px] flex gap-1.5">
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                doSearch();
              }
            }}
            placeholder="ابحث عن حي أو مدينة… مثل: حي الملقا الرياض"
            className="flex-1 px-3 py-1.5 border border-gray-200 rounded-lg text-xs focus:outline-none focus:ring-2 focus:ring-[#2AB5CE] bg-white"
          />
          <button type="button" onClick={doSearch} disabled={searching} className={toolBtn}>
            <Search className="w-3.5 h-3.5" /> {searching ? '…' : 'بحث'}
          </button>
          {results.length > 0 && (
            <ul className="absolute top-full mt-1 inset-x-0 z-[1000] bg-white border border-gray-200 rounded-lg shadow-lg max-h-60 overflow-auto">
              {results.map((r) => (
                <li
                  key={r.place_id}
                  onClick={() => pickResult(r)}
                  className="px-3 py-2 text-xs text-gray-700 hover:bg-gray-50 cursor-pointer border-b border-gray-50 last:border-0"
                >
                  {r.display_name}
                </li>
              ))}
            </ul>
          )}
        </div>

        {!readOnly && (
          <div className="flex items-center gap-1.5">
            <span className="text-xs text-gray-500">النقاط: {points.length}</span>
            <button type="button" className={toolBtn} onClick={() => setPoints(points.slice(0, -1))} disabled={points.length === 0}>
              <Undo2 className="w-3.5 h-3.5" /> تراجع
            </button>
            <button type="button" className={toolBtn} onClick={() => setPoints([])} disabled={points.length === 0}>
              <Trash2 className="w-3.5 h-3.5" /> مسح
            </button>
            <button type="button" className={toolBtn} onClick={() => setFitTo([...points])} disabled={points.length < 2}>
              <ZoomIn className="w-3.5 h-3.5" /> تكبير على المنطقة
            </button>
          </div>
        )}
      </div>

      {!readOnly && mode === 'draw' && (
        <p className="text-xs text-gray-500">
          انقر على الخريطة لإضافة نقاط حدود المنطقة بالترتيب (3 نقاط على الأقل). اسحب النقطة لتحريكها، وانقر عليها نقرتين لحذفها.
        </p>
      )}
      {mode === 'test' && (
        <p className="text-xs text-gray-500">
          انقر على أي موقع في الخريطة لمعرفة هل يقع داخل نطاق الخدمة (يعتمد على المناطق المحفوظة والمفعّلة فقط).
        </p>
      )}

      <div className="rounded-xl overflow-hidden border border-gray-200" style={{ height }}>
        <MapContainer
          center={RIYADH_CENTER}
          zoom={DEFAULT_ZOOM}
          style={{ height: '100%', width: '100%' }}
          scrollWheelZoom
          doubleClickZoom={false}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <MapController fitTo={fitTo} flyTo={flyTo} />
          <ClickCapture mode={mode} onAddPoint={addPoint} onTestPoint={onTestPoint} />

          {otherZones.map((z) =>
            z.polygon?.length >= 3 ? (
              <Polygon
                key={`other-${z.id}`}
                positions={z.polygon.map((p) => [p.lat, p.lng])}
                pathOptions={{
                  color: z.color || '#16a34a',
                  weight: 1.5,
                  dashArray: z.isActive ? undefined : '6 6',
                  fillOpacity: z.isActive ? 0.08 : 0.03,
                  interactive: false,
                }}
              >
                <Tooltip sticky direction="top">{z.nameAr}</Tooltip>
              </Polygon>
            ) : null
          )}

          {positions.length >= 3 ? (
            <Polygon positions={positions} pathOptions={{ color, weight: 2.5, fillOpacity: 0.2 }} />
          ) : positions.length === 2 ? (
            <Polyline positions={positions} pathOptions={{ color, weight: 2.5, dashArray: '6 6' }} />
          ) : null}

          {!readOnly &&
            points.map((p, i) => (
              <Marker
                key={`v-${i}`}
                position={[p.lat, p.lng]}
                draggable
                icon={vertexIcon(color)}
                eventHandlers={{
                  dragend: (e) => {
                    const ll = e.target.getLatLng();
                    movePoint(i, { lat: ll.lat, lng: ll.lng });
                  },
                  dblclick: () => removePoint(i),
                }}
              >
                <Tooltip direction="top" offset={[0, -8]}>نقطة {i + 1}</Tooltip>
              </Marker>
            ))}

          {testPoint && <Marker position={[testPoint.lat, testPoint.lng]} icon={testIcon} />}
        </MapContainer>
      </div>
    </div>
  );
}
