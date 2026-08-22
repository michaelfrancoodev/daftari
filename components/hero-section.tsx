"use client"

import { useLang } from "@/lib/i18n"

const REPO_URL = process.env.NEXT_PUBLIC_REPO_URL || "https://github.com/michaelfrancoodev/daftari"

export function HeroSection() {
  const { t } = useLang()

  return (
    <section id="top" className="relative overflow-hidden border-b border-border/70">
      <div className="mx-auto max-w-3xl px-4 py-16 text-center sm:px-6 md:py-24">
        <p className="text-xs font-semibold tracking-[0.18em] text-muted-foreground">{t.heroKicker}</p>

        <h1 className="mt-5 text-balance text-4xl font-semibold leading-[1.15] tracking-tight text-foreground md:text-5xl">
          {t.heroTitle}
        </h1>

        <p className="mx-auto mt-6 max-w-xl text-pretty text-base leading-relaxed text-muted-foreground md:text-lg">
          {t.heroBody}
        </p>

        <div className="mt-9 flex flex-wrap items-center justify-center gap-3">
          <a
            href={`${REPO_URL}/releases`}
            target="_blank"
            rel="noreferrer"
            className="inline-flex h-14 items-center rounded-xl bg-primary px-7 text-sm font-semibold text-primary-foreground transition-opacity hover:opacity-90"
          >
            {t.ctaDownload}
          </a>
        </div>
        <p className="mt-3 text-xs text-muted-foreground">{t.apkMeta}</p>
      </div>
    </section>
  )
}
