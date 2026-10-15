// Small shared table helpers used by the list pages.

export function Th({ children }) {
  return (
    <th className="text-right px-4 py-3.5 font-semibold text-gray-600 first:px-5">
      {children}
    </th>
  );
}

export function Spinner() {
  return (
    <div className="flex justify-center py-20">
      <div className="w-10 h-10 border-4 border-green-200 border-t-[#2AB5CE] rounded-full animate-spin" />
    </div>
  );
}

export function Empty({ icon: Icon, text }) {
  return (
    <div className="text-center py-20 text-gray-400">
      <Icon className="w-12 h-12 mx-auto mb-3 opacity-30" />
      <p>{text}</p>
    </div>
  );
}
