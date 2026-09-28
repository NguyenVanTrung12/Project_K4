import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import ServiceBusinessBanner from "./detailservice/ServiceBusinessBanner";
import ServiceBusinessDetail from "./detailservice/ServiceBusinessDetail";
import { api } from "../api/api";

function DetailServicePage() {
  const { id } = useParams();
  const [service,setService]=useState(null); const [error,setError]=useState("");
  useEffect(()=>{api.get(`/services/${id}`).then(setService).catch(e=>setError(e.message))},[id]);
  if(error) return <div style={{padding:"80px",textAlign:"center"}}>{error}</div>;
  if(!service) return <div style={{padding:"80px",textAlign:"center"}}>Đang tải dịch vụ...</div>;
  const data={overview:{title:"Tổng quan dịch vụ",description:service.detail||service.description},contentTitle:"Nội dung dịch vụ",services:[{id:service.id,title:service.title,description:service.description}],processTitle:"Quy trình tư vấn",process:[{id:1,number:"01",title:"Tiếp nhận yêu cầu",description:"Lắng nghe và phân tích nhu cầu pháp lý."},{id:2,number:"02",title:"Phân tích & đề xuất",description:"Đánh giá hồ sơ và đề xuất phương án phù hợp."},{id:3,number:"03",title:"Tư vấn & triển khai",description:"Luật sư tư vấn và thực hiện công việc theo thống nhất."},{id:4,number:"04",title:"Báo cáo kết quả",description:"Cập nhật tiến độ và bàn giao kết quả cho khách hàng."}],relatedTitle:"Dịch vụ liên quan",relatedServices:[],quote:"THEMIS TRUST đồng hành cùng bạn trong từng vấn đề pháp lý."};
  return <><ServiceBusinessBanner data={{title:service.practiceAreaName,description:service.description}}/><ServiceBusinessDetail data={data}/></>;
}
export default DetailServicePage;
