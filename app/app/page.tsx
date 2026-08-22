"use client"

import Link from "next/link"
import { ArrowLeft, Code2, Smartphone } from "lucide-react"
import { SiteHeader } from "@/components/site-header"
import { SiteFooter } from "@/components/site-footer"
import { useLang } from "@/lib/i18n"

const REPO_URL = process.env.NEXT_PUBLIC_REPO_URL || "https://github.com/daftari-app/daftari"

/**
 * Route: /app — reserved for the compiled Flutter web build.
 *
 * Honesty over polish: building that bundle requires the Flutter SDK,
 * which this environment does not have and cannot download (pub.dev is
 * not reachable from here). Rather than fabricate a fake demo, this page
 * says so plainly and points at the real build instructions. Running
 * `flutter build web` from flutter/daftari and deploying the output here
 * is a documented step in DEPLOYMENT.md.
 */
export default function AppPage() {
  const { lang } = useLang()
  const sw = lang === "sw"

  return (
    <main>
      <SiteHeader />
      <div className="mx-auto flex max-w-xl flex-col items-center px-4 py-20 text-center sm:px-6">
        <Smartphone className="h-10 w-10 text-gold" />
        <h1 className="mt-4 text-2xl font-bold tracking-tight text-foreground">
          {sw ? "Toleo la Web bado halijajengwa hapa" : "The web build is not deployed here yet"}
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
          {sw
            ? "Programu ya Flutter inahitaji kujengwa na Flutter SDK kabla ya kuwekwa hapa (amri: flutter build web ndani ya flutter/daftari). Hatua hii imeandikwa kikamilifu kwenye DEPLOYMENT.md ya mradi."
            : "The Flutter app needs to be compiled with the Flutter SDK before it can be served here (flutter build web, run inside flutter/daftari). That step is documented in full in the project's DEPLOYMENT.md."}
        </p>
        <div className="mt-6 flex flex-col gap-3 sm:flex-row">
          <a
            href={REPO_URL}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center justify-center gap-2 rounded-full bg-primary px-5 py-2.5 text-sm font-semibold text-primary-foreground"
          >
            <Code2 className="h-4 w-4" />
            {sw ? "Ona Msimbo" : "View source"}
          </a>
          <Link
            href="/"
            className="inline-flex items-center justify-center gap-2 rounded-full border border-border px-5 py-2.5 text-sm font-semibold text-foreground"
          >
            <ArrowLeft className="h-4 w-4" />
            {sw ? "Rudi" : "Back home"}
          </Link>
        </div>
      </div>
      <SiteFooter />
    </main>
  )
}
