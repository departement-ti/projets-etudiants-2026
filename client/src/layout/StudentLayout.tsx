import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { logout } from "../services/auth";
import { 
  LayoutDashboard, 
  BookOpen, 
  FileText, 
  Calendar, 
  User, 
  MessageSquare,
  CalendarDays // ✅ تم إضافة أيقونة جدول المواعيد الجديد
} from "lucide-react";

export default function StudentLayout() {
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  const links = [
    { to: "/student", label: "Tableau de bord", icon: <LayoutDashboard size={18} /> },
    { to: "/student/classes", label: "Ma Classe", icon: <BookOpen size={18} /> },
    { to: "/student/schedule", label: "Emploi du Temps", icon: <CalendarDays size={18} /> }, // ✅ الرابط الجديد الذي طلبته
    { to: "/student/resources", label: "Ressources", icon: <FileText size={18} /> },
    { to: "/student/attendance", label: "Mes Présences", icon: <Calendar size={18} /> },
    { to: "/student/messages", label: "Messagerie", icon: <MessageSquare size={18} /> },
    { to: "/student/profile", label: "Mon Profil", icon: <User size={18} /> },
  ];

  return (
    <div className="flex min-h-screen bg-slate-50">
      <aside className="w-64 bg-white shadow-sm p-6 flex flex-col border-r border-slate-100">
        <h1 className="text-xl font-bold text-slate-900 mb-8">Espace Étudiant</h1>
        <nav className="flex flex-col gap-1 flex-1">
          {links.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.to === "/student"}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition ${
                  isActive
                    ? "bg-blue-50 text-blue-600"
                    : "text-slate-600 hover:bg-slate-50"
                }`
              }
            >
              {link.icon}
              {link.label}
            </NavLink>
          ))}
        </nav>
        
        <div className="pt-4 border-t border-slate-100">
          <button
            onClick={handleLogout}
            className="flex items-center gap-3 w-full text-sm text-slate-400 hover:text-red-500 transition px-4 py-2"
          >
            Déconnexion
          </button>
        </div>
      </aside>

      <main className="flex-1 p-8 overflow-y-auto">
        {/* سيتم عرض محتوى الصفحات هنا بناءً على الرابط المختار */}
        <Outlet />
      </main>
    </div>
  );
}