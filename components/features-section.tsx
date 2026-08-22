"use client"

import { useLang } from "@/lib/i18n"

export function FeaturesSection() {
  const { t } = useLang()

  return (
    <section id="features" className="border-b border-border/70 py-20 md:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <p className="text-xs font-semibold tracking-[0.18em] text-muted-foreground">{t.featuresKicker}</p>
        <h2 className="mt-3 max-w-2xl text-balance text-3xl font-semibold tracking-tight text-foreground md:text-4xl">
          {t.featuresTitle}
        </h2>

        <div className="mt-14 grid gap-px overflow-hidden rounded-2xl border border-border bg-border sm:grid-cols-2 lg:grid-cols-3">
          {t.features.map((f) => (
            <div key={f.title} className="flex flex-col gap-3 bg-card p-7">
              <span className="h-1.5 w-6 rounded-full bg-gold" aria-hidden />
              <h3 className="text-base font-semibold text-foreground">{f.title}</h3>
              <p className="text-sm leading-relaxed text-muted-foreground">{f.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
