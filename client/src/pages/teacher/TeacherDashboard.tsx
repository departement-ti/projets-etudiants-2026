import { useEffect, useState } from "react";
import axios from "axios";
import { getToken, getUser } from "../../services/auth";

const API = "http://localhost:5000/api";

export default function TeacherDashboard() {
  const [classes, setClasses] = useState([]);
  const user = getUser();

  useEffect(() => {
    axios.get(`${API}/teacher/classes`, {
      headers: { Authorization: `Bearer ${getToken()}` }
    }).then(res => setClasses(res.data)).catch(() => {});
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">
          Bonjour, {user?.full_name} 👋
        </h1>
        <p className="mt-1 text-slate-500">Bienvenue dans votre espace enseignant</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
        <div className="rounded-2xl bg-white p-6 shadow-sm border border-slate-100">
          <p className="text-sm text-slate-500">Mes Classes</p>
          <p className="text-3xl font-bold text-slate-900 mt-2">{classes.length}</p>
        </div>
      </div>

      {/* Classes */}
      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <h2 className="text-xl font-semibold text-slate-800 mb-4">Mes Classes</h2>
        {classes.length === 0 ? (
          <p className="text-slate-400 text-center py-8">Aucune classe assignée.</p>
        ) : (
          <div className="space-y-3">
            {classes.map((cls: any) => (
              <div key={cls.id} className="flex items-center justify-between rounded-xl border border-slate-100 p-4">
                <div>
                  <p className="font-semibold text-slate-800">{cls.name}</p>
                  <p className="text-sm text-slate-500">{cls.level_name} • {cls.schedule}</p>
                </div>
                {cls.meeting_link && (
                  <a href={cls.meeting_link} target="_blank" rel="noopener noreferrer"
                    className="rounded-xl bg-blue-500 px-4 py-2 text-sm text-white hover:bg-blue-600">
                    Rejoindre
                  </a>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}