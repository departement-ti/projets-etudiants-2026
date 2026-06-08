import { useEffect, useState } from "react";
import axios from "axios";
import { getToken } from "../../services/auth";
import { Calendar, Link as LinkIcon, User, BookOpen, Video, GraduationCap } from "lucide-react";

const API = "http://localhost:5000/api";

export default function StudentClasses() {
  const [info, setInfo] = useState<any>(null);

  useEffect(() => {
    axios.get(`${API}/student/info`, {
      headers: { Authorization: `Bearer ${getToken()}` },
    }).then((res) => setInfo(res.data)).catch(() => {});
  }, []);

  if (!info?.group_name) return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Ma Classe</h1>
        <p className="mt-1 text-slate-500">Détails de votre classe</p>
      </div>
      <div className="rounded-2xl bg-white p-12 shadow-sm text-center">
        <GraduationCap size={48} className="mx-auto mb-4 text-slate-300" />
        <p className="text-slate-400 font-medium">Vous n'êtes assigné à aucune classe.</p>
        <p className="text-slate-300 text-sm mt-1">Contactez l'administration pour plus d'informations.</p>
      </div>
    </div>
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Ma Classe</h1>
        <p className="mt-1 text-slate-500">Détails de votre classe</p>
      </div>

      {/* Carte principale */}
      <div className="rounded-2xl bg-gradient-to-br from-blue-600 to-indigo-700 p-6 shadow-lg text-white">
        <div className="flex items-center gap-3 mb-2">
          <div className="rounded-xl bg-white/20 p-2">
            <BookOpen size={22} className="text-white" />
          </div>
          <p className="text-blue-100 text-sm">Classe assignée</p>
        </div>
        <h2 className="text-2xl font-bold mt-1">{info.group_name}</h2>
        {info.level_name && (
          <span className="mt-2 inline-block rounded-full bg-white/20 px-3 py-1 text-xs text-white">
            {info.level_name}
          </span>
        )}
      </div>

      {/* Infos détaillées */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">

        {/* Enseignant */}
        <div className="rounded-2xl bg-white p-5 shadow-sm flex items-center gap-4">
          <div className="rounded-xl bg-violet-50 p-3">
            <User size={22} className="text-violet-500" />
          </div>
          <div>
            <p className="text-xs text-slate-400 mb-1">Enseignant</p>
            <p className="font-semibold text-slate-800">{info.teacher_name || "-"}</p>
          </div>
        </div>

        {/* Horaire */}
        <div className="rounded-2xl bg-white p-5 shadow-sm flex items-center gap-4">
          <div className="rounded-xl bg-orange-50 p-3">
            <Calendar size={22} className="text-orange-500" />
          </div>
          <div>
            <p className="text-xs text-slate-400 mb-1">Horaire</p>
            <p className="font-semibold text-slate-800">{info.schedule || "-"}</p>
          </div>
        </div>
      </div>

      {/* Lien Meet */}
      {info.meeting_link && (
        <div className="rounded-2xl bg-white p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="rounded-xl bg-green-50 p-3">
                <Video size={22} className="text-green-500" />
              </div>
              <div>
                <p className="text-xs text-slate-400 mb-1">Lien de réunion</p>
                <p className="font-semibold text-slate-800">Cours en ligne disponible</p>
              </div>
            </div>
            <a
              href={info.meeting_link}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 rounded-xl bg-green-500 px-5 py-2.5 text-sm font-medium text-white hover:bg-green-600 transition-colors"
            >
              <LinkIcon size={16} />
              Rejoindre
            </a>
          </div>
        </div>
      )}
    </div>
  );
}