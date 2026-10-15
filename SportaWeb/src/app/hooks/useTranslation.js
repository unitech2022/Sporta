import { useState, useEffect } from "react";
import { translations, getCurrentLanguage, isRTL } from "../translations";
const useTranslation = () => {
  const [lang, setLang] = useState(getCurrentLanguage());
  useEffect(() => {
    const handleStorageChange = () => {
      setLang(getCurrentLanguage());
    };
    window.addEventListener("storage", handleStorageChange);
    return () => window.removeEventListener("storage", handleStorageChange);
  }, []);
  const t = (key) => {
    const keys = key.split(".");
    let value = translations[lang];
    for (const k of keys) {
      value = value?.[k];
    }
    return value || key;
  };
  return {
    t,
    lang,
    isRTL: isRTL(lang),
    dir: isRTL(lang) ? "rtl" : "ltr"
  };
};
export {
  useTranslation
};
