import { useEffect, useState } from "react";
import axios from "axios";
import { getToken } from "../../services/auth";
import { Plus, Trash2, Eye, X, FileText, Link as LinkIcon, Video, Upload } from "lucide-react";

const API = "http://localhost:5000/api";

interface Group { id: number; name: string; }
interface Resource {
  id: number;
  title: string;
  description: string;
  type: string;
  file_url: string;
  external_url: string;
  created_at: string;
}

export default function TeacherResources() {
  const [groups, setGroups] = useState<Group[]>([]);
  const [selectedGroup, setSelectedGroup] = useState<number | "">("");
  const [resources, setResources] = useState<Resource[]>([]);
  const [showModal, setShowModal] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [success, setSuccess] = useState("");
  const [form, setForm] = useState({
    title: "",
    description: "",
    type: "pdf",
    file_url: "",
    external_url: "",
  });

  useEffect(() => {
    axios.get(`${API}/teacher/groups`, {
      headers: { Authorization: `Bearer ${getToken()}` },
    }).then((res) => {
      setGroups(res.data);
      if (res.data.length > 0) setSelectedGroup(res.data[0].id);
    }).catch(() => {});
  }, []);

  useEffect(() => {
    if (selectedGroup !== "") fetchResources();
  }, [selectedGroup]);

  const fetchResources = async () => {
    try {
      const res = await axios.get(`${API}/resources?group_id=${selectedGroup}`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      setResources(res.data);
    } catch {
      setResources([]);
    }
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const formDataUpload = new FormData();
    formDataUpload.append("file", file);
    try {
      setUploading(true);
      const res = await axios.post(`${API}/resources/upload`, formDataUpload, {
        headers: {
          Authorization: `Bearer ${getToken()}`,
          "Content-Type": "multipart/form-data",
        },
      });
      setForm((prev) => ({ ...prev, file_url: res.data.file_url }));
    } catch {
      alert("Erreur lors de l'upload du fichier");
    } finally {
      setUploading(false);
    }
  };

  const handleAdd = async () => {
    if (!form.title) return alert("Le titre est obligatoire");
    if (form.type === "pdf" && !form.file_url) return alert("Le fichier est obligatoire");
    if ((form.type === "video" || form.type === "link") && !form.external_url)
      return alert("Le lien est obligatoire");
    try {
      await axios.post(`${API}/resources`, {
        title: form.title,
        description: form.description,
        type: form.type,
        file_url: form.type === "pdf" ? form.file_url : null,
        external_url: form.type !== "pdf" ? form.external_url : null,
        group_id: selectedGroup,
      }, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      setShowModal(false);
      setForm({ title: "", description: "", type: "pdf", file_url: "", external_url: "" });
      fetchResources();
      setSuccess("Ressource ajoutée avec succès ✓");
      setTimeout(() => setSuccess(""), 3000);
    } catch {
      alert("Une erreur est survenue lors de l'ajout");
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await axios.delete(`${API}/resources/${id}`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      fetchResources();
    } catch {
      alert("Une erreur est survenue lors de la suppression");
    }
  };

  const getTypeIcon = (type: string) => {
    if (type === "pdf") return <FileText className="text-red-500" size={20} />;
    if (type === "video") return <Video className="text-blue-500" size={20} />;
    return <LinkIcon className="text-orange-500" size={20} />;
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Ressources Pédagogiques</h1>
        <p className="mt-1 text-slate-500">Gérez les fichiers et les liens pour vos étudiants</p>
      </div>

      {success && (
        <div className="rounded-xl bg-green-50 border border-green-200 px-4 py-3 text-green-700 text-sm">
          {success}
        </div>
      )}

      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <label className="mb-2 block text-sm font-medium text-slate-700">Choisir le groupe d'étude</label>
        <select value={selectedGroup}
          onChange={(e) => setSelectedGroup(Number(e.target.value))}
          className="w-full rounded-xl border border-slate-300 p-3 outline-none focus:border-blue-500">
          {groups.map((g) => (
            <option key={g.id} value={g.id}>{g.name}</option>
          ))}
        </select>
      </div>

      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-slate-800">Liste des ressources</h2>
          <button onClick={() => setShowModal(true)}
            className="flex items-center gap-2 rounded-xl bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700">
            <Plus size={16} /> Ajouter une ressource
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="border-b text-sm text-slate-500">
              <tr>
                <th className="pb-3 px-2">Type</th>
                <th className="pb-3 px-2">Titre</th>
                <th className="pb-3 px-2">Description</th>
                <th className="pb-3 px-2">Date</th>
                <th className="pb-3 px-2 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {resources.map((r) => (
                <tr key={r.id} className="h-16 hover:bg-slate-50 transition-colors">
                  <td className="px-2">{getTypeIcon(r.type)}</td>
                  <td className="px-2 font-medium text-slate-800">{r.title}</td>
                  <td className="px-2 text-slate-500 text-sm">{r.description || "-"}</td>
                  <td className="px-2 text-slate-500 text-sm">
                    {new Date(r.created_at).toLocaleDateString("fr-FR")}
                  </td>
                  <td className="px-2">
                    <div className="flex justify-end gap-2">
                      <a href={r.file_url || r.external_url || "#"} target="_blank" rel="noopener noreferrer"
                        className="rounded-lg p-2 hover:bg-slate-100 transition-colors">
                        <Eye size={18} className="text-slate-600" />
                      </a>
                      <button onClick={() => handleDelete(r.id)}
                        className="rounded-lg p-2 hover:bg-red-50 transition-colors">
                        <Trash2 size={18} className="text-red-500" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {resources.length === 0 && (
                <tr>
                  <td colSpan={5} className="py-12 text-center text-slate-400">
                    Aucune ressource disponible pour ce groupe.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl max-h-[90vh] overflow-y-auto">
            <div className="mb-6 flex items-center justify-between">
              <h2 className="text-xl font-bold">Ajouter une ressource</h2>
              <button onClick={() => { setShowModal(false); setForm({ title: "", description: "", type: "pdf", file_url: "", external_url: "" }); }}
                className="rounded-full p-1 hover:bg-slate-100">
                <X size={20} className="text-slate-600" />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium">Titre *</label>
                <input type="text" value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  className="w-full rounded-xl border p-3 outline-none focus:border-blue-500"
                  placeholder="Ex: Résumé du cours 1" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Description (optionnel)</label>
                <input type="text" value={form.description}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                  className="w-full rounded-xl border p-3 outline-none focus:border-blue-500" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Type</label>
                <select value={form.type}
                  onChange={(e) => setForm({ ...form, type: e.target.value, file_url: "", external_url: "" })}
                  className="w-full rounded-xl border p-3 outline-none focus:border-blue-500">
                  <option value="pdf">PDF / Fichier</option>
                  <option value="video">Video (YouTube/Vimeo)</option>
                  <option value="link">Lien externe</option>
                </select>
              </div>

              {form.type === "pdf" && (
                <div className="space-y-3">
                  {/* رفع من الجهاز */}
                  <div className="rounded-xl border-2 border-dashed border-slate-300 p-4 text-center hover:border-blue-400 transition-colors">
                    <Upload size={24} className="mx-auto mb-2 text-slate-400" />
                    <p className="text-sm text-slate-500 mb-2">Glissez un fichier ou cliquez pour choisir</p>
                    <input
                      type="file"
                      accept=".pdf,.doc,.docx,.ppt,.pptx"
                      onChange={handleFileUpload}
                      className="hidden"
                      id="file-upload-teacher"
                    />
                    <label htmlFor="file-upload-teacher"
                      className="cursor-pointer rounded-lg bg-blue-50 px-4 py-2 text-sm text-blue-600 hover:bg-blue-100">
                      {uploading ? "Upload en cours..." : "Choisir un fichier"}
                    </label>
                  </div>

                  {/* أو رابط مباشر */}
                  <div className="flex items-center gap-2">
                    <div className="flex-1 h-px bg-slate-200" />
                    <span className="text-xs text-slate-400">ou</span>
                    <div className="flex-1 h-px bg-slate-200" />
                  </div>
                  <input type="text" value={form.file_url}
                    onChange={(e) => setForm({ ...form, file_url: e.target.value })}
                    className="w-full rounded-xl border p-3 outline-none focus:border-blue-500"
                    placeholder="Coller un lien https://..." />

                  {form.file_url && (
                    <p className="text-xs text-green-600">✓ Fichier prêt : {form.file_url.split("/").pop()}</p>
                  )}
                </div>
              )}

              {(form.type === "video" || form.type === "link") && (
                <div>
                  <label className="mb-1 block text-sm font-medium">
                    {form.type === "video" ? "Lien YouTube / Vimeo *" : "Lien externe *"}
                  </label>
                  <input type="text" value={form.external_url}
                    onChange={(e) => setForm({ ...form, external_url: e.target.value })}
                    className="w-full rounded-xl border p-3 outline-none focus:border-blue-500"
                    placeholder="https://..." />
                </div>
              )}

              <div className="flex gap-3 mt-4">
                <button onClick={() => { setShowModal(false); setForm({ title: "", description: "", type: "pdf", file_url: "", external_url: "" }); }}
                  className="flex-1 rounded-xl border border-slate-200 py-3 text-slate-600 hover:bg-slate-50">
                  Annuler
                </button>
                <button onClick={handleAdd}
                  className="flex-1 rounded-xl bg-blue-600 py-3 text-white font-bold hover:bg-blue-700">
                  Enregistrer
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}