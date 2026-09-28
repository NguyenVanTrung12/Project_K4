import HomePage from "./layout/HomePage.jsx";
import TopMenu from "./layout/components/header.jsx";
import Footer from "./layout/components/footer.jsx";
import LawyersPage from "./layout/LawyersPage.jsx";
import LawyerManagement from "./admin/LawyerManagement";
import {
  BrowserRouter,
  Routes,
  Route,
  Outlet,
} from "react-router-dom";

import ServicesPage from "./layout/ServicePage.jsx";
import AboutPage from "./layout/AboutPage.jsx";
import NewsPage from "./layout/NewsPage.jsx";
import ContactPage from "./layout/ContactPage.jsx";
import DetailLawyerPage from "./layout/DetailLawyerPage.jsx";
import DetailServicePage from "./layout/DetailServicePage.jsx";
import Login from "./layout/Login.jsx";
import Register from "./layout/Register.jsx";
import BookingPage from "./layout/BookingPage.jsx";
import ProfilePage from "./layout/ProfilePage.jsx";
import AdminPage from "./admin/AdminPage.jsx";


/* =====================================================
   LAYOUT CHUNG
   Có Header + Footer
===================================================== */

function MainLayout() {
  return (
    <>
      <TopMenu />

      <main>
        <Outlet />
      </main>

      <Footer />
    </>
  );
}


/* =====================================================
   APP
===================================================== */

function App() {
  return (
    <BrowserRouter>

      <Routes>

        {/* ==============================================
            CÁC TRANG CÓ HEADER + FOOTER
        ============================================== */}

        <Route element={<MainLayout />}>

          <Route
            path="/"
            element={<HomePage />}
          />

          <Route
            path="/lawyers"
            element={<LawyersPage />}
          />

          <Route
            path="/services"
            element={<ServicesPage />}
          />

          <Route
            path="/about"
            element={<AboutPage />}
          />

          <Route
            path="/news"
            element={<NewsPage />}
          />

          <Route
            path="/contact"
            element={<ContactPage />}
          />

          <Route
            path="/lawyers/:id"
            element={<DetailLawyerPage />}
          />

          <Route
            path="/services/:id"
            element={<DetailServicePage />}
          />
          <Route
            path="/booking"
            element={<BookingPage />}
          />
          <Route
            path="/profile/*"
            element={<ProfilePage />}
          />
          
        </Route>


        {/* ==============================================
            LOGIN
            KHÔNG CÓ HEADER + FOOTER
        ============================================== */}

        <Route
          path="/login"
          element={<Login />}
        />
        <Route
          path="/register"
          element={<Register />}
        />
        <Route
            path="/admin/*"
            element={<AdminPage />}
          />

      </Routes>

    </BrowserRouter>
  );
}

export default App;