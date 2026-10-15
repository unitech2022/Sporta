import { useState, useEffect, useRef } from "react";
import logo from "../imports/new_logo.png";
import homeScreenshot from "../imports/home-screenshot.png";
const css = `
  @keyframes float-slow {
    0%,100% { transform: translateY(0px) rotate(-4deg); }
    50% { transform: translateY(-22px) rotate(4deg); }
  }
  @keyframes float-med {
    0%,100% { transform: translateY(0px) rotate(6deg); }
    50% { transform: translateY(-16px) rotate(-6deg); }
  }
  @keyframes float-fast {
    0%,100% { transform: translateY(0px) rotate(0deg); }
    50% { transform: translateY(-28px) rotate(8deg); }
  }
  @keyframes spin-slow {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }
  @keyframes pulse-ring {
    0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(42,181,206,0.4); }
    70% { transform: scale(1); box-shadow: 0 0 0 20px rgba(42,181,206,0); }
    100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(42,181,206,0); }
  }
  @keyframes fade-up {
    from { opacity: 0; transform: translateY(30px); }
    to { opacity: 1; transform: translateY(0); }
  }
  @keyframes slide-in-right {
    from { opacity: 0; transform: translateX(40px); }
    to { opacity: 1; transform: translateX(0); }
  }
  @keyframes slide-in-left {
    from { opacity: 0; transform: translateX(-40px); }
    to { opacity: 1; transform: translateX(0); }
  }
  @keyframes scroll-marquee {
    0% { transform: translateX(0); }
    100% { transform: translateX(-50%); }
  }
  .animate-float-slow { animation: float-slow 6s ease-in-out infinite; }
  .animate-float-med { animation: float-med 4.5s ease-in-out infinite; }
  .animate-float-fast { animation: float-fast 3.5s ease-in-out infinite; }
  .animate-spin-slow { animation: spin-slow 20s linear infinite; }
  .animate-pulse-ring { animation: pulse-ring 2.5s cubic-bezier(0.455,0.03,0.515,0.955) infinite; }
  .animate-fade-up { animation: fade-up 0.7s ease-out forwards; }
  .animate-slide-right { animation: slide-in-right 0.7s ease-out forwards; }
  .animate-slide-left { animation: slide-in-left 0.7s ease-out forwards; }
  .animate-marquee { animation: scroll-marquee 22s linear infinite; }
  .section-animate { opacity: 0; transform: translateY(30px); transition: opacity 0.7s ease, transform 0.7s ease; }
  .section-visible { opacity: 1; transform: translateY(0); }
  ::-webkit-scrollbar { width: 4px; }
  ::-webkit-scrollbar-track { background: #060C14; }
  ::-webkit-scrollbar-thumb { background: #2AB5CE44; border-radius: 4px; }
  .nav-link { position: relative; }
  .nav-link::after { content:''; position:absolute; bottom:-2px; right:0; width:0; height:2px; background:#2AB5CE; transition: width 0.3s ease; }
  .nav-link:hover::after { width:100%; }
  .nav-link-ltr::after { right:auto; left:0; }
  .feature-card { transition: transform 0.3s ease, box-shadow 0.3s ease; }
  .feature-card:hover { transform: translateY(-6px); box-shadow: 0 20px 50px rgba(42,181,206,0.15); }
  .lang-switch { transition: all 0.35s cubic-bezier(0.4,0,0.2,1); }
`;
const T = {
  ar: {
    dir: "rtl",
    nav: { features: "\u0627\u0644\u0645\u0645\u064A\u0632\u0627\u062A", points: "\u0627\u0644\u0646\u0642\u0627\u0637", download: "\u062A\u062D\u0645\u064A\u0644", cta: "\u062D\u0645\u0651\u0644 \u0627\u0644\u062A\u0637\u0628\u064A\u0642" },
    badge: "\u062A\u062C\u0631\u0628\u0629 \u0631\u064A\u0627\u0636\u064A\u0629 \u0645\u062A\u0643\u0627\u0645\u0644\u0629",
    heroTitle1: "\u0639\u0634 \u062A\u062C\u0631\u0628\u0629 \u0628\u0627\u062F\u0644",
    heroTitle2: "\u0627\u0633\u062A\u062B\u0646\u0627\u0626\u064A\u0629",
    heroSub: "\u0627\u062D\u062C\u0632 \u0645\u0644\u0627\u0639\u0628\u0643\u060C \u0627\u0646\u0636\u0645 \u0644\u0644\u0645\u0628\u0627\u0631\u064A\u0627\u062A\u060C \u062A\u062F\u0631\u0628 \u0645\u0639 \u0623\u0641\u0636\u0644 \u0627\u0644\u0645\u062F\u0631\u0628\u064A\u0646\u060C \u0648\u0627\u0631\u062A\u0642\u0650 \u0641\u064A \u0633\u0644\u0645 \u0627\u0644\u062A\u0635\u0646\u064A\u0641 \u2014 \u0643\u0644 \u0630\u0644\u0643 \u0645\u0646 \u062A\u0637\u0628\u064A\u0642 \u0648\u0627\u062D\u062F",
    appStore: "App Store",
    googlePlay: "Google Play",
    matchesToday: "\u0645\u0628\u0627\u0631\u064A\u0627\u062A \u0627\u0644\u064A\u0648\u0645",
    matchesTodayVal: "47 \u0645\u0628\u0627\u0631\u0627\u0629",
    yourPoints: "\u0646\u0642\u0627\u0637\u0643",
    statsSection: "\u0627\u0643\u062A\u0634\u0641 \u0627\u0644\u0645\u0632\u064A\u062F",
    stats: [
      { value: "+100", label: "\u0645\u0644\u0639\u0628 \u0628\u0627\u062F\u0644", icon: "\u{1F3DF}\uFE0F" },
      { value: "+3,000", label: "\u0644\u0627\u0639\u0628 \u0645\u0633\u062C\u0644", icon: "\u{1F465}" },
      { value: "+6,000", label: "\u0645\u0628\u0627\u0631\u0627\u0629 \u0645\u0646\u0638\u0645\u0629", icon: "\u{1F3C6}" },
      { value: "4.9\u2605", label: "\u062A\u0642\u064A\u064A\u0645 \u0627\u0644\u0645\u0633\u062A\u062E\u062F\u0645\u064A\u0646", icon: "\u2B50" }
    ],
    featuresSec: "\u0627\u0644\u0645\u0645\u064A\u0632\u0627\u062A",
    featuresTitle: "\u0643\u0644 \u0645\u0627 \u062A\u062D\u062A\u0627\u062C\u0647 \u0641\u064A \u0645\u0643\u0627\u0646 \u0648\u0627\u062D\u062F",
    featuresSub: "\u0635\u064F\u0645\u0651\u0645 SPORTA \u0644\u064A\u0643\u0648\u0646 \u0627\u0644\u0631\u0641\u064A\u0642 \u0627\u0644\u0631\u064A\u0627\u0636\u064A \u0627\u0644\u0645\u062B\u0627\u0644\u064A \u0644\u0643\u0644 \u0644\u0627\u0639\u0628\u060C \u0645\u062F\u0631\u0628\u060C \u0648\u0635\u0627\u062D\u0628 \u0645\u0644\u0639\u0628",
    features: [
      { title: "\u0627\u062D\u062C\u0632 \u0645\u0644\u0639\u0628\u0643", desc: "\u062A\u0635\u0641\u062D \u0623\u0641\u0636\u0644 \u0645\u0644\u0627\u0639\u0628 \u0627\u0644\u0628\u0627\u062F\u0644 \u0648\u0627\u062D\u062C\u0632 \u0648\u0642\u062A\u0643 \u0627\u0644\u0645\u0641\u0636\u0644 \u0628\u0643\u0644 \u0633\u0647\u0648\u0644\u0629 \u0648\u064A\u0633\u0631", color: "cyan" },
      { title: "\u0646\u0638\u0627\u0645 \u0627\u0644\u0646\u0642\u0627\u0637", desc: "\u0627\u0643\u0633\u0628 \u0646\u0642\u0627\u0637\u0627\u064B \u0645\u0639 \u0643\u0644 \u0645\u0628\u0627\u0631\u0627\u0629 \u0648\u0627\u0631\u062A\u0642\u0650 \u0641\u064A \u0627\u0644\u0645\u0633\u062A\u0648\u064A\u0627\u062A \u0645\u0646 \u0628\u0631\u0648\u0646\u0632\u064A \u0625\u0644\u0649 \u0623\u0633\u0637\u0648\u0631\u064A", color: "yellow" },
      { title: "\u0627\u0646\u0636\u0645 \u0644\u0645\u0628\u0627\u0631\u064A\u0627\u062A", desc: "\u0627\u0628\u062D\u062B \u0639\u0646 \u0644\u0627\u0639\u0628\u064A\u0646 \u0628\u0645\u0633\u062A\u0648\u0627\u0643 \u0648\u0627\u0646\u0636\u0645 \u0644\u0645\u0628\u0627\u0631\u064A\u0627\u062A \u0645\u062B\u064A\u0631\u0629 \u0641\u064A \u0623\u064A \u0648\u0642\u062A", color: "purple" },
      { title: "\u0628\u0637\u0648\u0644\u0627\u062A \u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648", desc: "\u0634\u0627\u0631\u0643 \u0641\u064A \u0628\u0637\u0648\u0644\u0627\u062A \u0627\u0644\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0648\u062A\u0646\u0627\u0641\u0633 \u0645\u0639 \u0623\u0641\u0636\u0644 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646 \u0641\u064A \u0645\u0646\u0637\u0642\u062A\u0643", color: "emerald" },
      { title: "\u0645\u062F\u0631\u0628\u0648\u0646 \u0645\u062D\u062A\u0631\u0641\u0648\u0646", desc: "\u0627\u0643\u062A\u0634\u0641 \u0623\u0641\u0636\u0644 \u0627\u0644\u0645\u062F\u0631\u0628\u064A\u0646 \u0627\u0644\u0645\u0639\u062A\u0645\u062F\u064A\u0646 \u0648\u0627\u062D\u062C\u0632 \u062C\u0644\u0633\u062A\u0643 \u0627\u0644\u062A\u062F\u0631\u064A\u0628\u064A\u0629 \u0627\u0644\u062E\u0627\u0635\u0629", color: "orange" },
      { title: "\u062A\u0642\u064A\u064A\u0645\u0627\u062A \u062D\u0642\u064A\u0642\u064A\u0629", desc: "\u0642\u064A\u0651\u0645 \u0645\u0644\u0627\u0639\u0628\u0643 \u0648\u0645\u062F\u0631\u0628\u064A\u0643 \u0648\u0634\u0627\u0631\u0643\u0646\u0627 \u062A\u062C\u0631\u0628\u062A\u0643 \u0644\u0645\u062C\u062A\u0645\u0639 \u0631\u064A\u0627\u0636\u064A \u0623\u0641\u0636\u0644", color: "pink" }
    ],
    pointsSec: "\u0646\u0638\u0627\u0645 \u0627\u0644\u0646\u0642\u0627\u0637",
    pointsTitle: "\u0627\u0644\u0639\u0628 \u0648\u0627\u0631\u062A\u0642\u0650 \u0641\u064A \u0627\u0644\u0645\u0633\u062A\u0648\u064A\u0627\u062A",
    pointsSub: "\u0643\u0644 \u0645\u0628\u0627\u0631\u0627\u0629 \u062A\u0644\u0639\u0628\u0647\u0627\u060C \u0643\u0644 \u0645\u0644\u0639\u0628 \u062A\u062D\u062C\u0632\u0647\u060C \u0643\u0644 \u062A\u062F\u0631\u064A\u0628 \u062A\u062D\u0636\u0631\u0647 \u2014 \u064A\u0636\u064A\u0641 \u0646\u0642\u0627\u0637\u0627\u064B \u062A\u0631\u062A\u0642\u064A \u0628\u0643 \u0646\u062D\u0648 \u0627\u0644\u0623\u0639\u0644\u0649",
    levels: [
      { name: "\u0628\u0631\u0648\u0646\u0632\u064A", icon: "\u{1F949}", color: "from-amber-700 to-amber-600", range: "0 \u2013 99 \u0646\u0642\u0637\u0629" },
      { name: "\u0641\u0636\u064A", icon: "\u{1F948}", color: "from-gray-400 to-gray-300", range: "100 \u2013 299 \u0646\u0642\u0637\u0629" },
      { name: "\u0630\u0647\u0628\u064A", icon: "\u{1F947}", color: "from-yellow-500 to-yellow-400", range: "300 \u2013 999 \u0646\u0642\u0637\u0629" },
      { name: "\u0628\u0644\u0627\u062A\u064A\u0646\u064A", icon: "\u{1F48E}", color: "from-cyan-500 to-cyan-400", range: "1000 \u2013 4999 \u0646\u0642\u0637\u0629" },
      { name: "\u0623\u0633\u0637\u0648\u0631\u064A", icon: "\u{1F451}", color: "from-purple-600 to-pink-500", range: "5000+ \u0646\u0642\u0637\u0629" }
    ],
    earnItems: [
      { icon: "\u{1F3F8}", title: "\u0644\u0643\u0644 \u0645\u0628\u0627\u0631\u0627\u0629", pts: "+1 \u0646\u0642\u0637\u0629", color: "#2AB5CE" },
      { icon: "\u26A1", title: "\u0644\u0643\u0644 \u0628\u0637\u0648\u0644\u0629", pts: "+5 \u0646\u0642\u0627\u0637", color: "#F0C040" },
      { icon: "\u{1F91D}", title: "\u062F\u0639\u0648\u0629 \u0644\u0627\u0639\u0628", pts: "+3 \u0646\u0642\u0627\u0637", color: "#A78BFA" }
    ],
    sportsSec: "\u0627\u0644\u0631\u064A\u0627\u0636\u0627\u062A",
    sportsTitle: "\u0644\u0643\u0644 \u0631\u064A\u0627\u0636\u0629 \u062A\u062C\u0631\u0628\u0629 \u0645\u062E\u0635\u0635\u0629",
    sports: [
      { icon: "\u{1F3BE}", name: "\u0627\u0644\u0628\u0627\u062F\u0644", status: "\u0645\u062A\u0627\u062D \u0627\u0644\u0622\u0646", active: true },
      { icon: "\u26BD", name: "\u0643\u0631\u0629 \u0627\u0644\u0642\u062F\u0645", status: "\u0642\u0631\u064A\u0628\u0627\u064B", active: false },
      { icon: "\u{1F3C0}", name: "\u0643\u0631\u0629 \u0627\u0644\u0633\u0644\u0629", status: "\u0642\u0631\u064A\u0628\u0627\u064B", active: false },
      { icon: "\u{1F3B1}", name: "\u0627\u0644\u062A\u0646\u0633", status: "\u0642\u0631\u064A\u0628\u0627\u064B", active: false }
    ],
    dlSec: "\u062D\u0645\u0651\u0644 \u0627\u0644\u062A\u0637\u0628\u064A\u0642",
    dlTitle: "\u0627\u0628\u062F\u0623 \u062A\u062C\u0631\u0628\u062A\u0643 \u0627\u0644\u0631\u064A\u0627\u0636\u064A\u0629 \u0627\u0644\u0622\u0646",
    dlSub: "\u0645\u062A\u0627\u062D \u0639\u0644\u0649 iOS \u0648 Android \u2014 \u0633\u062C\u0651\u0644 \u0645\u062C\u0627\u0646\u0627\u064B \u0648\u0627\u0646\u0636\u0645 \u0644\u0622\u0644\u0627\u0641 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646",
    qr1: "\u0627\u0645\u0633\u062D \u0644\u0644\u062A\u062D\u0645\u064A\u0644 \u0645\u0646 App Store",
    qr2: "\u0627\u0645\u0633\u062D \u0644\u0644\u062A\u062D\u0645\u064A\u0644 \u0645\u0646 Google Play",
    tagline: "\u062A\u062C\u0631\u0628\u0629 \u0631\u064A\u0627\u0636\u064A\u0629 \u0645\u062A\u0643\u0627\u0645\u0644\u0629",
    reviews: "+15,000 \u062A\u0642\u064A\u064A\u0645",
    footerDesc: "\u0645\u0646\u0635\u0629 \u0631\u064A\u0627\u0636\u064A\u0629 \u0645\u062A\u0643\u0627\u0645\u0644\u0629 \u0644\u062D\u062C\u0632 \u0627\u0644\u0645\u0644\u0627\u0639\u0628 \u0648\u0625\u062F\u0627\u0631\u0629 \u0627\u0644\u0645\u0628\u0627\u0631\u064A\u0627\u062A \u0648\u0631\u0628\u0637 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646 \u0628\u0627\u0644\u0645\u062F\u0631\u0628\u064A\u0646",
    footerApp: "\u0627\u0644\u062A\u0637\u0628\u064A\u0642",
    footerAppLinks: ["\u062D\u062C\u0632 \u0627\u0644\u0645\u0644\u0627\u0639\u0628", "\u0627\u0644\u0645\u0628\u0627\u0631\u064A\u0627\u062A", "\u0627\u0644\u0645\u062F\u0631\u0628\u0648\u0646", "\u0646\u0638\u0627\u0645 \u0627\u0644\u0646\u0642\u0627\u0637"],
    footerCompany: "\u0627\u0644\u0634\u0631\u0643\u0629",
    footerCompanyLinks: ["\u0645\u0646 \u0646\u062D\u0646", "\u0633\u064A\u0627\u0633\u0629 \u0627\u0644\u062E\u0635\u0648\u0635\u064A\u0629", "\u0627\u0644\u0634\u0631\u0648\u0637 \u0648\u0627\u0644\u0623\u062D\u0643\u0627\u0645", "\u062A\u0648\u0627\u0635\u0644 \u0645\u0639\u0646\u0627"],
    footerContact: "\u062A\u0648\u0627\u0635\u0644 \u0645\u0639\u0646\u0627",
    footerCopy: "\xA9 2025 SPORTA. \u062C\u0645\u064A\u0639 \u0627\u0644\u062D\u0642\u0648\u0642 \u0645\u062D\u0641\u0648\u0638\u0629.",
    footerMade: "\u0635\u064F\u0646\u0639 \u0628\u0634\u063A\u0641 \u0644\u0643\u0644 \u0627\u0644\u0631\u064A\u0627\u0636\u064A\u064A\u0646 \u{1F3BE}",
    phoneMorning: "\u0645\u0631\u062D\u0628\u0627\u064B",
    phoneUser: "\u0627\u0644\u0644\u0627\u0639\u0628 \u0623\u062D\u0645\u062F",
    phonePoints: "\u0627\u0633\u062A\u0643\u0634\u0641 \u0646\u0638\u0627\u0645 \u0627\u0644\u0646\u0642\u0627\u0637",
    phoneLevel: "\u{1F947} \u0630\u0647\u0628\u064A",
    phoneActions: [{ icon: "\u{1F3F8}", label: "\u0645\u0628\u0627\u0631\u0627\u0629" }, { icon: "\u{1F3DF}\uFE0F", label: "\u0645\u0644\u0627\u0639\u0628" }, { icon: "\u{1F3C6}", label: "\u0628\u0637\u0648\u0644\u0627\u062A" }, { icon: "\u{1F468}\u200D\u{1F3EB}", label: "\u0645\u062F\u0631\u0628\u064A\u0646" }],
    phoneCourts: "3 \u0645\u0644\u0627\u0639\u0628 \u0642\u0631\u064A\u0628\u0629",
    phoneMatchesTitle: "\u0645\u0628\u0627\u0631\u064A\u0627\u062A \u0645\u062A\u0627\u062D\u0629",
    phoneMatchesAll: "\u0639\u0631\u0636 \u0627\u0644\u0643\u0644",
    phoneMatches: [
      { court: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A", time: "18:00", level: "5.0", color: "#10B981" },
      { court: "\u0645\u0644\u0639\u0628 \u0627\u0644\u0641\u064A\u0635\u0644\u064A\u0629", time: "20:00", level: "4.5", color: "#F59E0B" }
    ],
    phoneNav: ["\u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629", "\u0635\u0641\u062D\u062A\u064A", "\u0645\u0628\u0627\u0631\u064A\u0627\u062A", "\u0645\u0644\u0627\u0639\u0628", "\u0645\u062F\u0631\u0628\u064A\u0646"]
  },
  en: {
    dir: "ltr",
    nav: { features: "Features", points: "Points", download: "Download", cta: "Download App" },
    badge: "A Complete Sports Experience",
    heroTitle1: "Live an exceptional",
    heroTitle2: "padel experience",
    heroSub: "Book courts, join matches, train with top coaches, and climb the rankings \u2014 all in one app",
    appStore: "App Store",
    googlePlay: "Google Play",
    matchesToday: "Today's Matches",
    matchesTodayVal: "47 Matches",
    yourPoints: "Your Points",
    statsSection: "Discover More",
    stats: [
      { value: "100+", label: "Padel Courts", icon: "\u{1F3DF}\uFE0F" },
      { value: "3,000+", label: "Registered Players", icon: "\u{1F465}" },
      { value: "6,000+", label: "Organized Matches", icon: "\u{1F3C6}" },
      { value: "4.9\u2605", label: "User Rating", icon: "\u2B50" }
    ],
    featuresSec: "FEATURES",
    featuresTitle: "Everything you need in one place",
    featuresSub: "SPORTA is designed to be the ultimate sports companion for every player, coach, and venue owner",
    features: [
      { title: "Book Your Court", desc: "Browse the best padel courts and reserve your preferred slot with ease", color: "cyan" },
      { title: "Points System", desc: "Earn points with every match and rise through tiers from Bronze to Legendary", color: "yellow" },
      { title: "Join Matches", desc: "Find players at your level and join exciting matches any time of the day", color: "purple" },
      { title: "Americano Tournaments", desc: "Participate in Americano tournaments and compete with top players in your area", color: "emerald" },
      { title: "Pro Coaches", desc: "Discover certified coaches and book your personal training session", color: "orange" },
      { title: "Real Reviews", desc: "Rate courts and coaches and share your experience to build a better sports community", color: "pink" }
    ],
    pointsSec: "POINTS SYSTEM",
    pointsTitle: "Play and Rise Through the Ranks",
    pointsSub: "Every match you play, every court you book, every training you attend \u2014 earns you points to climb higher",
    levels: [
      { name: "Bronze", icon: "\u{1F949}", color: "from-amber-700 to-amber-600", range: "0 \u2013 99 pts" },
      { name: "Silver", icon: "\u{1F948}", color: "from-gray-400 to-gray-300", range: "100 \u2013 299 pts" },
      { name: "Gold", icon: "\u{1F947}", color: "from-yellow-500 to-yellow-400", range: "300 \u2013 999 pts" },
      { name: "Platinum", icon: "\u{1F48E}", color: "from-cyan-500 to-cyan-400", range: "1,000 \u2013 4,999 pts" },
      { name: "Legendary", icon: "\u{1F451}", color: "from-purple-600 to-pink-500", range: "5,000+ pts" }
    ],
    earnItems: [
      { icon: "\u{1F3F8}", title: "Per match played", pts: "+1 pt", color: "#2AB5CE" },
      { icon: "\u26A1", title: "Per tournament", pts: "+5 pts", color: "#F0C040" },
      { icon: "\u{1F91D}", title: "Invite a player", pts: "+3 pts", color: "#A78BFA" }
    ],
    sportsSec: "SPORTS",
    sportsTitle: "A tailored experience for each sport",
    sports: [
      { icon: "\u{1F3BE}", name: "Padel", status: "Available Now", active: true },
      { icon: "\u26BD", name: "Football", status: "Coming Soon", active: false },
      { icon: "\u{1F3C0}", name: "Basketball", status: "Coming Soon", active: false },
      { icon: "\u{1F3B1}", name: "Tennis", status: "Coming Soon", active: false }
    ],
    dlSec: "DOWNLOAD",
    dlTitle: "Start your sports journey today",
    dlSub: "Available on iOS & Android \u2014 register free and join thousands of players",
    qr1: "Scan to download on App Store",
    qr2: "Scan to download on Google Play",
    tagline: "A Complete Sports Experience",
    reviews: "+15,000 Reviews",
    footerDesc: "A complete sports platform for court booking, match management, and connecting players with coaches",
    footerApp: "App",
    footerAppLinks: ["Court Booking", "Matches", "Coaches", "Points System"],
    footerCompany: "Company",
    footerCompanyLinks: ["About Us", "Privacy Policy", "Terms & Conditions", "Contact Us"],
    footerContact: "Follow Us",
    footerCopy: "\xA9 2025 SPORTA. All rights reserved.",
    footerMade: "Made with passion for every athlete \u{1F3BE}",
    phoneMorning: "Welcome",
    phoneUser: "Player Ahmed",
    phonePoints: "Explore Points System",
    phoneLevel: "\u{1F947} Gold",
    phoneActions: [{ icon: "\u{1F3F8}", label: "Match" }, { icon: "\u{1F3DF}\uFE0F", label: "Courts" }, { icon: "\u{1F3C6}", label: "Tourn." }, { icon: "\u{1F468}\u200D\u{1F3EB}", label: "Coaches" }],
    phoneCourts: "3 Nearby Courts",
    phoneMatchesTitle: "Available Matches",
    phoneMatchesAll: "See All",
    phoneMatches: [
      { court: "Royal Padel Club", time: "18:00", level: "5.0", color: "#10B981" },
      { court: "Faisaliyah Court", time: "20:00", level: "4.5", color: "#F59E0B" }
    ],
    phoneNav: ["Home", "Profile", "Matches", "Courts", "Coaches"]
  }
};
function QRPlaceholder({ label }) {
  const pattern = [
    [1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1],
    [1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0, 1],
    [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0],
    [1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1],
    [0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0],
    [1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1]
  ];
  return <div className="flex flex-col items-center gap-3">
      <div className="bg-white p-3 rounded-2xl shadow-lg shadow-black/30">
        <svg width="110" height="110" viewBox="0 0 110 110">
          {pattern.map((row, ri) => row.map((cell, ci) => cell ? <rect key={`${ri}-${ci}`} x={ci * 6.2 + 2} y={ri * 6.2 + 2} width="5.5" height="5.5" rx="0.8" fill="#060C14" /> : null))}
          <rect x="2" y="2" width="40" height="40" rx="4" fill="none" stroke="#060C14" strokeWidth="4" />
          <rect x="68" y="2" width="40" height="40" rx="4" fill="none" stroke="#060C14" strokeWidth="4" />
          <rect x="2" y="68" width="40" height="40" rx="4" fill="none" stroke="#060C14" strokeWidth="4" />
          <rect x="12" y="12" width="20" height="20" rx="2" fill="#060C14" />
          <rect x="78" y="12" width="20" height="20" rx="2" fill="#060C14" />
          <rect x="12" y="78" width="20" height="20" rx="2" fill="#060C14" />
        </svg>
      </div>
      <p className="text-white/50 text-xs text-center">{label}</p>
    </div>;
}
function useInView(threshold = 0.15) {
  const ref = useRef(null);
  const [visible, setVisible] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        setVisible(true);
        obs.disconnect();
      }
    }, { threshold });
    obs.observe(el);
    return () => obs.disconnect();
  }, []);
  return { ref, visible };
}
function Section({ children, className = "", delay = 0 }) {
  const { ref, visible } = useInView();
  return <div
    ref={ref}
    className={`section-animate ${visible ? "section-visible" : ""} ${className}`}
    style={{ transitionDelay: visible ? `${delay}ms` : "0ms" }}
  >
      {children}
    </div>;
}
const colorMap = {
  cyan: { bg: "rgba(42,181,206,0.06)", border: "rgba(42,181,206,0.25)", icon: "#2AB5CE" },
  yellow: { bg: "rgba(240,192,64,0.06)", border: "rgba(240,192,64,0.25)", icon: "#F0C040" },
  purple: { bg: "rgba(167,139,250,0.06)", border: "rgba(167,139,250,0.25)", icon: "#A78BFA" },
  emerald: { bg: "rgba(52,211,153,0.06)", border: "rgba(52,211,153,0.25)", icon: "#34D399" },
  orange: { bg: "rgba(251,146,60,0.06)", border: "rgba(251,146,60,0.25)", icon: "#FB923C" },
  pink: { bg: "rgba(244,114,182,0.06)", border: "rgba(244,114,182,0.25)", icon: "#F472B6" }
};
const featureIcons = [
  <svg viewBox="0 0 48 48" className="w-10 h-10" fill="none"><ellipse cx="24" cy="20" rx="13" ry="16" stroke="#2AB5CE" strokeWidth="2.5" /><line x1="11" y1="20" x2="37" y2="20" stroke="#2AB5CE" strokeWidth="1.5" strokeOpacity="0.5" /><line x1="11" y1="13" x2="37" y2="13" stroke="#2AB5CE" strokeWidth="1.5" strokeOpacity="0.5" /><line x1="11" y1="27" x2="37" y2="27" stroke="#2AB5CE" strokeWidth="1.5" strokeOpacity="0.5" /><line x1="24" y1="4" x2="24" y2="36" stroke="#2AB5CE" strokeWidth="1.5" strokeOpacity="0.5" /><rect x="20" y="35" width="8" height="10" rx="4" fill="#2AB5CE" fillOpacity="0.6" /><circle cx="38" cy="11" r="5" fill="#F0C040" /></svg>,
  <svg viewBox="0 0 48 48" className="w-10 h-10" fill="none"><circle cx="24" cy="24" r="18" stroke="#F0C040" strokeWidth="2.5" /><path d="M24 14 L28 20 L35 21 L30 27 L31 34 L24 31 L17 34 L18 27 L13 21 L20 20 Z" fill="#F0C040" fillOpacity="0.3" stroke="#F0C040" strokeWidth="1.5" strokeLinejoin="round" /></svg>,
  <svg viewBox="0 0 48 48" className="w-10 h-10" fill="none"><circle cx="24" cy="16" r="8" stroke="#A78BFA" strokeWidth="2.5" /><path d="M8 40 C8 30 16 26 24 26 C32 26 40 30 40 40" stroke="#A78BFA" strokeWidth="2.5" strokeLinecap="round" /><circle cx="36" cy="14" r="5" stroke="#A78BFA" strokeWidth="2" strokeDasharray="2 2" /></svg>,
  <svg viewBox="0 0 48 48" className="w-10 h-10" fill="none"><rect x="8" y="10" width="32" height="28" rx="4" stroke="#34D399" strokeWidth="2.5" /><path d="M8 18 H40" stroke="#34D399" strokeWidth="1.5" strokeOpacity="0.5" /><circle cx="16" cy="14" r="2" fill="#34D399" /><circle cx="24" cy="14" r="2" fill="#34D399" fillOpacity="0.5" /><path d="M14 26 H34 M14 32 H26" stroke="#34D399" strokeWidth="1.5" strokeLinecap="round" strokeOpacity="0.7" /></svg>,
  <svg viewBox="0 0 48 48" className="w-10 h-10" fill="none"><circle cx="24" cy="20" r="8" stroke="#FB923C" strokeWidth="2.5" /><path d="M10 42 C10 34 16 28 24 28 C32 28 38 34 38 42" stroke="#FB923C" strokeWidth="2.5" strokeLinecap="round" /><path d="M30 12 L33 9 M36 18 L40 18 M30 28 L33 31" stroke="#FB923C" strokeWidth="2" strokeLinecap="round" strokeOpacity="0.6" /></svg>,
  <svg viewBox="0 0 48 48" className="w-10 h-10" fill="none"><path d="M24 8 L28 16 L38 17 L31 24 L33 34 L24 29 L15 34 L17 24 L10 17 L20 16 Z" stroke="#F472B6" strokeWidth="2" fill="#F472B6" fillOpacity="0.15" /><circle cx="24" cy="8" r="3" fill="#F472B6" /><path d="M10 40 H38" stroke="#F472B6" strokeWidth="2" strokeLinecap="round" strokeOpacity="0.5" /></svg>
];
function App() {
  const [lang, setLang] = useState("ar");
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeSection, setActiveSection] = useState("hero");
  const t = T[lang];
  const isAr = lang === "ar";
  useEffect(() => {
    const handleScroll = () => {
      for (const id of ["hero", "features", "points", "download"]) {
        const el = document.getElementById(id);
        if (el) {
          const rect = el.getBoundingClientRect();
          if (rect.top <= 100 && rect.bottom > 100) {
            setActiveSection(id);
            break;
          }
        }
      }
    };
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);
  const scrollTo = (id) => {
    document.getElementById(id)?.scrollIntoView({ behavior: "smooth" });
    setMenuOpen(false);
  };
  const navItems = [
    ["features", t.nav.features],
    ["points", t.nav.points],
    ["download", t.nav.download]
  ];
  return <div
    className="min-h-screen text-white overflow-x-hidden lang-switch"
    style={{ background: "#060C14", fontFamily: "'Cairo', sans-serif", direction: t.dir }}
    dir={t.dir}
  >
      <style>{css}</style>

      {
    /* ── NAV ── */
  }
      <nav
    className="fixed top-0 inset-x-0 z-50 backdrop-blur-xl border-b"
    style={{ background: "rgba(6,12,20,0.88)", borderColor: "rgba(42,181,206,0.12)" }}
  >
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <img src={logo} alt="SPORTA" className="h-9 w-auto brightness-0 invert" />
          <div className="hidden md:flex items-center gap-8">
            {navItems.map(([id, label]) => <button
    key={id}
    onClick={() => scrollTo(id)}
    className={`nav-link ${!isAr ? "nav-link-ltr" : ""} text-sm transition-colors ${activeSection === id ? "text-white" : "text-white/50 hover:text-white/80"}`}
  >
                {label}
              </button>)}
          </div>
          <div className="flex items-center gap-3">
            {
    /* Language toggle */
  }
            <button
    onClick={() => setLang(lang === "ar" ? "en" : "ar")}
    className="flex items-center gap-2 px-3 py-2 rounded-full text-sm border transition-all hover:scale-105"
    style={{ background: "rgba(42,181,206,0.1)", borderColor: "rgba(42,181,206,0.3)", color: "#2AB5CE" }}
  >
              <svg viewBox="0 0 20 20" className="w-4 h-4" fill="currentColor">
                <path d="M10 2a8 8 0 100 16A8 8 0 0010 2zm0 1.5c.85 0 1.7.5 2.4 1.5H7.6c.7-1 1.55-1.5 2.4-1.5zM4 10a6 6 0 01.16-1.34H6.1a14.4 14.4 0 000 2.68H4.16A6 6 0 014 10zm.56 2.84H6.3c.27 1.03.65 1.9 1.1 2.53A6.02 6.02 0 014.56 12.84zm10.88 0a6.02 6.02 0 01-2.84 2.53c.45-.63.83-1.5 1.1-2.53h1.74zm.39-1.5H14a14.4 14.4 0 000-2.68h1.83A6 6 0 0116 10c0 .46-.05.91-.17 1.34zm-2.4-4.18c.27 1.03.41 2.13.41 3.34 0 1.21-.14 2.31-.4 3.34H10.9V6.16h2.09zM9.1 12.84H7.03a12.77 12.77 0 01-.4-3.34c0-1.21.14-2.31.4-3.34H9.1v6.68zm.9 4.32c-.85 0-1.7-.5-2.4-1.5h4.8c-.7 1-1.55 1.5-2.4 1.5zm2.44-1.79c.45-.63.83-1.5 1.1-2.53h1.74a6.02 6.02 0 01-2.84 2.53zm-6.96-2.53h1.75c.27 1.03.65 1.9 1.1 2.53a6.02 6.02 0 01-2.85-2.53zm5.71-8.69c.45.63.83 1.5 1.1 2.53H9.1c.27-1.03.65-1.9 1.1-2.53h.09z" />
              </svg>
              <span>{lang === "ar" ? "EN" : "\u0639\u0631\u0628\u064A"}</span>
            </button>
            <button
    onClick={() => scrollTo("download")}
    className="hidden md:flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-medium transition-all hover:scale-105"
    style={{ background: "linear-gradient(135deg, #2AB5CE, #1a8fa6)", boxShadow: "0 4px 20px rgba(42,181,206,0.3)" }}
  >
              {t.nav.cta}
            </button>
            <button className="md:hidden p-2" onClick={() => setMenuOpen(!menuOpen)}>
              <div className="w-5 h-0.5 bg-white mb-1.5 transition-all" style={{ transform: menuOpen ? "rotate(45deg) translateY(7px)" : "none" }} />
              <div className="w-5 h-0.5 bg-white mb-1.5" style={{ opacity: menuOpen ? 0 : 1 }} />
              <div className="w-5 h-0.5 bg-white transition-all" style={{ transform: menuOpen ? "rotate(-45deg) translateY(-7px)" : "none" }} />
            </button>
          </div>
        </div>
        {menuOpen && <div className="md:hidden border-t px-6 py-4 space-y-3" style={{ background: "rgba(6,12,20,0.97)", borderColor: "rgba(42,181,206,0.1)" }}>
            {navItems.map(([id, label]) => <button key={id} onClick={() => scrollTo(id)} className="block w-full text-white/70 py-2 hover:text-white transition-colors" style={{ textAlign: isAr ? "right" : "left" }}>{label}</button>)}
          </div>}
      </nav>

      {
    /* ── HERO ── */
  }
      <section id="hero" className="relative min-h-screen flex items-center justify-center overflow-hidden pt-20">
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-1/4 right-1/4 w-96 h-96 rounded-full blur-3xl opacity-20" style={{ background: "#2AB5CE" }} />
          <div className="absolute bottom-1/4 left-1/4 w-80 h-80 rounded-full blur-3xl opacity-10" style={{ background: "#A78BFA" }} />
          <div className="absolute top-1/2 left-1/2 w-64 h-64 rounded-full blur-3xl opacity-10" style={{ background: "#F0C040", transform: "translate(-50%,-50%)" }} />
        </div>

        {
    /* Floating icons */
  }
        <div className="absolute inset-0 pointer-events-none overflow-hidden">
          <div className="absolute top-24 right-16 opacity-25 animate-float-slow">
            <svg width="70" height="90" viewBox="0 0 70 90" fill="none">
              <ellipse cx="35" cy="32" rx="22" ry="28" stroke="#2AB5CE" strokeWidth="3" />
              <line x1="13" y1="32" x2="57" y2="32" stroke="#2AB5CE" strokeWidth="1.5" strokeOpacity="0.6" />
              <line x1="13" y1="20" x2="57" y2="20" stroke="#2AB5CE" strokeWidth="1.5" strokeOpacity="0.6" />
              <line x1="13" y1="44" x2="57" y2="44" stroke="#2AB5CE" strokeWidth="1.5" strokeOpacity="0.6" />
              <line x1="35" y1="4" x2="35" y2="60" stroke="#2AB5CE" strokeWidth="1.5" strokeOpacity="0.6" />
              <line x1="22" y1="6" x2="22" y2="58" stroke="#2AB5CE" strokeWidth="1.5" strokeOpacity="0.4" />
              <line x1="48" y1="6" x2="48" y2="58" stroke="#2AB5CE" strokeWidth="1.5" strokeOpacity="0.4" />
              <rect x="30" y="58" width="10" height="24" rx="5" fill="#2AB5CE" fillOpacity="0.5" />
            </svg>
          </div>
          <div className="absolute top-36 left-20 opacity-30 animate-float-med" style={{ animationDelay: "0.8s" }}>
            <svg width="50" height="50" viewBox="0 0 50 50" fill="none">
              <circle cx="25" cy="25" r="22" fill="#F0C040" fillOpacity="0.2" stroke="#F0C040" strokeWidth="2.5" />
              <path d="M8 20 Q25 25 42 20" stroke="#F0C040" strokeWidth="1.5" fill="none" />
              <path d="M8 30 Q25 25 42 30" stroke="#F0C040" strokeWidth="1.5" fill="none" />
            </svg>
          </div>
          <div className="absolute bottom-40 right-12 opacity-20 animate-float-fast" style={{ animationDelay: "1.5s" }}>
            <svg width="60" height="70" viewBox="0 0 60 70" fill="none">
              <path d="M12 8 H48 V28 C48 42 36 52 30 52 C24 52 12 42 12 28 Z" stroke="#F0C040" strokeWidth="2.5" fill="#F0C040" fillOpacity="0.1" />
              <path d="M12 14 C6 14 4 22 10 26" stroke="#F0C040" strokeWidth="2.5" strokeLinecap="round" />
              <path d="M48 14 C54 14 56 22 50 26" stroke="#F0C040" strokeWidth="2.5" strokeLinecap="round" />
              <rect x="24" y="52" width="12" height="10" fill="#F0C040" fillOpacity="0.4" />
              <rect x="18" y="62" width="24" height="4" rx="2" fill="#F0C040" fillOpacity="0.4" />
            </svg>
          </div>
          <div className="absolute bottom-32 left-16 opacity-25 animate-float-slow" style={{ animationDelay: "2s" }}>
            <svg width="55" height="55" viewBox="0 0 55 55" fill="none">
              <polygon points="27.5,5 33,20 49,20 36,30 41,45 27.5,36 14,45 19,30 6,20 22,20" stroke="#A78BFA" strokeWidth="2" fill="#A78BFA" fillOpacity="0.15" />
            </svg>
          </div>
          <div className="absolute top-1/3 left-8 opacity-10 animate-spin-slow">
            <svg width="100" height="100" viewBox="0 0 100 100" fill="none">
              <circle cx="50" cy="50" r="46" stroke="#2AB5CE" strokeWidth="2" strokeDasharray="8 6" />
            </svg>
          </div>
        </div>

        <div className="relative z-10 max-w-7xl mx-auto px-6 grid md:grid-cols-2 gap-16 items-center">
          <div className={`text-center ${isAr ? "md:text-right" : "md:text-left"}`}>
            <div
    className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm mb-8 border animate-fade-up"
    style={{ background: "rgba(42,181,206,0.1)", borderColor: "rgba(42,181,206,0.3)", animationDelay: "0.1s", opacity: 0 }}
  >
              <span className="w-2 h-2 rounded-full" style={{ background: "#2AB5CE", animation: "pulse-ring 2.5s infinite" }} />
              {t.badge}
            </div>
            <h1
    className="text-5xl md:text-6xl font-bold mb-6 leading-tight animate-fade-up"
    style={{ fontFamily: "'El Messiri', serif", animationDelay: "0.2s", opacity: 0 }}
  >
              {t.heroTitle1}<br />
              <span style={{ color: "#2AB5CE" }}>{t.heroTitle2}</span>
            </h1>
            <p
    className="text-lg text-white/60 mb-10 max-w-lg leading-relaxed animate-fade-up"
    style={{ animationDelay: "0.4s", opacity: 0 }}
  >
              {t.heroSub}
            </p>
            <div
    className={`flex flex-wrap justify-center ${isAr ? "md:justify-start" : "md:justify-start"} gap-4 animate-fade-up`}
    style={{ animationDelay: "0.6s", opacity: 0 }}
  >
              <button
    onClick={() => scrollTo("download")}
    className="flex items-center gap-3 px-7 py-4 rounded-2xl text-white font-semibold text-base transition-all hover:scale-105"
    style={{ background: "linear-gradient(135deg, #2AB5CE, #1a8fa6)", boxShadow: "0 8px 32px rgba(42,181,206,0.4)" }}
  >
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor"><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.7 9.05 7.42c1.31.07 2.22.72 2.98.68 1.14-.23 2.23-.96 3.45-.82 1.47.18 2.59.88 3.32 2.2-3.03 1.79-2.53 5.72.25 6.82-.65 1.73-1.51 3.45-2 3.98zm-3.4-17.2c-2.08.23-3.78 2.24-3.56 4.09 2.07.15 3.82-1.85 3.56-4.09z" /></svg>
                {t.appStore}
              </button>
              <button
    onClick={() => scrollTo("download")}
    className="flex items-center gap-3 px-7 py-4 rounded-2xl font-semibold text-base transition-all hover:scale-105 border"
    style={{ background: "rgba(255,255,255,0.05)", borderColor: "rgba(255,255,255,0.15)" }}
  >
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor"><path d="M3.18 23.87c.28.15.59.13.87-.02l12.7-7.37L13.6 12l-10.42 11.87zm16.7-9.56L5.56 6.3C5.29 6.15 5 6.13 4.72 6.28l9.14 8.72 6.02-.69zM2.85.13C2.32.47 2 1.06 2 1.76V22.23c0 .7.32 1.3.85 1.64L14.42 12 2.85.13zM19.88 10.1l-3.13-1.82-3.37 3.22 3.37 3.22 3.17-1.85c.9-.52.9-1.74-.04-2.77z" /></svg>
                {t.googlePlay}
              </button>
            </div>
          </div>

          {
    /* Phone mockup */
  }
          <div className={`hidden md:flex justify-center items-center ${isAr ? "animate-slide-right" : "animate-slide-left"}`} style={{ animationDelay: "0.3s", opacity: 0 }}>
            <div className="relative" style={{ filter: "drop-shadow(0 40px 60px rgba(42,181,206,0.18))", transform: "scale(1.35)" }}>

              {
    /* Ambient glow behind */
  }
              <div
    className="absolute rounded-[3rem] blur-3xl opacity-30 pointer-events-none"
    style={{ inset: "-20px", background: "linear-gradient(145deg,#2AB5CE,#A78BFA)" }}
  />

              {
    /* ── iPhone frame ── */
  }
              {
    /* Outer shell — titanium-look gradient border */
  }
              <div style={{
    position: "relative",
    width: 175,
    borderRadius: 28,
    padding: 3,
    background: "linear-gradient(145deg,#4a4a52,#2a2a30,#5a5a62,#1e1e24)",
    boxShadow: "0 0 0 1px rgba(255,255,255,0.08), inset 0 1px 0 rgba(255,255,255,0.15), 0 30px 80px rgba(0,0,0,0.7)"
  }}>

                {
    /* Side buttons — volume (left side) */
  }
                <div style={{ position: "absolute", left: -3, top: 80, width: 3, height: 22, borderRadius: "2px 0 0 2px", background: "linear-gradient(180deg,#555,#333)", boxShadow: "-1px 0 2px rgba(0,0,0,0.4)" }} />
                <div style={{ position: "absolute", left: -3, top: 110, width: 3, height: 22, borderRadius: "2px 0 0 2px", background: "linear-gradient(180deg,#555,#333)", boxShadow: "-1px 0 2px rgba(0,0,0,0.4)" }} />
                {
    /* Mute toggle */
  }
                <div style={{ position: "absolute", left: -3, top: 58, width: 3, height: 16, borderRadius: "2px 0 0 2px", background: "linear-gradient(180deg,#555,#333)", boxShadow: "-1px 0 2px rgba(0,0,0,0.4)" }} />
                {
    /* Power button (right side) */
  }
                <div style={{ position: "absolute", right: -3, top: 92, width: 3, height: 34, borderRadius: "0 2px 2px 0", background: "linear-gradient(180deg,#555,#333)", boxShadow: "1px 0 2px rgba(0,0,0,0.4)" }} />

                {
    /* Inner bezel */
  }
                <div style={{
    borderRadius: 26,
    overflow: "hidden",
    background: "#F8F9FA",
    position: "relative"
  }}>
                  {
    /* Real app screenshot */
  }
                  <img src={homeScreenshot} alt="Sporta app" style={{ display: "block", width: "100%", height: "auto" }} />
                </div>
              </div>
            </div>

            {
    /* Floating badges */
  }
            <div className="absolute -right-16 top-16 backdrop-blur-sm border border-white/20 rounded-2xl px-4 py-3 shadow-xl animate-float-slow" style={{ background: "rgba(255,255,255,0.08)", animationDelay: "1s" }}>
              <p className="text-xs text-white/60 mb-1">{t.matchesToday}</p>
              <p className="text-white font-bold text-lg">{t.matchesTodayVal}</p>
            </div>
            <div className="absolute -left-16 bottom-24 backdrop-blur-sm border border-white/20 rounded-2xl px-4 py-3 shadow-xl animate-float-med" style={{ background: "rgba(255,255,255,0.08)", animationDelay: "0.5s" }}>
              <p className="text-xs text-white/60 mb-1">{t.yourPoints}</p>
              <p className="font-bold text-lg" style={{ color: "#F0C040" }}>1,240 🥇</p>
            </div>
          </div>
        </div>

        <div className="absolute bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 opacity-40 animate-bounce">
          <p className="text-xs text-white/60">{t.statsSection}</p>
          <svg className="w-5 h-5" viewBox="0 0 20 20" fill="white"><path d="M10 14l-7-7h14l-7 7z" /></svg>
        </div>
      </section>

      {
    /* ── STATS MARQUEE ── */
  }
      <div className="border-y py-6 overflow-hidden" style={{ borderColor: "rgba(42,181,206,0.1)", background: "rgba(42,181,206,0.03)" }}>
        <div className="flex animate-marquee whitespace-nowrap" style={{ width: "max-content" }}>
          {[...t.stats, ...t.stats].map((s, i) => <div key={i} className="flex items-center gap-4 mx-10">
              <span className="text-2xl">{s.icon}</span>
              <span className="text-2xl font-bold" style={{ fontFamily: "'El Messiri', serif", color: "#2AB5CE" }}>{s.value}</span>
              <span className="text-white/50 text-sm">{s.label}</span>
              <span className="text-white/20 mx-4">◆</span>
            </div>)}
        </div>
      </div>

      {
    /* ── FEATURES ── */
  }
      <section id="features" className="py-28 max-w-7xl mx-auto px-6">
        <Section className="text-center mb-20">
          <p className="text-sm mb-4 font-medium" style={{ color: "#2AB5CE", letterSpacing: "0.1em" }}>{t.featuresSec}</p>
          <h2 className="text-4xl md:text-5xl font-bold mb-6" style={{ fontFamily: "'El Messiri', serif" }}>{t.featuresTitle}</h2>
          <p className="text-white/50 max-w-xl mx-auto text-lg">{t.featuresSub}</p>
        </Section>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {t.features.map((f, i) => {
    const c = colorMap[f.color];
    return <Section key={i} delay={i * 80}>
                <div
      className="feature-card h-full rounded-3xl p-7 border cursor-default"
      style={{ background: c.bg, borderColor: c.border }}
    >
                  <div className="mb-5">{featureIcons[i]}</div>
                  <h3 className="text-xl font-bold mb-3" style={{ fontFamily: "'El Messiri', serif" }}>{f.title}</h3>
                  <p className="text-white/55 text-sm leading-relaxed">{f.desc}</p>
                </div>
              </Section>;
  })}
        </div>
      </section>

      {
    /* ── POINTS ── */
  }
      <section id="points" className="py-28 relative overflow-hidden">
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-0 inset-x-0 h-px" style={{ background: "linear-gradient(90deg, transparent, rgba(42,181,206,0.3), transparent)" }} />
          <div className="absolute bottom-0 inset-x-0 h-px" style={{ background: "linear-gradient(90deg, transparent, rgba(42,181,206,0.3), transparent)" }} />
          <div className="absolute inset-0 opacity-5" style={{ backgroundImage: "radial-gradient(rgba(42,181,206,0.6) 1px, transparent 1px)", backgroundSize: "30px 30px" }} />
        </div>
        <div className="max-w-7xl mx-auto px-6">
          <Section className="text-center mb-20">
            <p className="text-sm mb-4 font-medium" style={{ color: "#F0C040", letterSpacing: "0.1em" }}>{t.pointsSec}</p>
            <h2 className="text-4xl md:text-5xl font-bold mb-6" style={{ fontFamily: "'El Messiri', serif" }}>{t.pointsTitle}</h2>
            <p className="text-white/50 max-w-xl mx-auto text-lg">{t.pointsSub}</p>
          </Section>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-16">
            {t.levels.map((l, i) => <Section key={i} delay={i * 100}>
                <div className={`rounded-3xl p-6 text-center bg-gradient-to-br ${l.color} shadow-lg hover:scale-105 transition-transform cursor-default`}>
                  <div className="text-4xl mb-3">{l.icon}</div>
                  <p className="font-bold text-lg mb-1" style={{ fontFamily: "'El Messiri', serif" }}>{l.name}</p>
                  <p className="text-white/70 text-xs">{l.range}</p>
                </div>
              </Section>)}
          </div>
          <Section>
            <div className="grid md:grid-cols-3 gap-6">
              {t.earnItems.map((item, i) => <div
    key={i}
    className="rounded-2xl p-6 border flex items-center gap-5"
    style={{ background: "rgba(255,255,255,0.04)", borderColor: "rgba(255,255,255,0.08)" }}
  >
                  <div className="text-4xl">{item.icon}</div>
                  <div>
                    <p className="text-white/60 text-sm mb-1">{item.title}</p>
                    <p className="text-2xl font-bold" style={{ color: item.color, fontFamily: "'El Messiri', serif" }}>{item.pts}</p>
                  </div>
                </div>)}
            </div>
          </Section>
        </div>
      </section>

      {
    /* ── SPORTS ── */
  }
      <section className="py-20 max-w-7xl mx-auto px-6">
        <Section className="text-center mb-14">
          <p className="text-sm mb-4 font-medium" style={{ color: "#2AB5CE", letterSpacing: "0.1em" }}>{t.sportsSec}</p>
          <h2 className="text-4xl md:text-5xl font-bold" style={{ fontFamily: "'El Messiri', serif" }}>{t.sportsTitle}</h2>
        </Section>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          {t.sports.map((s, i) => <Section key={i} delay={i * 100}>
              <div
    className={`rounded-3xl p-8 text-center border transition-all ${s.active ? "hover:scale-105 cursor-pointer" : "opacity-50"}`}
    style={{ background: s.active ? "rgba(42,181,206,0.08)" : "rgba(255,255,255,0.03)", borderColor: s.active ? "rgba(42,181,206,0.3)" : "rgba(255,255,255,0.08)" }}
  >
                <div className="text-5xl mb-4">{s.icon}</div>
                <p className="font-bold text-lg mb-2" style={{ fontFamily: "'El Messiri', serif" }}>{s.name}</p>
                <span
    className="text-xs px-3 py-1 rounded-full"
    style={{ background: s.active ? "rgba(42,181,206,0.2)" : "rgba(255,255,255,0.1)", color: s.active ? "#2AB5CE" : "rgba(255,255,255,0.5)" }}
  >
                  {s.status}
                </span>
              </div>
            </Section>)}
        </div>
      </section>

      {
    /* ── DOWNLOAD ── */
  }
      <section id="download" className="py-28 relative overflow-hidden">
        <div className="absolute inset-0 pointer-events-none">
          <div
    className="absolute top-1/2 left-1/2 w-[600px] h-[600px] rounded-full blur-3xl opacity-12 -translate-x-1/2 -translate-y-1/2"
    style={{ background: "radial-gradient(circle, #2AB5CE, transparent)" }}
  />
        </div>
        <div className="max-w-7xl mx-auto px-6">
          <Section className="text-center mb-20">
            <p className="text-sm mb-4 font-medium" style={{ color: "#2AB5CE", letterSpacing: "0.1em" }}>{t.dlSec}</p>
            <h2 className="text-4xl md:text-5xl font-bold mb-6" style={{ fontFamily: "'El Messiri', serif" }}>{t.dlTitle}</h2>
            <p className="text-white/50 max-w-xl mx-auto text-lg">{t.dlSub}</p>
          </Section>
          <Section>
            <div className="rounded-3xl p-12 border" style={{ background: "linear-gradient(135deg, rgba(42,181,206,0.08), rgba(10,37,64,0.3))", borderColor: "rgba(42,181,206,0.2)" }}>
              <div className="grid md:grid-cols-3 gap-12 items-center">
                <div className="flex flex-col items-center gap-6">
                  <QRPlaceholder label={t.qr1} />
                  <button
    className="flex items-center gap-3 px-6 py-3 rounded-2xl text-white font-medium text-sm w-full justify-center border border-white/20"
    style={{ background: "rgba(255,255,255,0.08)" }}
  >
                    <svg className="w-6 h-6" viewBox="0 0 24 24" fill="white"><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.7 9.05 7.42c1.31.07 2.22.72 2.98.68 1.14-.23 2.23-.96 3.45-.82 1.47.18 2.59.88 3.32 2.2-3.03 1.79-2.53 5.72.25 6.82-.65 1.73-1.51 3.45-2 3.98zm-3.4-17.2c-2.08.23-3.78 2.24-3.56 4.09 2.07.15 3.82-1.85 3.56-4.09z" /></svg>
                    {t.appStore}
                  </button>
                </div>
                <div className="flex flex-col items-center gap-6 text-center">
                  <div
    className="w-24 h-24 rounded-3xl flex items-center justify-center p-4 shadow-2xl animate-pulse-ring"
    style={{ background: "linear-gradient(135deg, #2AB5CE, #1a8fa6)" }}
  >
                    <img src={logo} alt="SPORTA" className="w-full brightness-0 invert" />
                  </div>
                  <div>
                    <p className="text-2xl font-bold mb-2" style={{ fontFamily: "'El Messiri', serif" }}>SPORTA</p>
                    <p className="text-white/50 text-sm">{t.tagline}</p>
                  </div>
                  <div className="flex gap-1">{[...Array(5)].map((_, i) => <span key={i} className="text-yellow-400 text-xl">★</span>)}</div>
                  <p className="text-white/40 text-xs">{t.reviews}</p>
                </div>
                <div className="flex flex-col items-center gap-6">
                  <QRPlaceholder label={t.qr2} />
                  <button
    className="flex items-center gap-3 px-6 py-3 rounded-2xl text-white font-medium text-sm w-full justify-center border border-white/20"
    style={{ background: "rgba(255,255,255,0.08)" }}
  >
                    <svg className="w-6 h-6" viewBox="0 0 24 24" fill="white"><path d="M3.18 23.87c.28.15.59.13.87-.02l12.7-7.37L13.6 12l-10.42 11.87zm16.7-9.56L5.56 6.3C5.29 6.15 5 6.13 4.72 6.28l9.14 8.72 6.02-.69zM2.85.13C2.32.47 2 1.06 2 1.76V22.23c0 .7.32 1.3.85 1.64L14.42 12 2.85.13zM19.88 10.1l-3.13-1.82-3.37 3.22 3.37 3.22 3.17-1.85c.9-.52.9-1.74-.04-2.77z" /></svg>
                    {t.googlePlay}
                  </button>
                </div>
              </div>
            </div>
          </Section>
        </div>
      </section>

      {
    /* ── FOOTER ── */
  }
      <footer className="border-t py-12 px-6" style={{ borderColor: "rgba(42,181,206,0.1)", background: "rgba(42,181,206,0.03)" }}>
        <div className="max-w-7xl mx-auto">
          <div className="grid md:grid-cols-4 gap-10 mb-12">
            <div>
              <img src={logo} alt="SPORTA" className="h-10 w-auto brightness-0 invert mb-4" />
              <p className="text-white/40 text-sm leading-relaxed">{t.footerDesc}</p>
            </div>
            <div>
              <p className="font-semibold mb-4 text-white/80">{t.footerApp}</p>
              <ul className="space-y-2.5 text-sm text-white/40">
                {t.footerAppLinks.map((l) => <li key={l} className="hover:text-white/70 transition-colors cursor-pointer">{l}</li>)}
              </ul>
            </div>
            <div>
              <p className="font-semibold mb-4 text-white/80">{t.footerCompany}</p>
              <ul className="space-y-2.5 text-sm text-white/40">
                {t.footerCompanyLinks.map((l) => <li key={l} className="hover:text-white/70 transition-colors cursor-pointer">{l}</li>)}
              </ul>
            </div>
            <div>
              <p className="font-semibold mb-4 text-white/80">{t.footerContact}</p>
              <div className="flex gap-3">
                {["\u{1D54F}", "in", "f", "\u25B6"].map((icon, i) => <button key={i} className="w-10 h-10 rounded-xl flex items-center justify-center text-sm border border-white/10 text-white/50 hover:text-white hover:border-white/30 transition-all">{icon}</button>)}
              </div>
            </div>
          </div>
          <div className="border-t pt-8 flex flex-col md:flex-row justify-between items-center gap-4" style={{ borderColor: "rgba(255,255,255,0.06)" }}>
            <p className="text-white/30 text-sm">{t.footerCopy}</p>
            <p className="text-white/20 text-xs">{t.footerMade}</p>
          </div>
        </div>
      </footer>
    </div>;
}
export {
  App as default
};
