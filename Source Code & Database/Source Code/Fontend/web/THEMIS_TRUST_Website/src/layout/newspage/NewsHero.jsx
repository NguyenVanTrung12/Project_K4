import "../../assets/css/newspage/NewsHero.css";

const NewsHero = () => {
  return (
    <section className="news-hero">
      <div className="news-hero-overlay"></div>

      <div className="news-hero-container">
        <div className="news-hero-content">

          <div className="news-hero-label">
            <span>TIN TỨC PHÁP LUẬT</span>
            <div className="news-hero-label-line"></div>
          </div>

          <h1 className="news-hero-title">
            Cập nhật tri thức pháp luật
            <br />
            Kiến tạo giá trị bền vững
          </h1>

          <p className="news-hero-description">
            Những thông tin pháp lý mới nhất, phân tích chuyên sâu và góc nhìn
            thực tiễn từ đội ngũ luật sư của THEMIS TRUST.
          </p>

        </div>

        <div className="news-hero-quote">
          <p>
            “Hiểu luật
            <br />
            để vững bước
            <br />
            tương lai.”
          </p>

          <span className="quote-line"></span>
        </div>
      </div>
    </section>
  );
};

export default NewsHero;