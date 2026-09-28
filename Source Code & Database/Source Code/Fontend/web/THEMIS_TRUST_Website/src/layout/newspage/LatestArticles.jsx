import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faArrowRight,
  faChevronLeft,
  faChevronRight,
  faEye,
  faPlus,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/newspage/LatestArticles.css";

const articles = [
  {
    image: "https://file3.qdnd.vn/data/images/0/2026/01/14/upload_2299/1%201.jpg",
    category: "Cộng đồng pháp lý",
    date: "10 Tháng 8, 2025",
    title: "Thủ tục thành lập doanh nghiệp mới nhất năm 2025",
    description:
      "Hướng dẫn chi tiết hồ sơ, quy trình và những lưu ý quan trọng khi thành lập doanh nghiệp.",
  },
  {
    image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTFDLarDqsvsyxL3ZEBhiIsfdk1f1Iz_NgRBQwRloANqQ&s=10",
    category: "Phân tích chuyên sâu",
    date: "08 Tháng 8, 2025",
    title: "Giải quyết tranh chấp hợp đồng dân sự: Những lưu ý quan trọng",
    description:
      "Phân tích các phương thức giải quyết tranh chấp và kinh nghiệm thực tiễn từ các vụ việc điển hình.",
  },
  {
    image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTckwyGQeuF66o2U-B5NyBCTzbSg-EYS-KU8hqT7sVEhw&s=10",
    category: "Cập nhật pháp luật",
    date: "05 Tháng 8, 2025",
    title: "Chính sách mới về bất động sản và tác động đến thị trường",
    description:
      "Những quy định mới trong lĩnh vực bất động sản và dự báo xu hướng trong thời gian tới.",
  },
  {
    image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRSthZSX3XLddAXEY7glEU8ElFNPG82CHfDXXOoCpKI3S7pLOD5KnpQPIU&s=10",
    category: "Phân tích chuyên sâu",
    date: "03 Tháng 8, 2025",
    title: "Quy định mới về lao động và bảo hiểm xã hội",
    description:
      "Cập nhật những thay đổi quan trọng trong chính sách lao động, bảo hiểm xã hội và tác động đến doanh nghiệp.",
  },
  {
    image: "https://cdn.thuvienphapluat.vn//uploads/tintuc/2024/03/30/dau-tu-ra-nuoc-ngoai.png",
    category: "Hướng dẫn pháp lý",
    date: "28 Tháng 7, 2025",
    title: "Những rủi ro pháp lý trong hoạt động đầu tư nước ngoài",
    description:
      "Phân tích các rủi ro thường gặp và giải pháp pháp lý khi doanh nghiệp đầu tư tại Việt Nam.",
  },
  {
    image: "https://luattriminh.vn/wp-content/uploads/2024/09/banner-luat-tri-minh-3-3.png",
    category: "Tin nội bộ",
    date: "25 Tháng 7, 2025",
    title: "THEMIS TRUST đồng hành cùng doanh nghiệp Việt",
    description:
      "Chia sẻ về các hoạt động tư vấn, hội thảo và những dự án tiêu biểu mà chúng tôi đã thực hiện.",
  },
];

const popularArticles = [
  {
    number: "01",
    image: "https://file3.qdnd.vn/data/images/0/2026/01/14/upload_2299/1%201.jpg",
    title: "Những điểm mới quan trọng của Luật Đất đai 2024",
    date: "12 Tháng 8, 2025",
    views: "12.5K",
  },
  {
    number: "02",
    image: "https://cdn.thuvienphapluat.vn//uploads/tintuc/2024/03/30/dau-tu-ra-nuoc-ngoai.png",
    title: "Thủ tục thành lập doanh nghiệp mới nhất năm 2025",
    date: "10 Tháng 8, 2025",
    views: "9.3K",
  },
  {
    number: "03",
    image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTFDLarDqsvsyxL3ZEBhiIsfdk1f1Iz_NgRBQwRloANqQ&s=10",
    title: "Giải quyết tranh chấp hợp đồng dân sự",
    date: "08 Tháng 8, 2025",
    views: "8.1K",
  },
  {
    number: "04",
    image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTckwyGQeuF66o2U-B5NyBCTzbSg-EYS-KU8hqT7sVEhw&s=10",
    title: "Chính sách mới về bất động sản",
    date: "05 Tháng 8, 2025",
    views: "6.7K",
  },
  {
    number: "05",
    image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRkB4lAAJsVwuJ1bAe9ImaOC3B44-Doq3xCzTZd8FIh0Q&s=10",
    title: "Quy định mới về lao động và bảo hiểm xã hội",
    date: "01 Tháng 8, 2025",
    views: "5.9K",
  },
];

const LatestArticles = () => {
  return (
    <section className="latest-articles-section">
      <div className="latest-articles-container">

        {/* =========================
            LEFT - ARTICLES
        ========================== */}
        <div className="latest-articles-main">

          <div className="latest-articles-header">
            <h2>Bài viết mới nhất</h2>
          </div>

          <div className="articles-grid">
            {articles.map((article, index) => (
              <article className="article-card" key={index}>

                {/* Image */}
                <div className="article-image-wrapper">
                  <img
                    src={article.image}
                    alt={article.title}
                    className="article-image"
                  />

                  <span className="article-category">
                    {article.category}
                  </span>
                </div>

                {/* Content */}
                <div className="article-content">

                  <div className="article-date">
                    {article.date}
                  </div>

                  <h3 className="article-title">
                    {article.title}
                  </h3>

                  <p className="article-description">
                    {article.description}
                  </p>

                  <a href="#" className="article-detail">
                    Xem chi tiết

                    <FontAwesomeIcon icon={faArrowRight} />
                  </a>

                </div>
              </article>
            ))}
          </div>

          {/* =========================
              PAGINATION
          ========================== */}
          <div className="articles-pagination">

            <button className="pagination-btn">
              <FontAwesomeIcon icon={faChevronLeft} />
            </button>

            <button className="pagination-btn active">
              1
            </button>

            <button className="pagination-btn">
              2
            </button>

            <button className="pagination-btn">
              3
            </button>

            <button className="pagination-btn">
              4
            </button>

            <button className="pagination-btn">
              5
            </button>

            <button className="pagination-btn">
              <FontAwesomeIcon icon={faChevronRight} />
            </button>

          </div>
        </div>

        {/* =========================
            RIGHT - POPULAR ARTICLES
        ========================== */}
        <aside className="popular-articles">

          <div className="popular-header">
            <h2>Bài viết được quan tâm</h2>
          </div>

          <div className="popular-list">

            {popularArticles.map((article, index) => (
              <div className="popular-item" key={index}>

                {/* Number */}
                <div className="popular-number">
                  {article.number}
                </div>

                {/* Image */}
                <div className="popular-image-wrapper">
                  <img
                    src={article.image}
                    alt={article.title}
                    className="popular-image"
                  />
                </div>

                {/* Content */}
                <div className="popular-content">

                  <h3>{article.title}</h3>

                  <div className="popular-meta">

                    <span>
                      <FontAwesomeIcon icon={faPlus} />
                      {article.date}
                    </span>

                    <span>
                      <FontAwesomeIcon icon={faEye} />
                      {article.views} lượt xem
                    </span>

                  </div>

                </div>

              </div>
            ))}

          </div>

        </aside>

      </div>
    </section>
  );
};

export default LatestArticles;

