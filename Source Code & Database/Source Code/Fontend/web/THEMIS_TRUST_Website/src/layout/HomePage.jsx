import HeroBanner from "./homepage/banner.jsx";
import StatisticsSection from "./homepage/staticSection.jsx";
import LegalServicesSection from "./homepage/legalServicesSection.jsx";
import FeaturedLawyersSection from "./homepage/featuredLawyersSection.jsx";
import HowItWorksSection from "./homepage/howItWorksSection.jsx";
import TestimonialsSection from "./homepage/testimonialsSection.jsx";


function HomePage() {
  return (
    <>
      <HeroBanner />
      <StatisticsSection />
      <LegalServicesSection />
      <FeaturedLawyersSection />
      <HowItWorksSection />
      <TestimonialsSection />
    </>
  );
}

export default HomePage;