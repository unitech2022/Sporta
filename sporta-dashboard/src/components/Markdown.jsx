// Tiny dependency-free Markdown renderer for the policy previews.
// Supports the small subset the policy content uses:
//   ## Heading        → section heading
//   ### Sub-heading   → sub heading
//   - bullet          → list item (consecutive lines grouped into a list)
//   blank line        → paragraph break
// Anything else is treated as paragraph text (consecutive lines are joined).
// Keep this in sync with the Flutter PolicyMarkdown widget.

function renderBlocks(text) {
  const lines = String(text ?? '').replace(/\r\n/g, '\n').split('\n');
  const blocks = [];
  let paragraph = [];
  let bullets = [];

  const flushParagraph = () => {
    if (paragraph.length) {
      blocks.push({ type: 'p', text: paragraph.join(' ') });
      paragraph = [];
    }
  };
  const flushBullets = () => {
    if (bullets.length) {
      blocks.push({ type: 'ul', items: bullets });
      bullets = [];
    }
  };

  for (const raw of lines) {
    const line = raw.trim();
    if (line === '') {
      flushParagraph();
      flushBullets();
    } else if (line.startsWith('### ')) {
      flushParagraph();
      flushBullets();
      blocks.push({ type: 'h3', text: line.slice(4) });
    } else if (line.startsWith('## ')) {
      flushParagraph();
      flushBullets();
      blocks.push({ type: 'h2', text: line.slice(3) });
    } else if (line.startsWith('- ')) {
      flushParagraph();
      bullets.push(line.slice(2));
    } else {
      flushBullets();
      paragraph.push(line);
    }
  }
  flushParagraph();
  flushBullets();
  return blocks;
}

export default function Markdown({ text, dir = 'rtl', className = '' }) {
  const blocks = renderBlocks(text);
  const align = dir === 'rtl' ? 'text-right' : 'text-left';

  if (!blocks.length) {
    return <p className="text-gray-400 text-sm">لا يوجد محتوى</p>;
  }

  return (
    <div dir={dir} className={`space-y-3 ${align} ${className}`}>
      {blocks.map((b, i) => {
        if (b.type === 'h2') {
          return (
            <h2 key={i} className="text-base font-bold text-[#0A2540] mt-4 first:mt-0">
              {b.text}
            </h2>
          );
        }
        if (b.type === 'h3') {
          return (
            <h3 key={i} className="text-sm font-semibold text-[#2AB5CE] mt-2">
              {b.text}
            </h3>
          );
        }
        if (b.type === 'ul') {
          return (
            <ul key={i} className="space-y-1.5">
              {b.items.map((it, j) => (
                <li key={j} className="flex gap-2 text-sm text-gray-600 leading-relaxed">
                  <span className="text-[#2AB5CE] shrink-0">•</span>
                  <span>{it}</span>
                </li>
              ))}
            </ul>
          );
        }
        return (
          <p key={i} className="text-sm text-gray-600 leading-relaxed">
            {b.text}
          </p>
        );
      })}
    </div>
  );
}
