import { Analytics } from "@vercel/analytics/next"
import type { Metadata, Viewport } from "next"
import { Geist, Geist_Mono } from "next/font/google"
import { LangProvider } from "@/lib/i18n"
import "./globals.css"

const geistSans = Geist({ subsets: ["latin"], variable: "--font-geist-sans" })
const geistMono = Geist_Mono({ subsets: ["latin"], variable: "--font-geist-mono" })

export const metadata: Metadata = {
  title: "DAFTARI — A ledger that cannot be lost",
  description:
    "Speak or type one sentence. DAFTARI splits it into events, works with no network, and shows what each gram actually cost you — your own arithmetic, never a market price. Kiswahili na Kiingereza.",
  generator: "v0.app",
  applicationName: "DAFTARI",
  keywords: ["DAFTARI", "gold mining ledger", "offline app", "Tanzania", "artisanal mining", "Swahili"],
  icons: {
    icon: "/icon.png",
    apple: "/icon.png",
  },
  openGraph: {
    title: "DAFTARI — A ledger that cannot be lost",
    description: "Works with no network. Shows your own real cost per gram — never a market price.",
    type: "website",
  },
}

export const viewport: Viewport = {
  colorScheme: "light",
  themeColor: "#0B1B2B",
  width: "device-width",
  initialScale: 1,
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="sw" className={`${geistSans.variable} ${geistMono.variable} bg-background`}>
      <body className="font-sans antialiased">
        <LangProvider>{children}</LangProvider>
        {process.env.NODE_ENV === "production" && <Analytics />}
      </body>
    </html>
  )
}
