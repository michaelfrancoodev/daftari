import { SiteHeader } from "@/components/site-header"
import { HeroSection } from "@/components/hero-section"
import { FeaturesSection } from "@/components/features-section"
import { HowItWorks } from "@/components/how-it-works"
import { ScreensSection } from "@/components/screens-section"
import { DownloadSection } from "@/components/download-section"
import { SiteFooter } from "@/components/site-footer"

export default function Page() {
  return (
    <main>
      <SiteHeader />
      <HeroSection />
      <FeaturesSection />
      <HowItWorks />
      <ScreensSection />
      <DownloadSection />
      <SiteFooter />
    </main>
  )
}
