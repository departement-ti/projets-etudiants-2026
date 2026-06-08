import { useEffect, useState } from "react";
import axios from "axios";
import { getToken } from "../../services/auth";

const API = "http://localhost:5000/api";

export default function TeacherClasses() {
  const [classes, setClasses] = useState([]);

  useEffect(() => {
    axios.get(`${API}/teacher/classes`, {
      headers: { Authorization: `Bearer ${getToken()}` }
    }).then(res => setClasses(res.data)).catch(() => {});
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Mes Classes</h1>
        <p className="mt-1 text-slate-500">Gérez vos classes et vos étudiants</p>
      </div>

      <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
        {classes.map((cls: any) => (
          <div key={cls.id} className="rounded-2xl bg-white p-6 shadow-sm border border-slate-100">
            <div className="flex items-start justify-between">
              <div>
                <h2 className="text-xl font-bold text-slate-900">{cls.name}</h2>
                <p className="text-slate-500 mt-1">{cls.level_name}</p>
              </div>
              {cls.meeting_link && (
                <a href={cls.meeting_link} target="_blank" rel="noopener noreferrer"
                  className="rounded-xl bg-green-500 px-4 py-2 text-sm text-white hover:bg-green-600">
                  Google Meet
                </a>
              )}
            </div>
            {cls.schedule && (
              <div className="mt-4 rounded-xl bg-slate-50 p-3">
                <p className="text-sm text-slate-600">📅 {cls.schedule}</p>
              </div>
            )}
          </div>
        ))}
        {classes.length === 0 && (
          <p className="text-slate-400 col-span-2 text-center py-12">Aucune classe assignée.</p>
        )}
      </div>
    </div>
  );
}