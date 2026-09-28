import "../../assets/css/aboutpage/AboutHero.css";

const AboutHero = () => {
    return (
        <section className="about-hero">

            {/* Lớp phủ màu */}
            <div className="about-hero-overlay"></div>

            <div className="about-hero-container">

                <div className="about-hero-content">

                    {/* Label */}
                    <div className="about-hero-label">
                        <span>VỀ CHÚNG TÔI</span>
                        <span className="about-hero-line"></span>
                    </div>

                    {/* Title */}
                    <h1>
                        Công lý hôm nay
                        <br />
                        cho một ngày mai tốt đẹp hơn
                    </h1>

                    {/* Description */}
                    <p>
                        THEMIS TRUST luôn đồng hành cùng khách hàng bằng
                        sự chuyên nghiệp, tận tâm và cam kết mang đến giải pháp pháp lý
                        toàn diện, hiệu quả và bền vững.
                    </p>

                </div>

                {/* Quote bên phải */}
                <div className="about-hero-quote">

                    <div className="quote-text">
                        JUSTICE
                        <br />
                        BUILDS
                        <br />
                        A BRIGHTER
                        <br />
                        TOMORROW
                    </div>
                    <div className="quote-source">
                        <p>Công lý kiến tạo một ngày mai tươi sáng hơn.</p>
                    </div>
                    <div className="quote-line"></div>

                </div>

            </div>

        </section>
    );
};

export default AboutHero;