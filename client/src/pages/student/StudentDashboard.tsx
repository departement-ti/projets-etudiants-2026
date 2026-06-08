import { useEffect, useState } from "react";
import axios from "axios";
import { getToken, getUser } from "../../services/auth";
import { BookOpen, Users, CheckCircle } from "lucide-react";

const API = "http://localhost:5000/api";

export default function StudentDashboard() {
  const [info, setInfo] = useState<any>(null);
  const [attendance, setAttendance] = useState<any[]>([]);
  const user = getUser();

  useEffect(() => {
    axios.get(`${API}/student/info`, {
      headers: { Authorization: `Bearer ${getToken()}` },
    }).then((res) => setInfo(res.data)).catch(() => {});

    axios.get(`${API}/student/attendance`, {
      headers: { Authorization: `Bearer ${getToken()}` },
    }).then((res) => setAttendance(res.data)).catch(() => {});
  }, []);

  const presentCount = attendance.filter((a) => a.status === "present").length;
  const totalCount = attendance.length;
  const rate = totalCount > 0 ? Math.round((presentCount / totalCount) * 100) : 0;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">
          Bonjour, {user?.full_name} 👋
        </h1>
        <p className="mt-1 text-slate-500">Bienvenue dans votre espace étudiant</p>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-2">
            <BookOpen size={20} className="text-blue-500" />
            <p className="text-sm text-slate-500">Ma Classe</p>
          </div>
          <p className="text-2xl font-bold text-slate-900">{info?.group_name || "-"}</p>
        </div>
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-2">
            <Users size={20} className="text-purple-500" />
            <p className="text-sm text-slate-500">Niveau</p>
          </div>
          <p className="text-2xl font-bold text-slate-900">{info?.level_name || "-"}</p>
        </div>
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-2">
            <CheckCircle size={20} className="text-green-500" />
            <p className="text-sm text-slate-500">Taux de présence</p>
          </div>
          <p className="text-2xl font-bold text-slate-900">{rate}%</p>
        </div>
      </div>

      {info?.group_name && (
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-800 mb-4">Informations sur ma classe</h2>
          <div className="space-y-3 text-sm">
            <div className="flex justify-between border-b pb-2">
              <span className="text-slate-500">Groupe</span>
              <span className="font-medium">{info.group_name}</span>
            </div>
            <div className="flex justify-between border-b pb-2">
              <span className="text-slate-500">Enseignant</span>
              <span className="font-medium">{info.teacher_name || "-"}</span>
            </div>
            <div className="flex justify-between border-b pb-2">
              <span className="text-slate-500">Horaire</span>
              <span className="font-medium">{info.schedule || "-"}</span>
            </div>
            {info.meeting_link && (
              <div className="flex justify-between">
                <span className="text-slate-500">Lien de réunion</span>
                <a href={info.meeting_link} target="_blank" rel="noopener noreferrer"
                  className="text-blue-500 hover:underline font-medium">
                  Rejoindre
                </a>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}