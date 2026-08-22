"use client"

import Image from "next/image"
import Link from "next/link"
import { useLang } from "@/lib/i18n"

// Set NEXT_PUBLIC_REPO_URL when you connect this project to your own Git
// host — this is a real, working fallback rather than a fabricated link.
const REPO_URL = process.env.NEXT_PUBLIC_REPO_URL || "https://github.com/daftari-app/daftari"

export function SiteFooter() {
  const { t } = useLang()

  return (
    <footer className="py-14">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="flex flex-col gap-8 md:flex-row md:items-start md:justify-between">
          <div className="max-w-sm">
            <div className="flex items-center gap-2.5">
              <Image src="/logo.png" alt="" width={22} height={22} className="h-5.5 w-5.5" />
              <span className="text-sm font-semibold tracking-[0.18em] text-foreground">DAFTARI</span>
            </div>
            <p className="mt-3 text-sm leading-relaxed text-muted-foreground">{t.footerTagline}</p>
          </div>

          <nav className="flex flex-wrap gap-x-6 gap-y-2 text-sm text-muted-foreground">
            <a href={REPO_URL} target="_blank" rel="noreferrer" className="transition-colors hover:text-foreground">
              {t.footerRepo}
            </a>
            <Link href="/architecture" className="transition-colors hover:text-foreground">
              {t.footerArch}
            </Link>
            <Link href="/privacy" className="transition-colors hover:text-foreground">
              {t.footerPrivacy}
            </Link>
          </nav>
        </div>

        <p className="mt-10 border-t border-border pt-6 text-xs leading-relaxed text-muted-foreground">
          {t.footerNotice}
        </p>
      </div>
    </footer>
  )
}
