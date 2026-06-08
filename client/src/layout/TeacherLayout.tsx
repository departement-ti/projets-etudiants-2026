import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { logout } from "../services/auth";
import { LayoutDashboard, BookOpen, FileText, Calendar, MessageSquare, User } from "lucide-react";

export default function TeacherLayout() {
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  const navItems = [
    { to: "/teacher", label: "Tableau de bord", icon: <LayoutDashboard size={18} /> },
    { to: "/teacher/classes", label: "Mes Classes", icon: <BookOpen size={18} /> },
    { to: "/teacher/resources", label: "Ressources", icon: <FileText size={18} /> },
    { to: "/teacher/attendance", label: "Présences", icon: <Calendar size={18} /> },
    { to: "/teacher/messages", label: "Messagerie", icon: <MessageSquare size={18} /> },
    { to: "/teacher/profile", label: "Mon Profil", icon: <User size={18} /> },
  ];

  return (
    <div className="flex min-h-screen bg-slate-50">
      <aside className="w-64 border-r border-slate-200 bg-white">
        <div className="border-b border-slate-200 px-6 py-6">
          <h1 className="text-2xl font-bold text-slate-900">Espace Enseignant</h1>
        </div>
        <nav className="space-y-1 p-4">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === "/teacher"}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition ${
                  isActive
                    ? "bg-blue-50 text-blue-600"
                    : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
                }`
              }
            >
              {item.icon}
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="absolute bottom-6 left-4">
          <button
            onClick={handleLogout}
            className="text-sm text-slate-400 hover:text-red-500 px-4"
          >
            Déconnexion
          </button>
        </div>
      </aside>
      <div className="flex flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-slate-200 bg-white px-8 py-4">
          <p className="text-sm text-slate-500">Espace Enseignant - EduLive</p>
          <div className="flex items-center gap-6 text-sm font-medium text-slate-700">
            <NavLink to="/teacher/profile" className="hover:text-slate-900">Mon Profil</NavLink>
            <button onClick={handleLogout} className="hover:text-red-500">Déconnexion</button>
          </div>
        </header>
        <main className="flex-1 p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}