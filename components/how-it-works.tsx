"use client"

import { useLang } from "@/lib/i18n"

export function HowItWorks() {
  const { t } = useLang()

  return (
    <section id="how" className="border-b border-border/70 bg-secondary/40 py-20 md:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <p className="text-xs font-semibold tracking-[0.18em] text-muted-foreground">{t.howKicker}</p>
        <h2 className="mt-3 max-w-2xl text-balance text-3xl font-semibold tracking-tight text-foreground md:text-4xl">
          {t.howTitle}
        </h2>

        <ol className="mt-14 grid gap-10 md:grid-cols-3 md:gap-8">
          {t.howSteps.map((step, i) => (
            <li key={step.t} className="relative pl-0">
              <div className="flex items-center gap-3">
                <span className="tabular flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary text-sm font-semibold text-primary-foreground">
                  {step.n}
                </span>
                {i < t.howSteps.length - 1 && <span className="hidden h-px flex-1 bg-border md:block" aria-hidden />}
              </div>
              <h3 className="mt-5 text-base font-semibold text-foreground">{step.t}</h3>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{step.d}</p>
            </li>
          ))}
        </ol>
      </div>
    </section>
  )
}
