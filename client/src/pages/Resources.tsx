import React, { useEffect, useState } from "react";
import axios from "axios";
import { Plus, Trash2, Eye, X, FileText, Video, Link as LinkIcon, Play, Upload } from "lucide-react";

const API = "http://localhost:5000/api";

type Resource = {
  id: number;
  title: string;
  description: string | null;
  type: string;
  file_url: string | null;
  external_url: string | null;
  group_id: number | null;
  level_id: number | null;
  teacher_id: number | null;
  created_at: string;
  level_name?: string;
  teacher_name?: string;
};

type Group = { id: number; name: string };

const getYoutubeThumbnail = (url: string) => {
  const regExp = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/;
  const match = url.match(regExp);
  return match ? `https://img.youtube.com/vi/${match[1]}/mqdefault.jpg` : null;
};

const getVideoEmbedUrl = (url: string) => {
  const ytRegExp = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/;
  const ytMatch = url.match(ytRegExp);
  if (ytMatch) return `https://www.youtube.com/embed/${ytMatch[1]}`;
  const vimeoRegExp = /vimeo\.com\/(\d+)/;
  const vimeoMatch = url.match(vimeoRegExp);
  if (vimeoMatch) return `https://player.vimeo.com/video/${vimeoMatch[1]}`;
  return url;
};

export default function Resources() {
  const token = localStorage.getItem("token");
  const headers = { Authorization: `Bearer ${token}` };

  const [groups, setGroups] = useState<Group[]>([]);
  const [selectedGroup, setSelectedGroup] = useState<number | "">("");
  const [resources, setResources] = useState<Resource[]>([]);
  const [loading, setLoading] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [previewVideo, setPreviewVideo] = useState<string | null>(null);
  const [deleteModal, setDeleteModal] = useState(false);
  const [deleteTargetId, setDeleteTargetId] = useState<number | null>(null);
  const [uploading, setUploading] = useState(false);

  const [form, setForm] = useState({
    title: "",
    description: "",
    type: "pdf",
    file_url: "",
    external_url: "",
  });

  useEffect(() => {
    axios.get(`${API}/groups`, { headers }).then((res) => {
      setGroups(res.data);
      if (res.data.length > 0) setSelectedGroup(res.data[0].id);
    });
  }, []);

  useEffect(() => {
    if (selectedGroup !== "") fetchResources();
  }, [selectedGroup]);

  const fetchResources = async () => {
    try {
      setLoading(true);
      const res = await axios.get(`${API}/resources?group_id=${selectedGroup}`, { headers });
      setResources(res.data);
    } catch {
      setResources([]);
    } finally {
      setLoading(false);
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
          Authorization: `Bearer ${token}`,
          "Content-Type": "multipart/form-data",
        },
      });
      setForm({ ...form, file_url: res.data.file_url });
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
      }, { headers });
      setShowModal(false);
      setForm({ title: "", description: "", type: "pdf", file_url: "", external_url: "" });
      fetchResources();
    } catch {
      alert("Erreur lors de l'ajout");
    }
  };

  const confirmDelete = async () => {
    if (!deleteTargetId) return;
    try {
      await axios.delete(`${API}/resources/${deleteTargetId}`, { headers });
      fetchResources();
      setDeleteModal(false);
      setDeleteTargetId(null);
    } catch {
      alert("Erreur lors de la suppression");
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
        <h1 className="text-3xl font-bold text-slate-900">Gestion des ressources</h1>
      </div>

      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-slate-800 mb-1">Sélectionner un groupe</h2>
        <p className="text-sm text-slate-500 mb-4">Choisissez un groupe pour gérer ses ressources</p>
        <select
          value={selectedGroup}
          onChange={(e) => setSelectedGroup(Number(e.target.value))}
          className="w-full rounded-xl border border-slate-300 p-3 outline-none focus:border-blue-500"
        >
          {groups.map((g) => (
            <option key={g.id} value={g.id}>{g.name}</option>
          ))}
        </select>
      </div>

      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <div className="mb-4 flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-slate-800">Ressources de groupe</h2>
            <p className="text-sm text-slate-500">Gérez les ressources pédagogiques</p>
          </div>
          <button
            onClick={() => setShowModal(true)}
            className="flex items-center gap-2 rounded-xl bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700"
          >
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
                <th className="pb-3 px-2">Date d'ajout</th>
                <th className="pb-3 px-2 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {loading ? (
                <tr><td colSpan={5} className="py-12 text-center text-slate-400">Chargement...</td></tr>
              ) : resources.length === 0 ? (
                <tr><td colSpan={5} className="py-12 text-center text-slate-400">Aucune ressource pour ce groupe.</td></tr>
              ) : (
                resources.map((r) => {
                  const thumbnail = r.type === "video" && r.external_url ? getYoutubeThumbnail(r.external_url) : null;
                  return (
                    <tr key={r.id} className="h-16 hover:bg-slate-50 transition-colors">
                      <td className="px-2">{getTypeIcon(r.type)}</td>
                      <td className="px-2 font-medium text-slate-800">{r.title}</td>
                      <td className="px-2 text-slate-500 text-sm">{r.description || "-"}</td>
                      <td className="px-2 text-slate-500 text-sm">
                        {new Date(r.created_at).toLocaleDateString("fr-FR")}
                      </td>
                      <td className="px-2">
                        <div className="flex justify-end gap-2">
                          {r.type === "video" && r.external_url ? (
                            <button onClick={() => setPreviewVideo(r.external_url!)} className="rounded-lg p-2 hover:bg-slate-100">
                              {thumbnail ? (
                                <div className="relative w-16 h-10 rounded overflow-hidden">
                                  <img src={thumbnail} className="w-full h-full object-cover" />
                                  <div className="absolute inset-0 flex items-center justify-center bg-black/30">
                                    <Play size={12} className="text-white" />
                                  </div>
                                </div>
                              ) : <Eye size={18} className="text-slate-600" />}
                            </button>
                          ) : (
                            <a href={r.file_url || r.external_url || "#"} target="_blank" rel="noreferrer"
                              className="rounded-lg p-2 hover:bg-slate-100">
                              <Eye size={18} className="text-slate-600" />
                            </a>
                          )}
                          <button onClick={() => { setDeleteTargetId(r.id); setDeleteModal(true); }}
                            className="rounded-lg p-2 hover:bg-red-50">
                            <Trash2 size={18} className="text-red-500" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Vidéo */}
      {previewVideo && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 px-4">
          <div className="w-full max-w-3xl rounded-2xl bg-black overflow-hidden shadow-2xl">
            <div className="flex items-center justify-between px-4 py-3 bg-slate-900">
              <p className="text-white text-sm">Aperçu Vidéo</p>
              <button onClick={() => setPreviewVideo(null)} className="text-white hover:text-red-400"><X size={20} /></button>
            </div>
            <div className="aspect-video">
              <iframe src={getVideoEmbedUrl(previewVideo)} className="w-full h-full"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen />
            </div>
          </div>
        </div>
      )}

      {/* Modal Ajout */}
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
                  placeholder="Titre de la ressource" />
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
                  <option value="video">Vidéo (YouTube/Vimeo)</option>
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
                      id="file-upload-admin"
                    />
                    <label htmlFor="file-upload-admin"
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

      {/* Modal Suppression */}
      {deleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-semibold text-slate-800">Confirmer la suppression</h2>
            <p className="mt-2 text-sm text-slate-500">Voulez-vous vraiment supprimer cette ressource ?</p>
            <div className="mt-5 flex justify-end gap-3">
              <button onClick={() => { setDeleteModal(false); setDeleteTargetId(null); }}
                className="rounded-xl border border-slate-200 px-4 py-2 text-sm text-slate-600 hover:bg-slate-50">
                Annuler
              </button>
              <button onClick={confirmDelete}
                className="rounded-xl bg-red-500 px-4 py-2 text-sm font-medium text-white hover:bg-red-600">
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}