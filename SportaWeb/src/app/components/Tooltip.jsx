import { useState } from "react";
function Tooltip({ content, children, position = "top" }) {
  const [isVisible, setIsVisible] = useState(false);
  const positionClasses = {
    top: "bottom-full left-1/2 -translate-x-1/2 mb-2",
    bottom: "top-full left-1/2 -translate-x-1/2 mt-2",
    left: "right-full top-1/2 -translate-y-1/2 mr-2",
    right: "left-full top-1/2 -translate-y-1/2 ml-2"
  };
  const arrowClasses = {
    top: "top-full left-1/2 -translate-x-1/2 border-t-secondary border-l-transparent border-r-transparent border-b-transparent",
    bottom: "bottom-full left-1/2 -translate-x-1/2 border-b-secondary border-l-transparent border-r-transparent border-t-transparent",
    left: "left-full top-1/2 -translate-y-1/2 border-l-secondary border-t-transparent border-b-transparent border-r-transparent",
    right: "right-full top-1/2 -translate-y-1/2 border-r-secondary border-t-transparent border-b-transparent border-l-transparent"
  };
  return <div
    className="relative inline-block"
    onMouseEnter={() => setIsVisible(true)}
    onMouseLeave={() => setIsVisible(false)}
    onTouchStart={() => setIsVisible(true)}
    onTouchEnd={() => setTimeout(() => setIsVisible(false), 2e3)}
  >
      {children}
      {isVisible && <div
    className={`absolute z-50 px-3 py-2 bg-secondary text-white text-xs rounded-lg shadow-lg whitespace-nowrap pointer-events-none ${positionClasses[position]}`}
  >
          {content}
          <div className={`absolute w-0 h-0 border-4 ${arrowClasses[position]}`} />
        </div>}
    </div>;
}
export {
  Tooltip as default
};
