"use client"

import { useLang } from "@/lib/i18n"

export function ScreensSection() {
  const { t } = useLang()

  return (
    <section id="screens" className="border-b border-border/70 py-20 md:py-28">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <p className="text-xs font-semibold tracking-[0.18em] text-muted-foreground">{t.screensKicker}</p>
        <h2 className="mt-3 max-w-2xl text-balance text-3xl font-semibold tracking-tight text-foreground md:text-4xl">
          {t.screensTitle}
        </h2>

        <div className="mt-14 grid grid-cols-2 gap-8 lg:grid-cols-4">
          {t.screens.map((group) => (
            <div key={group.group}>
              <h3 className="text-[11px] font-semibold tracking-[0.14em] text-gold-foreground">
                <span className="border-b-2 border-gold pb-1">{group.group.toUpperCase()}</span>
              </h3>
              <ul className="mt-4 flex flex-col gap-3">
                {group.items.map((item) => (
                  <li key={item} className="text-sm leading-relaxed text-foreground">
                    {item}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
