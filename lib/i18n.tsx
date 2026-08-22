"use client"

import { createContext, useContext, useMemo, useState, type ReactNode } from "react"

/**
 * One language at a time, never mixed — the same rule the Flutter app
 * enforces. Swahili is the template the English copy is written against
 * (Rule #10), but English is what a first-time visitor to this website
 * sees by default.
 */
export type Lang = "sw" | "en"

export const dictionary = {
  sw: {
    langName: "Kiswahili",
    otherLangName: "English",
    navFeatures: "Vipengele",
    navHow: "Jinsi Inavyofanya Kazi",
    navScreens: "Skrini",
    navDownload: "Pakua",
    navMenu: "Fungua menyu",
    navClose: "Funga menyu",
    heroKicker: "DAFTARI · Daftari lisiloweza kupotea",
    heroTitle: "Andika kwa sauti. Fanya kazi bila mtandao. Jua gharama yako ya kweli.",
    heroBody:
      "Bonyeza mara moja, ongea kadri unavyotaka, bonyeza tena kuacha. DAFTARI hugawa sentensi yako kwenye matukio, huhifadhi kila neno lako, na hukueleza gharama ya kila gramu — kutokana na pesa yako mwenyewe, si makadirio ya soko — yote bila mtandao.",
    ctaDownload: "PAKUA APK",
    apkMeta: "18 MB · Android 6.0 na juu",
    featuresKicker: "KWA NINI",
    featuresTitle: "Iliyojengwa kwa siku isiyo ya kawaida",
    features: [
      {
        title: "Sauti moja, matukio mengi",
        body: "Sentensi moja ndefu inagawanywa kiotomatiki kuwa manunuzi, mafuta, mikopo na mauzo — kila moja likiwa na neno lililotumika.",
      },
      {
        title: "Gharama kwa gramu, papo hapo",
        body: "Mara dhahabu ikitolewa, gharama ya kila gramu inahesabiwa kwenye simu, kutoka gharama zako halisi za ununuzi na uchakataji, bila mtandao, bila kusubiri.",
      },
      {
        title: "Faida yako, si bei ya jumla",
        body: "Kwa kuwa dhahabu ina aina na usafi tofauti, DAFTARI haitangazi 'bei ya dhahabu'. Inakuonyesha tu: uliuza kwa kiasi gani dhidi ya ulichogharimu — hesabu yako mwenyewe, si makadirio ya nje.",
      },
      {
        title: "Haiwaachi maswali bila jibu",
        body: "Mfumo unaona mawe yaliyonunuliwa lakini hayajasagwa, na mikopo isiyorejeshwa — na huuliza swali moja tu.",
      },
      {
        title: "Maneno yako, salama milele",
        body: "Kila kilichosemwa kinahifadhiwa bila kubadilishwa. Marekebisho huongeza safu mpya; hayafuti historia.",
      },
      {
        title: "Uamuzi ni wako",
        body: "Programu hutoa hesabu ya gharama na faida tu. Kamwe haishauri kuuza, kutouza, au thamani ya soko.",
      },
    ],
    howKicker: "JINSI INAVYOFANYA KAZI",
    howTitle: "Tabaka tatu, kamwe moja",
    howSteps: [
      { n: "1", t: "Sema au andika", d: "\u201cNimempatia Michael elfu tano... na nimekopesha laki mbili kwa Salimu.\u201d" },
      { n: "2", t: "Kagua kwa sekunde", d: "Kila kipengele kinaonyeshwa na alama ya vema au alama ya swali — hakiwezi kuzuia vingine." },
      { n: "3", t: "Hifadhi na endelea", d: "Kila kilichoandikwa kinarudi na jibu papo hapo: gharama mpya, jumla ya wiki, faida ya batch." },
    ],
    screensKicker: "SKRINI",
    screensTitle: "Kumi na sita skrini, mbili zinabeba siku",
    screens: [
      { group: "Kuanza", items: ["Lugha", "Nafasi", "Ahadi Nne"] },
      { group: "Kila Siku", items: ["Nyumbani", "Andika kwa Sauti", "Andika kwa Kuchapa", "Chagua Haraka"] },
      { group: "Kagua na Hifadhi", items: ["Kagua", "Uthibitisho", "Batch", "Kabla Hujauza"] },
      { group: "Soma Nyuma", items: ["Maswali", "Ripoti ya Siku", "Chanzo", "Ripoti ya Mwezi", "Mipangilio"] },
    ],
    downloadKicker: "PAKUA",
    downloadTitle: "Weka DAFTARI kwenye simu yako",
    downloadBody: "Inafanya kazi kwenye Android 6.0 na juu. Hauitaji akaunti, namba ya simu, wala GPS.",
    trustNoLocation: "Hakuna GPS",
    trustNoPhone: "Hakuna namba ya simu",
    trustDeletable: "Unaweza kufuta wakati wowote",
    trustOffline: "Inafanya kazi bila mtandao",
    footerTagline: "Daftari lisiloweza kupotea, kwa wachimbaji wadogo wa dhahabu.",
    footerNotice: "Programu hii haitoi ushauri wa kuuza wala bei ya soko. Inaonyesha gharama na faida yako halisi tu.",
    footerRepo: "Msimbo",
    footerArch: "Muundo",
    footerPrivacy: "Faragha",
  },
  en: {
    langName: "English",
    otherLangName: "Kiswahili",
    navFeatures: "Features",
    navHow: "How It Works",
    navScreens: "Screens",
    navDownload: "Download",
    navMenu: "Open menu",
    navClose: "Close menu",
    heroKicker: "DAFTARI · A ledger that cannot be lost",
    heroTitle: "Speak it. Work with no network. Know your real cost.",
    heroBody:
      "Press once, speak for as long as you need, press again to stop. DAFTARI splits your sentence into events, keeps every word you said, and tells you what each gram actually cost you — from your own spending, not a market estimate — all of it offline.",
    ctaDownload: "DOWNLOAD APK",
    apkMeta: "18 MB · Android 6.0 and up",
    featuresKicker: "WHY IT EXISTS",
    featuresTitle: "Built for a day that is never orderly",
    features: [
      {
        title: "One breath, several events",
        body: "One long sentence is split automatically into purchases, fuel, loans and sales — each one carrying the exact words it came from.",
      },
      {
        title: "Cost per gram, instantly",
        body: "The moment a yield is entered, cost per gram is computed on the device from your own purchase and processing costs — no network, no waiting.",
      },
      {
        title: "Your margin, not a market price",
        body: "Gold varies in purity and grade, so DAFTARI never claims a single 'gold price'. It only ever shows what you sold for against what it cost you — your own arithmetic, never an outside estimate.",
      },
      {
        title: "It never lets a gap go quiet",
        body: "The ledger notices ore that was never milled and loans that were never repaid, and asks exactly one question.",
      },
      {
        title: "Your words, kept forever",
        body: "Everything spoken is stored exactly as said. A correction adds a new row; it never erases the history.",
      },
      {
        title: "The decision stays yours",
        body: "The app reports your own cost and profit arithmetic only. It never advises whether to sell, nor claims to know a market value.",
      },
    ],
    howKicker: "HOW IT WORKS",
    howTitle: "Three layers, never one",
    howSteps: [
      { n: "1", t: "Speak or type", d: "\u201cI paid Michael five thousand... and lent two hundred thousand to Salimu.\u201d" },
      { n: "2", t: "Review in seconds", d: "Every item shows a check or a question mark — the uncertain never block the certain." },
      { n: "3", t: "Save and carry on", d: "Every entry returns something new instantly: a fresh cost, this week's total, this batch's margin." },
    ],
    screensKicker: "SCREENS",
    screensTitle: "Sixteen screens, two of which carry a day",
    screens: [
      { group: "Getting Started", items: ["Language", "Role", "Four Promises"] },
      { group: "Every Day", items: ["Home", "Voice Capture", "Typed Capture", "Quick Capture"] },
      { group: "Review & Save", items: ["Review Card", "Confirmation", "Batch", "Before You Sell"] },
      { group: "Reading Back", items: ["Inbox", "Day Report", "Origin", "Month Report", "Settings"] },
    ],
    downloadKicker: "DOWNLOAD",
    downloadTitle: "Put DAFTARI on your phone",
    downloadBody: "Works on Android 6.0 and up. No account, no phone number, no GPS required.",
    trustNoLocation: "No location collected",
    trustNoPhone: "No phone number needed",
    trustDeletable: "Delete it at any time",
    trustOffline: "Works with no network",
    footerTagline: "A ledger that cannot be lost, for small-scale gold miners.",
    footerNotice: "This app gives no advice on selling and claims no market price. It shows your own real cost and profit only.",
    footerRepo: "Code",
    footerArch: "Architecture",
    footerPrivacy: "Privacy",
  },
}

export type Dictionary = typeof dictionary.sw

const LangContext = createContext<{
  lang: Lang
  setLang: (l: Lang) => void
  t: Dictionary
} | null>(null)

export function LangProvider({ children }: { children: ReactNode }) {
  const [lang, setLang] = useState<Lang>("en")
  const value = useMemo(() => ({ lang, setLang, t: dictionary[lang] }), [lang])
  return <LangContext.Provider value={value}>{children}</LangContext.Provider>
}

export function useLang() {
  const ctx = useContext(LangContext)
  if (!ctx) throw new Error("useLang must be used within LangProvider")
  return ctx
}
