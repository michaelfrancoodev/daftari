"use client"

import { useLang } from "@/lib/i18n"
import { LedgerCard } from "@/components/ledger-card"

const REPO_URL = process.env.NEXT_PUBLIC_REPO_URL || "https://github.com/daftari-app/daftari"

export function HeroSection() {
  const { t } = useLang()

  return (
    <section id="top" className="relative overflow-hidden border-b border-border/70">
      <div className="mx-auto grid max-w-6xl gap-12 px-4 py-16 sm:px-6 md:grid-cols-[1.15fr_0.85fr] md:items-center md:py-24">
        <div>
          <p className="text-xs font-semibold tracking-[0.18em] text-muted-foreground">{t.heroKicker}</p>

          <h1 className="mt-5 text-balance text-4xl font-semibold leading-[1.15] tracking-tight text-foreground md:text-5xl">
            {t.heroTitle}
          </h1>

          <p className="mt-6 max-w-xl text-pretty text-base leading-relaxed text-muted-foreground md:text-lg">
            {t.heroBody}
          </p>

          <div className="mt-9 flex flex-wrap items-center gap-3">
            <a
              href={`${REPO_URL}/releases`}
              target="_blank"
              rel="noreferrer"
              className="inline-flex h-14 items-center rounded-xl bg-primary px-7 text-sm font-semibold text-primary-foreground transition-opacity hover:opacity-90"
            >
              {t.ctaDownload}
            </a>
            <a
              href="/app"
              className="inline-flex h-14 items-center rounded-xl border-[1.5px] border-primary px-7 text-sm font-semibold text-primary transition-colors hover:bg-primary/5"
            >
              {t.ctaTry}
            </a>
          </div>
          <p className="mt-3 text-xs text-muted-foreground">{t.apkMeta}</p>

          <dl className="mt-12 grid grid-cols-2 gap-6 border-t border-border pt-8 sm:grid-cols-4">
            {[
              [t.statFiles, "10"],
              [t.statTests, "120+"],
              [t.statScreens, "16"],
              [t.statLang, "2"],
            ].map(([label, value]) => (
              <div key={label as string}>
                <dt className="text-[11px] font-medium tracking-wide text-muted-foreground">{label}</dt>
                <dd className="tabular mt-1 text-2xl font-semibold text-foreground">{value}</dd>
              </div>
            ))}
          </dl>
        </div>

        <div className="flex justify-center md:justify-end">
          <LedgerCard />
        </div>
      </div>
    </section>
  )
}
