import FeaturedArticles from "./newspage/FeaturedArticles";
import LatestArticles from "./newspage/LatestArticles";
import NewsCategoryBar from "./newspage/NewsCategoryBar";
import NewsHero from "./newspage/NewsHero";


function NewsPage() {
  return (
    <>
      <NewsHero />
      <NewsCategoryBar />
      <FeaturedArticles />
      <LatestArticles />
    </>
  );
}

export default NewsPage;