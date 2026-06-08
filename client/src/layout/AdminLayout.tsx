import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { logout } from "../services/auth";
import {
  LayoutDashboard, GraduationCap, ClipboardList, Users,
  BookOpen, FileText, MessageSquare, Mail, Calendar,
  User, Settings, UserCheck, Library
} from "lucide-react";

export default function AdminLayout() {
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  const navItems = [
    { to: "/dashboard", label: "Tableau de bord", icon: <LayoutDashboard size={18} /> },
    { to: "/dashboard/formations", label: "Formations", icon: <Library size={18} /> },
    { to: "/dashboard/levels", label: "Niveaux", icon: <GraduationCap size={18} /> },
    { to: "/dashboard/registration-requests", label: "Demandes d'inscription", icon: <ClipboardList size={18} /> },
    { to: "/dashboard/teachers", label: "Enseignants", icon: <UserCheck size={18} /> },
    { to: "/dashboard/students", label: "Élèves", icon: <Users size={18} /> },
    { to: "/dashboard/groups", label: "Groupes", icon: <BookOpen size={18} /> },
    { to: "/dashboard/resources", label: "Ressources", icon: <FileText size={18} /> },
    { to: "/dashboard/messages", label: "Messagerie", icon: <MessageSquare size={18} /> },
    { to: "/dashboard/contact-messages", label: "Messages Contact", icon: <Mail size={18} /> },
    { to: "/dashboard/attendance", label: "Présences", icon: <Calendar size={18} /> },
    { to: "/dashboard/profile", label: "Mon profil", icon: <User size={18} /> },
    { to: "/dashboard/settings", label: "Paramètres", icon: <Settings size={18} /> },
  ];

  return (
    <div className="flex min-h-screen bg-slate-50">
      <aside className="w-64 border-r border-slate-200 bg-white flex flex-col">
        <div className="border-b border-slate-200 px-6 py-6">
          <h1 className="text-2xl font-bold text-slate-900">Administration</h1>
        </div>
        <nav className="space-y-1 p-4 flex-1 overflow-y-auto">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === "/dashboard"}
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
        <div className="p-4 border-t border-slate-200">
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
          <p className="text-sm text-slate-500">Bienvenue, EduLive</p>
          <div className="flex items-center gap-6 text-sm font-medium text-slate-700">
            <NavLink to="/dashboard/profile" className="hover:text-slate-900">
              Mon Profil
            </NavLink>
            <button onClick={handleLogout} className="hover:text-red-500">
              Déconnexion
            </button>
          </div>
        </header>
        <main className="flex-1 p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}