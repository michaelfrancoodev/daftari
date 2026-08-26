"""
Generates ARB source files and hand-written Dart localization classes for
DAFTARI, standing in for `flutter gen-l10n` (which cannot be run in this
sandbox because the Flutter SDK / pub.dev are not reachable here).

Run this any time strings change. Output must be verified with a real
`flutter gen-l10n` run before shipping — see README.md.
"""
import json
from pathlib import Path

ROOT = Path("/home/claude/build/flutter/daftari")
L10N_DIR = ROOT / "lib" / "l10n"

# key -> (english, swahili)
STRINGS: dict[str, tuple[str, str]] = {
    # App
    "appName": ("DAFTARI", "DAFTARI"),
    "tagline": ("A ledger that cannot be lost", "Daftari isiyopotea"),

    # Generic actions
    "actionSave": ("Save", "Hifadhi"),
    "actionCancel": ("Cancel", "Ghairi"),
    "actionUndo": ("Undo", "Tengua"),
    "actionContinue": ("Continue", "Endelea"),
    "actionRetry": ("Retry", "Jaribu Tena"),
    "actionDelete": ("Delete", "Futa"),
    "actionEdit": ("Edit", "Badilisha"),
    "actionDone": ("Done", "Sawa"),
    "actionSkip": ("Skip", "Ruka"),
    "actionGetStarted": ("Get Started", "Anza"),
    "actionAnswer": ("Answer", "Jibu"),
    "actionYes": ("Yes", "Ndiyo"),
    "actionNotYet": ("Not yet", "Bado"),
    "actionSaveAll": ("Save all", "Hifadhi Zote"),
    "actionCorrect": ("Correct", "Sahihisha"),
    "actionVoid": ("Remove", "Ondoa"),
    "actionShare": ("Share", "Shiriki"),
    "actionClose": ("Close", "Funga"),
    "actionOpen": ("Open", "Fungua"),
    "actionSync": ("Sync now", "Sasisha Sasa"),
    "actionViewAll": ("View all", "Ona Zote"),

    # Onboarding — Screen 1: Language
    "onboardingLanguageTitle": ("Choose your language", "Chagua Lugha"),
    "onboardingLanguageSubtitle": (
        "No account, no permissions, no explanation needed.",
        "Hakuna akaunti, hakuna ruhusa, hakuna maelezo yanayohitajika.",
    ),

    # Onboarding — Screen 2: Role
    "onboardingRoleTitle": ("Who are you?", "Wewe ni Nani?"),
    "onboardingRoleSubtitle": ("You can change this later.", "Unaweza kubadilisha baadaye."),
    "onboardingRoleMiner": ("Miner", "Mchimbaji"),
    "onboardingRoleMinerDesc": ("I dig and sell gold", "Ninachimba na kuuza dhahabu"),
    "onboardingRoleSponsor": ("Sponsor", "Mzamini"),
    "onboardingRoleSponsorDesc": ("I provide money or equipment", "Ninatoa fedha au vifaa"),
    "onboardingRoleBuyer": ("Buyer", "Mnunuzi"),
    "onboardingRoleBuyerDesc": ("I buy gold", "Ninanunua dhahabu"),
    "onboardingRoleTrader": ("Other trader", "Mfanyabiashara Mwingine"),
    "onboardingRoleTraderDesc": ("I buy, sell, and keep track of money", "Ninanunua, kuuza, na kufuatilia pesa"),

    # Onboarding — Screen 3: Trust
    "onboardingPromisesTitle": ("Your ledger is yours", "Daftari Lako ni Lako"),
    "onboardingPromise1": ("No GPS location tracking", "Hakuna GPS"),
    "onboardingPromise2": ("No phone number required", "Hakuna namba ya simu"),
    "onboardingPromise3": ("You can delete everything, anytime", "Unaweza kufuta wakati wowote"),
    "onboardingPromise4": ("Works with no network, always", "Inafanya kazi bila mtandao"),
    "onboardingPromisesCta": ("Okay, let's start", "Sawa, Tuanze"),

    # Home
    "homeGreeting": ("Hello", "Habari"),
    "homeTodayLabel": ("Today", "Leo"),
    "homeMicHint": ("Press and speak", "Bonyeza na Ongea"),
    "homeCaptureVoice": ("Speak", "Sema"),
    "homeCaptureType": ("Type", "Andika"),
    "homeCaptureQuick": ("Quick", "Haraka"),
    "homeNoEntriesToday": ("No entries yet today", "Bado hakuna kumbukumbu leo"),
    "homeRecentReports": ("Recent reports", "Ripoti za Hivi Karibuni"),
    "homeNoRecentReports": ("Your reports will appear here once you record something", "Ripoti zako zitaonekana hapa mara utakaporekodi kitu"),
    "homeYesterday": ("Yesterday", "Jana"),

    # Capture chips — role-neutral core eight
    "chipOre": ("Ore", "Mawe"),
    "chipFuel": ("Fuel", "Mafuta"),
    "chipMilling": ("Milling", "Kusaga"),
    "chipYield": ("Yield", "Mavuno"),
    "chipWages": ("Wages", "Vibarua"),
    "chipLoan": ("Loan given", "Mkopo"),
    "chipRepayment": ("Repayment", "Marejesho"),
    "chipSale": ("Sale", "Mauzo"),
    # Generic-trader relabels
    "chipStock": ("Stock", "Bidhaa"),
    "chipPower": ("Power", "Umeme"),
    # Sponsor relabels
    "chipAdvance": ("Advance given", "Mkopo Ulotoa"),
    "chipRepaymentReceived": ("Repayment received", "Marejesho Uliyopokea"),
    # Buyer relabel
    "chipPurchase": ("Purchase", "Ununuzi"),

    # Bottom navigation
    "navHome": ("Home", "Nyumbani"),
    "navWrite": ("Write", "Andika"),
    "navQuestions": ("Questions", "Maswali"),
    "navReports": ("Reports", "Ripoti"),
    "navMore": ("More", "Zaidi"),

    # Capture screens
    "captureListening": ("Listening…", "Ninasikiliza..."),
    "captureHoldToTalk": ("Press once to start, again to stop", "Bonyeza mara moja kuanza, tena kusimamisha"),
    "captureProcessing": ("Working it out…", "Ninachakata..."),
    "captureTypedPlaceholder": (
        "Write down everything you did. The system will arrange it.",
        "Andika kila ulichofanya. Mfumo utapanga.",
    ),
    "captureStop": ("Stop", "Simamisha"),
    "captureSwitchToType": ("Type instead", "Andika badala yake"),
    "captureSwitchToVoice": ("Speak instead", "Sema badala yake"),
    "captureQuickTitle": ("Quick entry", "Kumbukumbu ya Haraka"),
    "captureQuickWho": ("Who? (optional)", "Nani? (hiari)"),

    # Review
    "reviewTitle": ("Review", "Kagua Kumbukumbu"),
    "reviewWeightLabel": ("Weight (grams)", "Uzito (gramu)"),
    "reviewAmountLabel": ("Amount", "Kiasi"),
    "reviewTotalLabel": ("Total", "Jumla"),
    "reviewSourceLabel": ("Source", "Chanzo"),
    "reviewConfirm": ("Confirm and save", "Thibitisha na Hifadhi"),
    "reviewLowConfidence": ("Not sure about this one. A tap resolves it.", "Sikuwa na uhakika. Mguso mmoja unatatua."),
    "reviewHeard": ("Heard", "Nimesikia"),
    "reviewStatusSettled": ("Settled", "Imekamilika"),
    "reviewStatusConfirmNeeded": ("Confirm", "Thibitisha"),
    "reviewTranscriptLabel": ("What you said", "Ulichosema"),
    "reviewNoTransactionsFound": (
        "I could not find a transaction in that. Try again, or type it instead.",
        "Sikupata muamala popote. Jaribu tena, au andika badala yake.",
    ),

    # Confirmation
    "confirmationSaved": ("Saved", "Nimeandika"),
    "confirmationUndoHint": ("Undo is available for a few seconds", "Unaweza kutengua ndani ya sekunde chache"),
    "confirmationThisWeek": ("This week", "Wiki hii"),
    "confirmationLastWeek": ("Last week", "Wiki iliyopita"),

    # Batch
    "batchTitle": ("This batch", "Batch Hii"),
    "batchAddAnother": ("Add another", "Ongeza Nyingine"),
    "batchSaveAll": ("Save all", "Hifadhi Zote"),
    "batchCostBreakdown": ("Costs", "Gharama"),
    "batchTotalCost": ("Total cost", "Jumla"),
    "batchYield": ("Output", "Mazao"),
    "batchCostPerGram": ("Cost per unit", "Kwa Kipimo"),
    "batchBeforeSelling": ("Before you sell", "Kabla Hujauza"),

    # Pre-sale
    "presaleTitle": ("Before you sell", "Kabla Hujauza"),
    "presaleYourGold": ("Your output", "Mazao Yako"),
    "presaleBuyerOffers": ("Buyer offers", "Mnunuzi Anatoa"),
    "presaleYourCost": ("This batch cost you", "Gharama Yako"),
    "presaleProfit": ("Profit at this offer", "Faida Ukiuza Sasa"),
    "presaleDecisionIsYours": ("The decision is yours.", "Uamuzi ni wako."),

    # Inbox / gap detection
    "inboxTitle": ("Questions", "Maswali"),
    "inboxEmpty": ("No questions right now", "Hakuna maswali kwa sasa"),
    "inboxResolve": ("Answer", "Jibu"),
    "inboxGapOreNotMilled": ("Ore bought {days} days ago — has it been milled yet?",
                             "Mawe yaliyonunuliwa siku {days} zilizopita — umeshayasaga?"),
    "inboxGapMillingNoYield": ("A mill run was recorded with no yield — how much gold came out?",
                               "Umesaga lakini hujaandika mavuno — ulipata gramu ngapi?"),
    "inboxGapLoanUnpaid": ("A loan to {counterparty} has had no repayment for over two months — still outstanding?",
                           "Mkopo kwa {counterparty} haujarejeshwa kwa zaidi ya miezi miwili — bado unadaiwa?"),

    # Day report
    "dayReportTitle": ("Today", "Siku ya Leo"),
    "dayReportTotalWeight": ("Total weight", "Uzito wa Jumla"),
    "dayReportTotalValue": ("Total value", "Thamani ya Jumla"),
    "dayReportEntryCount": ("Entries", "Idadi ya Kumbukumbu"),
    "dayReportGapWarning": ("Some entries are still incomplete", "Baadhi ya kumbukumbu bado hazijakamilika"),
    "dayReportMoneyIn": ("Money in", "Imeingia"),
    "dayReportMoneyOut": ("Money out", "Imetoka"),
    "dayReportCompleteness": ("Completeness", "Ukamilifu"),
    "dayReportYourWords": ("Your own words", "Maelezo Yako"),
    "dayReportViewOrigin": ("See the original sentence", "Ona sentensi halisi"),

    # Origin (Layer 1 — verbatim)
    "originTitle": ("Origin", "Chanzo"),
    "originVerbatim": ("What was said, exactly", "Ulichosema, kama kilivyo"),
    "originPlayAudio": ("Play recording", "Cheza Sauti"),
    "originEntriesFromThisCapture": ("Entries from this recording", "Kumbukumbu za Sauti Hii"),

    # Month report
    "monthReportTitle": ("Month report", "Ripoti ya Mwezi"),
    "monthReportAverage": ("Average price received", "Wastani wa Bei"),
    "monthReportMoneyIn": ("Money in", "Imeingia"),
    "monthReportMoneyOut": ("Money out", "Imetoka"),
    "monthReportNet": ("Net", "Faida"),
    "monthReportProduction": ("Production", "Uzalishaji"),
    "monthReportSuppliers": ("Ore suppliers", "Wauzaji wa Mawe"),
    "monthReportBuyers": ("Buyers", "Wanunuzi"),
    "monthReportCompleteness": ("Completeness", "Ukamilifu"),
    "monthReportShare": ("Share report", "Shiriki Ripoti"),

    # Settings
    "settingsTitle": ("Settings", "Mipangilio"),
    "settingsLanguage": ("Language", "Lugha"),
    "settingsRole": ("Role", "Nafasi"),
    "settingsExportData": ("Export data", "Hamisha Data"),
    "settingsAbout": ("About", "Kuhusu"),
    "settingsClearData": ("Delete all data", "Futa Data Yote"),
    "settingsClearDataConfirm": ("This cannot be undone. Delete everything?", "Hili haliwezi kutenguliwa. Futa yote?"),
    "settingsClearDataWarning": ("Every capture and entry on this device will be permanently removed.",
                                 "Kila kumbukumbu na sauti kwenye simu hii itafutwa kabisa."),
    "settingsAboutNotice": (
        "This app gives no advice on whether to sell and claims no market price. It shows your own cost and profit arithmetic only.",
        "Programu hii haitoi ushauri wa kuuza wala bei ya soko. Inaonyesha hesabu ya gharama na faida yako halisi tu.",
    ),
    "settingsVersion": ("Version", "Toleo"),

    # Units / currency
    "unitGrams": ("units", "vipimo"),
    "unitKilograms": ("kilograms", "kilo"),
    "currencyLabel": ("Shillings", "Shilingi"),

    # Errors
    "errorGeneric": ("Something went wrong. Your data is safe on this device.", "Hitilafu imetokea. Data yako iko salama kwenye simu."),
    "errorNoMicPermission": ("Microphone access is needed to record.", "Ruhusa ya kipaza sauti inahitajika kurekodi."),
    "errorNoNetwork": ("No network. Saved and will sync later.", "Hakuna mtandao. Imehifadhiwa na itasawazishwa baadaye."),
}

def write_arb(locale: str, index: int) -> None:
    data = {"@@locale": locale}
    for key, values in STRINGS.items():
        data[key] = values[index]
    path = L10N_DIR / f"app_{locale}.arb"
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {path} ({len(data) - 1} keys)")

if __name__ == "__main__":
    L10N_DIR.mkdir(parents=True, exist_ok=True)
    write_arb("sw", 1)
    write_arb("en", 0)
