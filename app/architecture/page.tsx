"use client"

import Link from "next/link"
import { ArrowLeft, Smartphone, Server, Database, Clock, ShieldCheck, Sparkles } from "lucide-react"
import { SiteHeader } from "@/components/site-header"
import { SiteFooter } from "@/components/site-footer"
import { useLang } from "@/lib/i18n"

/**
 * A plain, honest architecture page. Every box here corresponds to a real
 * file or service described in the project's README and ARCHITECTURE.md —
 * nothing here is aspirational or simulated. The landing page you are
 * reading this on is deployed separately, to Vercel; everything on this
 * page describes the Flutter app and the Google Cloud agent fleet behind
 * it, not this website's own hosting.
 */
export default function ArchitecturePage() {
  const { lang } = useLang()
  const sw = lang === "sw"

  const layers = [
    {
      icon: Smartphone,
      title: sw ? "Kifaa — chanzo cha ukweli" : "Device — the source of truth",
      items: sw
        ? [
            "Flutter (Android + Web) — lib/domain/ na lib/data/",
            "SQLite ya ndani kupitia Drift — Capture na Entry tables",
            "Interpreter, Ledger, GapDetector — kazi safi, bila mtandao",
            "Hakuna bei ya soko popote — gharama na faida ni zako mwenyewe tu",
          ]
        : [
            "Flutter (Android + Web) — lib/domain/ and lib/data/",
            "Local SQLite via Drift — Capture and Entry tables",
            "Interpreter, Ledger, GapDetector — pure functions, no network",
            "No external market price anywhere — cost and profit are the user's own only",
          ],
    },
    {
      icon: Server,
      title: sw ? "Cloud Run — wakala wanne halisi" : "Cloud Run — four real agents",
      items: sw
        ? [
            "Sikio — hutafsiri sentensi kwa Gemini (server-side refinement)",
            "Daftari — uthibitishaji na kuondoa marudio, deterministic",
            "Mkumbushi — hutambua mapengo na kutunga swali moja kwa Gemini",
            "Mlinganishi — hulinganisha rekodi za pande mbili zilizounganishwa",
          ]
        : [
            "Sikio — server-side sentence interpretation via Gemini",
            "Daftari — deterministic validation and deduplication",
            "Mkumbushi — gap detection plus one Gemini-phrased question",
            "Mlinganishi — compares two linked parties' records",
          ],
    },
    {
      icon: Clock,
      title: sw ? "Cloud Scheduler — uhuru wa kweli" : "Cloud Scheduler — real autonomy",
      items: sw
        ? [
            "Huamsha Mkumbushi kila jioni, bila kuombwa",
            "Hii ndiyo uthibitisho unaotakiwa na hackathon: agent inayofanya kazi yenyewe",
          ]
        : [
            "Wakes Mkumbushi every evening, with nobody asking",
            "This is the concrete proof the hackathon track asks for: an agent that acts on its own",
          ],
    },
    {
      icon: Database,
      title: sw ? "Hifadhi" : "Storage",
      items: sw
        ? ["Firestore — matukio yaliyosawazishwa kutoka kwa vifaa", "Secret Manager — funguo za API"]
        : ["Firestore — synced entries from devices", "Secret Manager — API keys"],
    },
    {
      icon: Sparkles,
      title: sw ? "Gemini — akili ya mawakala" : "Gemini — the agents' reasoning",
      items: sw
        ? ["Sikio na Mkumbushi hutumia Gemini kwa lugha asilia", "Daftari ni deterministic kwa makusudi — hakuna model kwa uthibitishaji wa pesa"]
        : ["Sikio and Mkumbushi use Gemini for natural language", "Daftari is deliberately deterministic — no model in the path of validating money"],
    },
    {
      icon: ShieldCheck,
      title: sw ? "Kanuni zinazoshikiliana" : "Rules holding it together",
      items: sw
        ? ["Sheria #2: kila kitu muhimu kinafanya kazi bila mtandao", "Sheria #6: pesa ni integer, kamwe decimal", "Sheria mpya: hakuna bei ya soko popote — gharama na faida ni zako tu"]
        : ["Rule #2: everything needed at the moment of decision works offline", "Rule #6: money is an integer, never a decimal", "New rule: no external market price anywhere — cost and profit are the user's own only"],
    },
  ]

  return (
    <main>
      <SiteHeader />
      <div className="mx-auto max-w-4xl px-4 py-12 sm:px-6 sm:py-16">
        <Link href="/" className="mb-8 inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground">
          <ArrowLeft className="h-4 w-4" />
          {sw ? "Rudi" : "Back"}
        </Link>

        <h1 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
          {sw ? "Muundo wa Mfumo" : "System Architecture"}
        </h1>
        <p className="mt-4 max-w-2xl text-base leading-relaxed text-muted-foreground">
          {sw
            ? "Kifaa ndicho chenye ukweli. Wingu huongeza akili kwa muda, lakini halihitajiki kwa uwezo wa msingi. Tovuti hii (landing page) inadeploy kwenye Vercel pekee; mawakala manne yaliyo hapa chini ni huduma tofauti, kila moja Cloud Run yake."
            : "The device holds the truth. The cloud adds intelligence over time but is never required for basic capability. This landing page deploys to Vercel only; the four agents below are separate services, each with its own Cloud Run deployment."}
        </p>

        <div className="mt-10 grid gap-4 sm:grid-cols-2">
          {layers.map((layer) => (
            <div key={layer.title} className="rounded-2xl border border-border bg-card p-5">
              <div className="flex items-center gap-2.5">
                <layer.icon className="h-4 w-4 text-gold" />
                <h2 className="text-sm font-semibold text-foreground">{layer.title}</h2>
              </div>
              <ul className="mt-3 space-y-1.5 text-sm leading-relaxed text-muted-foreground">
                {layer.items.map((item) => (
                  <li key={item} className="flex gap-2">
                    <span className="mt-2 h-1 w-1 shrink-0 rounded-full bg-muted-foreground" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-10 rounded-2xl border border-border bg-muted/40 p-5 text-sm leading-relaxed text-muted-foreground">
          {sw
            ? "Mtiririko: Kifaa → (mtandao ukipatikana) → Sikio/Daftari kwenye Cloud Run → Firestore. Mkumbushi anaamshwa na Cloud Scheduler kila jioni; Mlinganishi anaitwa wakati wa sync pale link ya share-code ipo."
            : "Flow: Device → (once a network appears) → Sikio/Daftari on Cloud Run → Firestore. Mkumbushi is woken by Cloud Scheduler every evening; Mlinganishi is called during sync whenever a share-code link exists."}
        </div>
      </div>
      <SiteFooter />
    </main>
  )
}
