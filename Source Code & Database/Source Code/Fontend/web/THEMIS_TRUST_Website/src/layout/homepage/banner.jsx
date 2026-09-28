import "../../assets/css/homepage/banner.css";
const HeroBanner = () => {
  const popularSearches = [
    "Tranh chấp đất đai",
    "Ly hôn",
    "Thành lập công ty",
    "Tư vấn hình sự",
    "Hợp đồng",
  ];

  return (
    <section className="hero">
      <div className="hero-overlay"></div>

      <div className="hero-container">
        {/* LEFT CONTENT */}
        <div className="hero-content">
          <p className="hero-subtitle">
            KẾT NỐI BẠN VỚI LUẬT SƯ UY TÍN
          </p>

          <h1>
            Tìm đúng luật sư
            <br />
            cho vấn đề của bạn
          </h1>

          <p className="hero-description">
            THEMIS TRUST giúp bạn dễ dàng tìm kiếm luật sư phù hợp
            và nhận tư vấn pháp lý chuyên nghiệp, nhanh chóng, bảo mật.
          </p>

          {/* SEARCH */}
          <div className="hero-search">
            <div className="search-input-wrapper">
              <span className="search-icon">⌕</span>

              <input
                type="text"
                placeholder="Bạn đang cần hỗ trợ về vấn đề gì? (ví dụ: tranh chấp đất đai, ly hôn, doanh nghiệp...)"
              />
            </div>

            <button className="search-button">
              Tìm luật sư
            </button>
          </div>

          {/* POPULAR SEARCH */}
          <div className="popular-search">
            <span>Tìm kiếm phổ biến:</span>

            <div className="popular-tags">
              {popularSearches.map((item) => (
                <button key={item} className="popular-tag">
                  {item}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* RIGHT CONTENT */}
        <div className="hero-features">
          <div className="hero-feature">
            <div className="feature-icon"><i class="fa-solid fa-scale-balanced"></i></div>

            <div>
              <h4>Luật sư uy tín</h4>
              <p>
                Đội ngũ luật sư giàu kinh nghiệm,
                chuyên môn cao.
              </p>
            </div>
          </div>

          <div className="hero-feature">
            <div className="feature-icon"><i class="fa-solid fa-shield-halved"></i></div>

            <div>
              <h4>Bảo mật tuyệt đối</h4>
              <p>
                Thông tin cá nhân và hồ sơ
                được bảo vệ an toàn.
              </p>
            </div>
          </div>

          <div className="hero-feature">
            <div className="feature-icon"><i class="fa-solid fa-headset"></i></div>

            <div>
              <h4>Hỗ trợ 24/7</h4>
              <p>
                Luôn sẵn sàng đồng hành
                cùng bạn.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HeroBanner;