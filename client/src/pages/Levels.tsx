import React, { useEffect, useState } from "react";
import axios from "axios";
import { Pencil, Trash2, Plus, X, GraduationCap } from "lucide-react";
import { getToken } from "../services/auth";

type Level = {
  id: number;
  name: string;
  description: string | null;
  image: string | null;
  price: number | null;
  duration: string | null;
};

export default function Levels() {
  const [openModal, setOpenModal] = useState(false);
  const [levelsData, setLevelsData] = useState<Level[]>([]);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [deleteModal, setDeleteModal] = useState(false);
  const [deleteTargetId, setDeleteTargetId] = useState<number | null>(null);

  const headers = { Authorization: `Bearer ${getToken()}` };

  const [formData, setFormData] = useState({
    name: "",
    description: "",
    image: "",
    price: "",
    duration: "",
  });

  useEffect(() => { fetchLevels(); }, []);

  const fetchLevels = async () => {
    try {
      setLoading(true);
      const res = await axios.get("http://localhost:5000/api/levels", { headers });
      setLevelsData(res.data);
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setFormData({ name: "", description: "", image: "", price: "", duration: "" });
    setEditingId(null);
  };

  const handleOpenAddModal = () => { resetForm(); setOpenModal(true); };

  const handleOpenEditModal = (level: Level) => {
    setEditingId(level.id);
    setFormData({
      name: level.name || "",
      description: level.description || "",
      image: level.image || "",
      price: level.price ? String(level.price) : "",
      duration: level.duration || "",
    });
    setOpenModal(true);
  };

  const handleSaveLevel = async () => {
    if (!formData.name.trim()) return alert("Veuillez entrer le nom");
    try {
      const payload = {
        ...formData,
        price: formData.price ? Number(formData.price) : null,
      };
      if (editingId !== null) {
        await axios.put(`http://localhost:5000/api/levels/${editingId}`, payload, { headers });
      } else {
        await axios.post("http://localhost:5000/api/levels", payload, { headers });
      }
      fetchLevels();
      setOpenModal(false);
    } catch (error) { console.error(error); }
  };

  const confirmDelete = (id: number) => {
    setDeleteTargetId(id);
    setDeleteModal(true);
  };

  const handleDeleteLevel = async () => {
    if (!deleteTargetId) return;
    try {
      await axios.delete(`http://localhost:5000/api/levels/${deleteTargetId}`, { headers });
      fetchLevels();
      setDeleteModal(false);
      setDeleteTargetId(null);
    } catch (error) { console.error(error); }
  };

  return (
    <div className="space-y-6">

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Gestion des Niveaux</h1>
          <p className="text-slate-500 mt-1 flex items-center gap-2">
            <GraduationCap size={18} /> Configurez les parcours scolaires et les niveaux
          </p>
        </div>
        <button
          onClick={handleOpenAddModal}
          className="flex items-center gap-2 rounded-xl bg-indigo-600 px-5 py-3 text-sm font-medium text-white hover:bg-indigo-700"
        >
          <Plus size={18} /> Nouveau Niveau
        </button>
      </div>

      {/* Table */}
      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <h2 className="mb-4 text-xl font-semibold text-slate-800">
          Liste des Niveaux
          <span className="ml-2 text-sm font-normal text-slate-400 bg-slate-100 px-3 py-1 rounded-full">
            {levelsData.length}
          </span>
        </h2>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="border-b text-sm text-slate-500">
              <tr>
                <th className="pb-4 px-2">Aperçu</th>
                <th className="pb-4 px-2">Nom</th>
                <th className="pb-4 px-2">Description</th>
                <th className="pb-4 px-2">Prix</th>
                <th className="pb-4 px-2">Durée</th>
                <th className="pb-4 px-2 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {loading ? (
                <tr><td colSpan={6} className="py-10 text-center text-slate-400">Chargement...</td></tr>
              ) : levelsData.length === 0 ? (
                <tr><td colSpan={6} className="py-10 text-center text-slate-400">Aucun niveau trouvé.</td></tr>
              ) : (
                levelsData.map((level) => (
                  <tr key={level.id} className="hover:bg-slate-50 transition">
                    <td className="py-4 px-2">
                      <div className="w-12 h-12 rounded-xl overflow-hidden shadow-sm">
                        <img
                          src={level.image || `https://ui-avatars.com/api/?name=${level.name}&background=random`}
                          alt={level.name}
                          className="w-full h-full object-cover"
                        />
                      </div>
                    </td>
                    <td className="px-2 font-semibold text-slate-800">{level.name}</td>
                    <td className="px-2 text-slate-500 text-sm max-w-[200px] truncate">
                      {level.description || "-"}
                    </td>
                    <td className="px-2">
                      {level.price ? (
                        <span className="rounded-full bg-green-100 px-3 py-1 text-xs font-medium text-green-700">
                          {level.price} DT
                        </span>
                      ) : (
                        <span className="text-slate-400 text-sm">-</span>
                      )}
                    </td>
                    <td className="px-2">
                      {level.duration ? (
                        <span className="rounded-full bg-blue-100 px-3 py-1 text-xs font-medium text-blue-700">
                          {level.duration}
                        </span>
                      ) : (
                        <span className="text-slate-400 text-sm">-</span>
                      )}
                    </td>
                    <td className="px-2 text-right">
                      <div className="flex justify-end gap-2">
                        <button
                          onClick={() => handleOpenEditModal(level)}
                          className="rounded-lg p-2 hover:bg-slate-100"
                        >
                          <Pencil size={16} className="text-slate-500" />
                        </button>
                        <button
                          onClick={() => confirmDelete(level.id)}
                          className="rounded-lg p-2 hover:bg-red-50"
                        >
                          <Trash2 size={16} className="text-red-500" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Ajout/Édition */}
      {openModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl max-h-[90vh] overflow-y-auto">
            <div className="mb-5 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-slate-800">
                {editingId !== null ? "Modifier le Niveau" : "Nouveau Niveau"}
              </h2>
              <button onClick={() => setOpenModal(false)} className="rounded-lg p-2 hover:bg-slate-100">
                <X size={20} className="text-slate-600" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Nom *</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full rounded-xl border border-slate-200 p-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  placeholder="Ex: BTS, Langues..."
                />
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Description</label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="w-full rounded-xl border border-slate-200 p-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  rows={3}
                  placeholder="Description du niveau..."
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="mb-1 block text-sm font-medium text-slate-700">Prix (DT)</label>
                  <input
                    type="number"
                    value={formData.price}
                    onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                    className="w-full rounded-xl border border-slate-200 p-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                    placeholder="Ex: 150"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-slate-700">Durée</label>
                  <input
                    type="text"
                    value={formData.duration}
                    onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
                    className="w-full rounded-xl border border-slate-200 p-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                    placeholder="Ex: 6 mois"
                  />
                </div>
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">URL Image</label>
                <input
                  type="text"
                  value={formData.image}
                  onChange={(e) => setFormData({ ...formData, image: e.target.value })}
                  className="w-full rounded-xl border border-slate-200 p-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  placeholder="https://..."
                />
                {formData.image && (
                  <img src={formData.image} alt="preview" className="mt-2 h-16 w-full object-cover rounded-xl" />
                )}
              </div>
            </div>

            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => setOpenModal(false)}
                className="rounded-xl border border-slate-200 px-5 py-2 text-sm text-slate-600 hover:bg-slate-50"
              >
                Annuler
              </button>
              <button
                onClick={handleSaveLevel}
                className="rounded-xl bg-indigo-600 px-5 py-2 text-sm font-medium text-white hover:bg-indigo-700"
              >
                {editingId !== null ? "Modifier" : "Ajouter"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Confirmation Suppression */}
      {deleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-semibold text-slate-800">Confirmer la suppression</h2>
            <p className="mt-2 text-sm text-slate-500">Voulez-vous vraiment supprimer ce niveau ?</p>
            <div className="mt-5 flex justify-end gap-3">
              <button
                onClick={() => { setDeleteModal(false); setDeleteTargetId(null); }}
                className="rounded-xl border border-slate-200 px-4 py-2 text-sm text-slate-600 hover:bg-slate-50"
              >
                Annuler
              </button>
              <button
                onClick={handleDeleteLevel}
                className="rounded-xl bg-red-500 px-4 py-2 text-sm font-medium text-white hover:bg-red-600"
              >
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}