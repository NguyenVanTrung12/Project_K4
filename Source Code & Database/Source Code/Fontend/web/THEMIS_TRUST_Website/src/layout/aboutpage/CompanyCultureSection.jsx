import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faUsers,
  faChartLine,
  faHeart,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/aboutpage/CompanyCultureSection.css";

const CompanyCultureSection = () => {
  const values = [
    {
      icon: faUsers,
      title: "Đoàn kết",
      description: (
        <>
          Cùng nhau tạo nên
          <br />
          sức mạnh
        </>
      ),
    },
    {
      icon: faChartLine,
      title: "Phát triển",
      description: (
        <>
          Không ngừng học hỏi
          <br />
          và đổi mới
        </>
      ),
    },
    {
      icon: faHeart,
      title: "Trách nhiệm",
      description: (
        <>
          Vì khách hàng và
          <br />
          vì cộng đồng
        </>
      ),
    },
  ];

  return (
    <section className="culture-section">
      <div className="culture-container">

        {/* LEFT - IMAGE */}
        <div className="culture-image-wrapper">
          <img
            src="../../src/assets/images/banner/banner4.png"
            alt="Văn phòng Themis Trust"
            className="culture-image"
          />
        </div>

        {/* RIGHT - CONTENT */}
        <div className="culture-content">

          <div className="culture-label">
            VĂN HÓA DOANH NGHIỆP
          </div>

          <h2 className="culture-title">
            Con người là giá trị cốt lõi
          </h2>

          <p className="culture-description">
            Chúng tôi xây dựng môi trường làm việc chuyên nghiệp,
            tôn trọng và đề cao sự phát triển của mỗi cá nhân.
            Mỗi thành viên tại THEMIS TRUST đều chung một mục tiêu:
            mang đến những giá trị pháp lý tốt nhất cho khách hàng
            và cộng đồng.
          </p>

          {/* VALUES */}
          <div className="culture-values">
            {values.map((item, index) => (
              <div className="culture-value" key={index}>

                <div className="culture-icon">
                  <FontAwesomeIcon icon={item.icon} />
                </div>

                <h3>{item.title}</h3>

                <p>{item.description}</p>

              </div>
            ))}
          </div>

        </div>
      </div>
    </section>
  );
};

export default CompanyCultureSection;