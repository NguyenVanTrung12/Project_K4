import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import {
  faTableCellsLarge,
  faFileLines,
  faChartColumn,
  faBookOpen,
  faUsers,
  faMagnifyingGlass,
} from "@fortawesome/free-solid-svg-icons";

import "../../assets/css/newspage/NewsCategoryBar.css";

const categories = [
  {
    id: "all",
    label: "Tất cả",
    icon: faTableCellsLarge,
  },
  {
    id: "legal-update",
    label: "Cập nhật pháp luật",
    icon: faFileLines,
  },
  {
    id: "analysis",
    label: "Phân tích chuyên sâu",
    icon: faChartColumn,
  },
  {
    id: "guide",
    label: "Hướng dẫn pháp lý",
    icon: faBookOpen,
  },
  {
    id: "internal",
    label: "Tin nội bộ",
    icon: faUsers,
  },
];

const NewsCategoryBar = ({
  activeCategory = "all",
  onCategoryChange,
}) => {
  const handleCategoryClick = (categoryId) => {
    if (onCategoryChange) {
      onCategoryChange(categoryId);
    }
  };

  return (
    <section className="news-category-section">
      <div className="news-category-container">

        {/* Category list */}
        <div className="news-category-list">
          {categories.map((category) => (
            <button
              key={category.id}
              type="button"
              className={`news-category-item ${
                activeCategory === category.id ? "active" : ""
              }`}
              onClick={() => handleCategoryClick(category.id)}
            >
              <span className="news-category-icon">
                <FontAwesomeIcon icon={category.icon} />
              </span>

              <span className="news-category-label">
                {category.label}
              </span>
            </button>
          ))}
        </div>

        {/* Search */}
        <div className="news-search-box">
          <input
            type="text"
            placeholder="Tìm kiếm bài viết..."
          />

          <button
            type="button"
            className="news-search-button"
          >
            <FontAwesomeIcon icon={faMagnifyingGlass} />
          </button>
        </div>

      </div>
    </section>
  );
};

export default NewsCategoryBar;