import { useEffect,useState } from "react";
import { useParams } from "react-router-dom";
import { api } from "../api/api";
import LawyerCareer from "./detailLawyer/LawyerCareer";
import LawyerHero from "./detailLawyer/LawyerHero";
import LawyerIntroduction from "./detailLawyer/LawyerIntroduction";
import LawyerStats from "./detailLawyer/LawyerStats";
export default function DetailLawyerPage(){const {id}=useParams();const [lawyer,setLawyer]=useState(null);const [error,setError]=useState("");useEffect(()=>{api.get(`/lawyers/${id}`).then(setLawyer).catch(e=>setError(e.message))},[id]);if(error)return <div style={{padding:"80px",textAlign:"center"}}>{error}</div>;if(!lawyer)return <div style={{padding:"80px",textAlign:"center"}}>Đang tải hồ sơ luật sư...</div>;return <><LawyerHero lawyer={lawyer}/><LawyerStats lawyer={lawyer}/><LawyerIntroduction lawyer={{...lawyer,name:lawyer.fullName,fullName:lawyer.fullName,position:lawyer.title,introduction:lawyer.bio||"Luật sư của THEMIS TRUST đồng hành cùng khách hàng trong các vấn đề pháp lý.",specialty:lawyer.practiceAreas?.join(", "),languages:"Tiếng Việt",image:lawyer.avatarUrl||"/images/lawyers/ls1.png"}}/><LawyerCareer lawyer={lawyer}/></>}
