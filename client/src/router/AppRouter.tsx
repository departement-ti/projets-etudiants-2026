import { BrowserRouter, Routes, Route } from "react-router-dom";
import AdminLayout from "../layout/AdminLayout";
import ProtectedRoute from "../components/ProtectedRoute";
import Login from "../pages/Login";
import Dashboard from "../pages/Dashboard";
import Levels from "../pages/Levels";
import Teachers from "../pages/Teachers";
import Students from "../pages/Students";
import Groups from "../pages/Groups";
import Resources from "../pages/Resources";
import Messages from "../pages/Messages";
import ContactMessages from "../pages/ContactMessages";
import Settings from "../pages/Settings";
import Profile from "../pages/Profile";
import Attendance from "../pages/Attendance";
import RegistrationRequests from "../pages/RegistrationRequests";
import Categories from "../pages/Categories";
import ForgotPassword from "../pages/ForgotPassword";
import ResetPassword from "../pages/ResetPassword";

// Teacher Pages Imports
import TeacherLayout from "../layout/TeacherLayout";
import TeacherDashboard from "../pages/teacher/TeacherDashboard";
import TeacherClasses from "../pages/teacher/TeacherClasses";
import TeacherProfile from "../pages/teacher/TeacherProfile";
import TeacherResources from "../pages/teacher/TeacherResources";
import TeacherAttendance from "../pages/teacher/TeacherAttendance";
import TeacherMessages from "../pages/teacher/TeacherMessages";

// Student Pages Imports
import StudentLayout from "../layout/StudentLayout";
import StudentDashboard from "../pages/student/StudentDashboard";
import StudentResources from "../pages/student/StudentResources";
import StudentAttendance from "../pages/student/StudentAttendance";
import StudentProfile from "../pages/student/StudentProfile";
import StudentClasses from "../pages/student/StudentClasses";
import StudentMessages from "../pages/student/StudentMessages";
import StudentSchedule from "../pages/student/StudentSchedule";

// Public Pages Imports
import PublicLayout from "../layout/PublicLayout";
import HomePage from "../pages/public/HomePage";
import ContactPage from "../pages/public/ContactPage";
import RegisterPage from "../pages/public/RegisterPage";
import NiveauxPage from "../pages/public/NiveauxPage";
import AvisPage from "../pages/public/AvisPage";


export default function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>

        {/* Public routes */}
        <Route path="/" element={<PublicLayout />}>
          <Route index element={<HomePage />} />
          <Route path="contact" element={<ContactPage />} />
          <Route path="register" element={<RegisterPage />} />
          <Route path="niveaux" element={<NiveauxPage />} />
          <Route path="avis" element={<AvisPage />} />
        </Route>

        {/* Login */}
        <Route path="/login" element={<Login />} />

        {/* Forgot / Reset Password */}
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/reset-password" element={<ResetPassword />} />

        {/* Admin routes */}
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute allowedRoles={["admin"]}>
              <AdminLayout />
            </ProtectedRoute>
          }
        >
          <Route index element={<Dashboard />} />
          <Route path="levels" element={<Levels />} />
          <Route path="teachers" element={<Teachers />} />
          <Route path="students" element={<Students />} />
          <Route path="groups" element={<Groups />} />
          <Route path="resources" element={<Resources />} />
          <Route path="messages" element={<Messages />} />
          <Route path="contact-messages" element={<ContactMessages />} />
          <Route path="settings" element={<Settings />} />
          <Route path="profile" element={<Profile />} />
          <Route path="attendance" element={<Attendance />} />
          <Route path="registration-requests" element={<RegistrationRequests />} />
          <Route path="formations" element={<Categories />} />
        </Route>

        {/* Teacher routes */}
        <Route
          path="/teacher"
          element={
            <ProtectedRoute allowedRoles={["teacher"]}>
              <TeacherLayout />
            </ProtectedRoute>
          }
        >
          <Route index element={<TeacherDashboard />} />
          <Route path="classes" element={<TeacherClasses />} />
          <Route path="profile" element={<TeacherProfile />} />
          <Route path="resources" element={<TeacherResources />} />
          <Route path="attendance" element={<TeacherAttendance />} />
          <Route path="messages" element={<TeacherMessages />} />
        </Route>

        {/* Student routes */}
        <Route
          path="/student"
          element={
            <ProtectedRoute allowedRoles={["student"]}>
              <StudentLayout />
            </ProtectedRoute>
          }
        >
          <Route index element={<StudentDashboard />} />
          <Route path="resources" element={<StudentResources />} />
          <Route path="attendance" element={<StudentAttendance />} />
          <Route path="profile" element={<StudentProfile />} />
          <Route path="classes" element={<StudentClasses />} />
          <Route path="messages" element={<StudentMessages />} />
          <Route path="schedule" element={<StudentSchedule />} />
        </Route>

      </Routes>
    </BrowserRouter>
  );
}