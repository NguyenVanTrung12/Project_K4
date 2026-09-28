import ContactFeatures from "./contact/ContactFeatures";
import ContactForm from "./contact/ContactForm";
import ContactHero from "./contact/ContactHero";
import VisitOffice from "./contact/VisitOffice";



function ContactPage() {
  return (
    <>
      <ContactHero />
      <ContactFeatures />
      <ContactForm />
      <VisitOffice />
    </>
  );
}

export default ContactPage;