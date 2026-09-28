import { useEffect, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { api } from "../../api/api";

import {
  faStar,
  faArrowRight,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/homepage/testimonialsSection.css";

function TestimonialsSection() {
  const [testimonials,setTestimonials]=useState([]);
  useEffect(()=>{api.get("/reviews/latest?take=3").then(data=>setTestimonials(Array.isArray(data)?data:[])).catch(console.error)},[]);
  return <section className="testimonials-section"><div className="testimonials-container"><div className="testimonials-header"><div><span className="testimonials-label">KHÁCH HÀNG NÓI VỀ CHÚNG TÔI</span><h2>Niềm tin từ khách hàng</h2></div></div><div className="testimonials-grid">{testimonials.map((t)=><div className="testimonial-card" key={t.id}><div className="testimonial-top"><div className="testimonial-avatar" style={{display:"grid",placeItems:"center"}}>{t.clientName?.charAt(0)}</div><p className="testimonial-content">"{t.comment}"</p></div><div className="testimonial-bottom"><div className="customer-info"><h3>{t.clientName}</h3><p>Khách hàng • Luật sư {t.lawyerName}</p></div><div className="testimonial-rating">{[...Array(t.rating)].map((_,i)=><FontAwesomeIcon key={i} icon={faStar}/>)}</div></div></div>)}</div>{!testimonials.length&&<p>Chưa có đánh giá.</p>}</div></section>;
}
export default TestimonialsSection;