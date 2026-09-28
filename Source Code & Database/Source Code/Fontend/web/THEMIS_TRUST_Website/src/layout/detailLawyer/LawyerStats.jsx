import React from "react";

import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

import {
  faUsers,
  faAward,
  faShieldHalved,
  faScaleBalanced,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/detailLawyer/LawyerStats.css";

const LawyerStats = ({ lawyer }) => {
  const stats = [
    {
      icon: faUsers,
      number: `${lawyer?.casesWon || 0}+`,
      label: "Năm kinh nghiệm",
    },
    {
      icon: faAward,
      number: `${lawyer?.yearsExp || 0}+`,
      label: "Vụ việc thành công",
    },
    {
      icon: faShieldHalved,
      number: `${Number(lawyer?.ratingAvg || 0).toFixed(1)}/5`,
      label: "Điểm đánh giá",
    },
    {
      icon: faScaleBalanced,
      number: lawyer?.isAvailable ? "Đang nhận" : "Tạm ngưng",
      label: "Trạng thái",
    },
  ];

  return (
    <section className="lawyer-stats">
      <div className="lawyer-stats__container">

        {stats.map((item, index) => (
          <React.Fragment key={item.number}>

            <div className="lawyer-stat">

              {/* ICON */}
              <div className="lawyer-stat__icon">
                <FontAwesomeIcon icon={item.icon} />
              </div>

              {/* CONTENT */}
              <div className="lawyer-stat__content">

                <div className="lawyer-stat__number">
                  {item.number}
                </div>

                <div className="lawyer-stat__label">
                  {item.label}
                </div>

              </div>

            </div>

            {/* DIVIDER */}
            {index < stats.length - 1 && (
              <div className="lawyer-stat__divider"></div>
            )}

          </React.Fragment>
        ))}

      </div>
    </section>
  );
};

export default LawyerStats;