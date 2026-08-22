"use client"

import { useLang } from "@/lib/i18n"

/**
 * A static illustration of the Batch screen (Screen 10 in the Master
 * Specification), replacing what used to be a live gold-price panel here.
 *
 * DAFTARI deliberately does not display, fetch, or claim any "gold price"
 * anywhere in this product — gold varies by purity, grade, and buyer, so a
 * single published figure would misrepresent what any individual miner
 * actually receives. What DAFTARI shows instead is arithmetic entirely
 * within the user's own control: what they spent, divided by what they
 * produced. The numbers below are a fixed illustrative example, not a
 * live feed of any kind.
 */
export function LedgerCard() {
  const { t } = useLang()

  return (
    <div className="w-full max-w-xs rounded-2xl border border-border bg-card p-6 shadow-sm">
      <p className="text-[11px] font-semibold tracking-[0.14em] text-muted-foreground">{t.ledgerCardTitle}</p>

      <div className="mt-3">
        <p className="text-[11px] font-medium text-muted-foreground">{t.ledgerCardCostLabel}</p>
        <p className="tabular mt-1 text-4xl font-semibold tracking-tight text-foreground">146,429</p>
        <p className="text-xs text-muted-foreground">TZS / g</p>
      </div>

      <div className="mt-5 space-y-2.5 border-t border-border pt-4 text-sm">
        <div className="flex items-center justify-between">
          <span className="text-muted-foreground">{t.ledgerCardYieldLabel}</span>
          <span className="tabular font-medium text-foreground">4.20 g</span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-muted-foreground">{t.ledgerCardTotalLabel}</span>
          <span className="tabular font-medium text-foreground">615,000</span>
        </div>
      </div>

      <p className="mt-5 border-t border-border pt-3 text-[11px] leading-relaxed text-muted-foreground">
        {t.ledgerCardNote}
      </p>
    </div>
  )
}
