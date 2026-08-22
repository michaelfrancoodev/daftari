"use client"

import Link from "next/link"
import { ArrowLeft, MapPinOff, Phone, Trash2, WifiOff } from "lucide-react"
import { SiteHeader } from "@/components/site-header"
import { SiteFooter } from "@/components/site-footer"
import { useLang } from "@/lib/i18n"

export default function PrivacyPage() {
  const { lang } = useLang()
  const sw = lang === "sw"

  const promises = [
    { icon: MapPinOff, sw: "Hakuna GPS. Hatujui uko wapi, na hatuhitaji kujua.", en: "No GPS. We don't know where you are, and we don't need to." },
    { icon: Phone, sw: "Hakuna namba ya simu au akaunti inayohitajika kuanza.", en: "No phone number or account is required to get started." },
    { icon: Trash2, sw: "Unaweza kufuta data yako yote, wakati wowote, kwenye Mipangilio.", en: "You can delete all your data, at any time, from Settings." },
    { icon: WifiOff, sw: "Kila kitu muhimu kinafanya kazi bila mtandao. Sync ni ya hiari, siyo sharti.", en: "Everything that matters works with no network. Syncing is optional, never required." },
  ]

  return (
    <main>
      <SiteHeader />
      <div className="mx-auto max-w-2xl px-4 py-12 sm:px-6 sm:py-16">
        <Link href="/" className="mb-8 inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground">
          <ArrowLeft className="h-4 w-4" />
          {sw ? "Rudi" : "Back"}
        </Link>

        <h1 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
          {sw ? "Daftari lako ni lako" : "Your ledger is yours"}
        </h1>
        <p className="mt-4 text-base leading-relaxed text-muted-foreground">
          {sw
            ? "Hii ndiyo ahadi inayoonekana kwenye skrini ya tatu ya programu, kabla hata hujaanza kutumia. Kila ahadi hapa chini ni kikwazo halisi tulichojenga programu kuzunguka, si sentensi ya uuzaji."
            : "This is the same promise shown on the app's third onboarding screen, before you even start using it. Every promise below is a real constraint the product was designed around, not a marketing line."}
        </p>

        <div className="mt-8 space-y-4">
          {promises.map((p) => (
            <div key={p.en} className="flex items-start gap-3 rounded-xl border border-border bg-card p-4">
              <p.icon className="mt-0.5 h-5 w-5 shrink-0 text-gold" />
              <p className="text-sm leading-relaxed text-foreground">{sw ? p.sw : p.en}</p>
            </div>
          ))}
        </div>

        <p className="mt-8 text-xs leading-relaxed text-muted-foreground">
          {sw
            ? "Programu hii haitoi ushauri wa kuuza dhahabu yako. Inaonyesha hesabu na bei iliyotangazwa rasmi tu; uamuzi unabaki wako."
            : "This app gives no advice on whether to sell your gold. It shows arithmetic and the published reference price only; the decision remains yours."}
        </p>
      </div>
      <SiteFooter />
    </main>
  )
}
