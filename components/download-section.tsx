"use client"

import { useLang } from "@/lib/i18n"

const REPO_URL = process.env.NEXT_PUBLIC_REPO_URL || "https://github.com/michaelfrancoodev/daftari"

export function DownloadSection() {
  const { t } = useLang()

  const trust = [t.trustNoLocation, t.trustNoPhone, t.trustDeletable, t.trustOffline]

  return (
    <section id="download" className="border-b border-border/70 bg-primary py-20 text-primary-foreground md:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="grid gap-10 md:grid-cols-[1fr_auto] md:items-end">
          <div>
            <p className="text-xs font-semibold tracking-[0.18em] text-primary-foreground/60">
              {t.downloadKicker}
            </p>
            <h2 className="mt-3 max-w-lg text-balance text-3xl font-semibold tracking-tight md:text-4xl">
              {t.downloadTitle}
            </h2>
            <p className="mt-4 max-w-md text-pretty text-sm leading-relaxed text-primary-foreground/70">
              {t.downloadBody}
            </p>
          </div>

          <div className="flex flex-wrap gap-3 md:justify-end">
            {/* Points at GitHub Releases rather than a fabricated
                /daftari.apk file — see docs/DEPLOYMENT.md for how a real
                signed build gets published there. */}
            <a
              href={`${REPO_URL}/releases`}
              target="_blank"
              rel="noreferrer"
              className="inline-flex h-14 items-center rounded-xl bg-gold px-7 text-sm font-semibold text-gold-foreground transition-opacity hover:opacity-90"
            >
              {t.ctaDownload}
            </a>
          </div>
        </div>

        <ul className="mt-14 grid gap-4 border-t border-primary-foreground/15 pt-8 sm:grid-cols-2 lg:grid-cols-4">
          {trust.map((item) => (
            <li key={item} className="flex items-start gap-2.5 text-sm text-primary-foreground/85">
              <span className="mt-1 h-1.5 w-1.5 shrink-0 rounded-full bg-gold" aria-hidden />
              {item}
            </li>
          ))}
        </ul>
      </div>
    </section>
  )
}
