import { useEffect, useState } from "react";
import axios from "axios";
import { getToken } from "../../services/auth";
import { FileText, Link as LinkIcon, Eye } from "lucide-react";

const API = "http://localhost:5000/api";

interface Resource {
  id: number; title: string; description: string;
  type: string; file_url: string; created_at: string;
}

export default function StudentResources() {
  const [resources, setResources] = useState<Resource[]>([]);

  useEffect(() => {
    axios.get(`${API}/student/resources`, {
      headers: { Authorization: `Bearer ${getToken()}` },
    }).then((res) => setResources(res.data)).catch(() => {});
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Ressources</h1>
        <p className="mt-1 text-slate-500">Ressources partagées par votre enseignant</p>
      </div>

      <div className="rounded-2xl bg-white p-6 shadow-sm">
        {resources.length === 0 ? (
          <p className="text-center text-slate-400 py-8">Aucune ressource disponible.</p>
        ) : (
          <div className="space-y-3">
            {resources.map((r) => (
              <div key={r.id} className="flex items-center justify-between rounded-xl border border-slate-100 p-4 hover:bg-slate-50">
                <div className="flex items-center gap-3">
                  {r.type === "pdf"
                    ? <FileText size={20} className="text-red-500" />
                    : <LinkIcon size={20} className="text-blue-500" />
                  }
                  <div>
                    <p className="font-medium text-slate-800">{r.title}</p>
                    {r.description && <p className="text-sm text-slate-400">{r.description}</p>}
                  </div>
                </div>
                <a href={r.file_url} target="_blank" rel="noopener noreferrer"
                  className="flex items-center gap-1 rounded-lg bg-blue-50 px-3 py-2 text-sm text-blue-600 hover:bg-blue-100">
                  <Eye size={16} /> Voir
                </a>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}