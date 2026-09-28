import {
  faUserTie,
  faUsers,
  faScaleBalanced,
  faCircleCheck,
} from "@fortawesome/free-solid-svg-icons";
import { useEffect, useState } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { api } from "../../api/api";
import "../../assets/css/homepage/staticSection.css";


function StatisticsSection() {
  const [stats, setStats] = useState({ lawyers: 0, clients: 0, cases: 0, rating: 0 });
  useEffect(() => { api.get("/dashboard/public-stats").then(setStats).catch(console.error) }, []);
  const statistics = [
    { icon: faUserTie, number: `${stats.lawyers} +`, title: "Luật sư chuyên môn" },
    { icon: faUsers, number: `${stats.clients} +`, title: "Khách hàng tin tưởng" },
    { icon: faScaleBalanced, number: `${stats.cases} +`, title: "Vụ việc đã hỗ trợ" },
    { icon: faCircleCheck, number: `${stats.rating}/5`, title: "Điểm đánh giá trung bình" },
  ];
  return <section className="statistics-section"><div className="statistics-container">{statistics.map((item, index) => <div className="statistic-item" key={index}><div className="statistic-icon"><FontAwesomeIcon icon={item.icon} /></div><div className="statistic-content"><h3>{item.number}</h3><p>{item.title}</p></div></div>)}</div></section>;
}
export default StatisticsSection;