import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
    faArrowRight,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/contact/VisitOffice.css";

const VisitOffice = () => {
    return (
        <section className="visit-office">
            <div className="visit-office-container">

                {/* MAP */}
                {/* MAP */}
                <div className="visit-map">
                    <iframe
                        src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3723.9451474226444!2d105.78290877503161!3d21.034880680615956!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3135ab4a5bbeaaab%3A0x6c2adbfef28c1be1!2zS1RYIFRoxINuZyBMb25nLCA2NiBD4buRbSBWw7JuZywgbMOgbmcgVsOybmcsIEPhuqd1IEdp4bqleSwgSMOgIE7hu5lpIDEwMDAwMCwgVmnhu4d0IE5hbQ!5e0!3m2!1svi!2s!4v1788684317641!5m2!1svi!2s"
                        loading="lazy"
                        allowFullScreen
                        referrerPolicy="strict-origin-when-cross-origin"
                        title="Vị trí văn phòng THEMIS TRUST"
                    />
                </div>


                {/* CONTENT */}
                <div className="visit-content">

                    <div className="visit-label">
                        <span>ĐẾN THĂM VĂN PHÒNG</span>
                        <div className="visit-label-line"></div>
                    </div>

                    <h2>
                        Chúng tôi rất hân hạnh
                        <br />
                        được đón tiếp bạn
                    </h2>

                    <p>
                        Bạn có thể đến trực tiếp văn phòng để trao đổi chi tiết hơn
                        với đội ngũ luật sư của chúng tôi.
                    </p>

                    <button className="visit-button">
                        <span>Xem đường đi</span>

                        <FontAwesomeIcon icon={faArrowRight} />
                    </button>

                </div>


                {/* OFFICE IMAGE */}
                <div className="visit-image">

                    <img
                        src="../../src/assets/images/banner/banner4.png"
                        alt="Văn phòng THEMIS TRUST"
                    />

                    <div className="image-overlay"></div>

                    

                </div>

            </div>
        </section>
    );
};

export default VisitOffice;