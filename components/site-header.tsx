"use client"

import { useState } from "react"
import Image from "next/image"
import Link from "next/link"
import { Menu, X } from "lucide-react"
import { useLang } from "@/lib/i18n"

export function SiteHeader() {
  const { lang, setLang, t } = useLang()
  const [menuOpen, setMenuOpen] = useState(false)

  const navLinks = [
    { href: "#features", label: t.navFeatures },
    { href: "#how", label: t.navHow },
    { href: "#screens", label: t.navScreens },
  ]

  return (
    <header className="sticky top-0 z-40 border-b border-border/70 bg-background/90 backdrop-blur-sm">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4 sm:px-6">
        <Link href="#top" className="flex items-center gap-2.5">
          <Image src="/logo.png" alt="" width={28} height={28} className="h-7 w-7" />
          <span className="text-sm font-semibold tracking-[0.18em] text-foreground">DAFTARI</span>
        </Link>

        {/* Desktop nav */}
        <nav className="hidden items-center gap-8 text-sm text-muted-foreground md:flex">
          {navLinks.map((link) => (
            <a key={link.href} href={link.href} className="transition-colors hover:text-foreground">
              {link.label}
            </a>
          ))}
          <a
            href="#download"
            className="rounded-full bg-primary px-4 py-2 text-xs font-semibold tracking-wide text-primary-foreground transition-opacity hover:opacity-90"
          >
            {t.navDownload}
          </a>
        </nav>

        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1 rounded-full border border-border p-1 text-xs font-medium">
            <button
              type="button"
              onClick={() => setLang("sw")}
              aria-pressed={lang === "sw"}
              className={`rounded-full px-2.5 py-1 transition-colors ${
                lang === "sw" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              SW
            </button>
            <button
              type="button"
              onClick={() => setLang("en")}
              aria-pressed={lang === "en"}
              className={`rounded-full px-2.5 py-1 transition-colors ${
                lang === "en" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              EN
            </button>
          </div>

          {/* Mobile menu toggle — the nav links have nowhere else to go
              below the md breakpoint, so without this button they were
              simply unreachable on a phone. */}
          <button
            type="button"
            onClick={() => setMenuOpen((open) => !open)}
            aria-label={menuOpen ? t.navClose : t.navMenu}
            aria-expanded={menuOpen}
            className="flex h-9 w-9 items-center justify-center rounded-full border border-border text-foreground md:hidden"
          >
            {menuOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
          </button>
        </div>
      </div>

      {/* Mobile nav panel */}
      {menuOpen && (
        <nav className="flex flex-col gap-1 border-t border-border/70 bg-background px-4 py-3 text-sm text-muted-foreground md:hidden">
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              onClick={() => setMenuOpen(false)}
              className="rounded-md px-2 py-2.5 transition-colors hover:bg-muted hover:text-foreground"
            >
              {link.label}
            </a>
          ))}
          <a
            href="#download"
            onClick={() => setMenuOpen(false)}
            className="mt-1 rounded-md bg-primary px-2 py-2.5 text-center text-xs font-semibold tracking-wide text-primary-foreground"
          >
            {t.navDownload}
          </a>
        </nav>
      )}
    </header>
  )
}
