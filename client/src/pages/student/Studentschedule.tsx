import { useEffect, useState } from "react";
import { Calendar, Clock, Link2, User, BookOpen, Video } from "lucide-react";
import axios from "axios";

interface StudentInfo {
  name: string;
  group_name: string;
  schedule: string;
  meeting_link: string;
  teacher_name: string;
  level_name: string;
}

export default function StudentSchedule() {
  const [info, setInfo] = useState<StudentInfo | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem("token");
    axios
      .get("http://localhost:5000/api/student/info", {
        headers: { Authorization: `Bearer ${token}` },
      })
      .then((res) => {
        setInfo(res.data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  // Parse schedule: "Lundi 14:00-16:00, Mercredi 10:00-12:00"
  
const parseSchedule = (schedule: string) => {
  if (!schedule) return [];
  if (schedule.includes(",")) {
    return schedule.split(",").map((s) => {
      const parts = s.trim().split(" ");
      return { day: parts[0] || "", time: parts.slice(1).join(" ") || "" };
    });
  }
  if (schedule.includes("&")) {
    const timeMatch = schedule.match(/\d{2}:\d{2}-\d{2}:\d{2}/);
    const time = timeMatch ? timeMatch[0] : "";
    const days = schedule.replace(time, "").split("&").map((d) => d.trim());
    return days.map((day) => ({ day, time }));
  }
  const parts = schedule.trim().split(" ");
  return [{ day: parts[0] || "", time: parts.slice(1).join(" ") || "" }];
};
  const dayColors: Record<string, string> = {
    Lundi:    "bg-blue-100 text-blue-700 border-blue-200",
    Mardi:    "bg-purple-100 text-purple-700 border-purple-200",
    Mercredi: "bg-green-100 text-green-700 border-green-200",
    Jeudi:    "bg-yellow-100 text-yellow-700 border-yellow-200",
    Vendredi: "bg-orange-100 text-orange-700 border-orange-200",
    Samedi:   "bg-pink-100 text-pink-700 border-pink-200",
    Dimanche: "bg-red-100 text-red-700 border-red-200",
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
      </div>
    );
  }

  if (!info || !info.group_name) {
    return (
      <div className="flex flex-col items-center justify-center h-64 text-slate-400 gap-3">
        <Calendar size={48} className="opacity-30" />
        <p className="text-lg">Aucun emploi du temps disponible</p>
      </div>
    );
  }

  const sessions = parseSchedule(info.schedule);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-slate-900 flex items-center gap-3">
          <Calendar className="text-blue-600" size={30} />
          Mon Emploi du Temps
        </h1>
        <p className="mt-1 text-slate-500">
          Planning de vos séances de cours
        </p>
      </div>

      {/* Infos groupe */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100 flex items-center gap-4">
          <div className="w-11 h-11 rounded-xl bg-blue-100 flex items-center justify-center">
            <BookOpen size={20} className="text-blue-600" />
          </div>
          <div>
            <p className="text-xs text-slate-400 font-medium uppercase tracking-wide">Groupe</p>
            <p className="text-slate-800 font-semibold">{info.group_name}</p>
          </div>
        </div>

        <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100 flex items-center gap-4">
          <div className="w-11 h-11 rounded-xl bg-purple-100 flex items-center justify-center">
            <User size={20} className="text-purple-600" />
          </div>
          <div>
            <p className="text-xs text-slate-400 font-medium uppercase tracking-wide">Enseignant</p>
            <p className="text-slate-800 font-semibold">{info.teacher_name || "—"}</p>
          </div>
        </div>

        <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100 flex items-center gap-4">
          <div className="w-11 h-11 rounded-xl bg-green-100 flex items-center justify-center">
            <BookOpen size={20} className="text-green-600" />
          </div>
          <div>
            <p className="text-xs text-slate-400 font-medium uppercase tracking-wide">Niveau</p>
            <p className="text-slate-800 font-semibold">{info.level_name || "—"}</p>
          </div>
        </div>
      </div>

      {/* Sessions */}
      <div className="rounded-2xl bg-white p-6 shadow-sm border border-slate-100">
        <h2 className="text-lg font-semibold text-slate-800 mb-5 flex items-center gap-2">
          <Clock size={20} className="text-blue-500" />
          Séances programmées
        </h2>

        {sessions.length === 0 ? (
          <div className="flex flex-col items-center py-10 text-slate-300 gap-2">
            <Clock size={40} />
            <p>Aucune séance définie</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {sessions.map((session, i) => {
              const colorClass =
                dayColors[session.day] || "bg-slate-100 text-slate-700 border-slate-200";
              return (
                <div
                  key={i}
                  className={`flex items-center justify-between rounded-xl border px-5 py-4 ${colorClass}`}
                >
                  <div className="flex items-center gap-3">
                    <Calendar size={18} />
                    <span className="font-semibold">{session.day}</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm font-medium">
                    <Clock size={15} />
                    {session.time || "—"}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Lien Meet */}
      {info.meeting_link && (
        <div className="rounded-2xl bg-gradient-to-r from-blue-500 to-blue-600 p-6 shadow-sm text-white flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-white/20 flex items-center justify-center">
              <Video size={22} className="text-white" />
            </div>
            <div>
              <p className="font-semibold text-lg">Rejoindre la séance en ligne</p>
              <p className="text-blue-100 text-sm">Cliquez pour accéder à la visioconférence</p>
            </div>
          </div>
          <a
            href={info.meeting_link}
            target="_blank"
            rel="noreferrer"
            className="flex items-center gap-2 bg-white text-blue-600 font-semibold px-5 py-3 rounded-xl hover:bg-blue-50 transition-colors"
          >
            <Link2 size={16} />
            Rejoindre
          </a>
        </div>
      )}
    </div>
  );
}