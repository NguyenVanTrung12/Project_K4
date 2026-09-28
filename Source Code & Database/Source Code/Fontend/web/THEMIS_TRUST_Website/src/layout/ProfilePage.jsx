import { Routes, Route, Outlet } from "react-router-dom";

import "../../src/assets/css/userpage/ProfilePage.css";

import ProfileSidebar from "./userpage/ProfileSidebar";
import UserProfile from "./userpage/UserProfile";
import MyConsultations from "./userpage/MyConsultations";
import ConsultationRequestPage from "./userpage/ConsultationRequestPage";
import NotificationPage from "./userpage/NotificationPage";
import ChatPage from "./userpage/ChatPage";
import EditProfile from "./userpage/EditProfile";

/* =========================================================
   PROFILE LAYOUT
   Sidebar chỉ gọi 1 lần
========================================================= */

const ProfileLayout = () => {
    return (
        <div className="profile-layout">

            {/* =================================================
          SIDEBAR
      ================================================= */}

            <ProfileSidebar />


            {/* =================================================
          CONTENT
          Nội dung sẽ thay đổi theo route
      ================================================= */}

            <main className="profile-layout__content">
                <Outlet />
            </main>

        </div>
    );
};


/* =========================================================
   PROFILE PAGE
========================================================= */

const ProfilePage = () => {
    return (
        <Routes>

            <Route element={<ProfileLayout />}>

                {/* =================================================
            /profile
            Trang cá nhân
        ================================================= */}

                <Route
                    index
                    element={<UserProfile />}
                />


                {/* =================================================
            /profile/my-consultations
            Lịch tư vấn của tôi
        ================================================= */}

                <Route
                    path="my-consultations"
                    element={<MyConsultations />}
                />
                <Route
                    path="my-consultation-requests"
                    element={<ConsultationRequestPage />}
                />
                <Route
                    path="notifications"
                    element={<NotificationPage />}
                />
                <Route
                    path="chats"
                    element={<ChatPage />}
                />
                <Route
                    path="edit"
                    element={<EditProfile />}
                />
            </Route>

        </Routes>
    );
};


export default ProfilePage;