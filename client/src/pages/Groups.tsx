import React, { useEffect, useState } from "react";
import axios from "axios";
import { Pencil, Trash2, Plus, X } from "lucide-react";

type Group = {
  id: number;
  name: string;
  level_id: number | null;
  teacher_id: number | null;
  schedule: string | null;
  meeting_link: string | null;
  level_name?: string | null;
  teacher_name?: string | null;
};

type Level = {
  id: number;
  name: string;
};

type Teacher = {
  id: number;
  name: string;
};

export default function Groups() {
  const token = localStorage.getItem("token");
  const headers = { Authorization: `Bearer ${token}` };

  const [groupsData, setGroupsData] = useState<Group[]>([]);
  const [levelsData, setLevelsData] = useState<Level[]>([]);
  const [teachersData, setTeachersData] = useState<Teacher[]>([]);
  const [openModal, setOpenModal] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);

  const [formData, setFormData] = useState({
    name: "",
    level_id: "",
    teacher_id: "",
    schedule: "",
    meeting_link: "",
  });

  useEffect(() => {
    fetchGroups();
    fetchLevels();
    fetchTeachers();
  }, []);

  const fetchGroups = async () => {
    try {
      setLoading(true);
      const res = await axios.get("http://localhost:5000/api/groups", { headers });
      setGroupsData(res.data);
    } catch (error) {
      console.error("Error fetching groups:", error);
    } finally {
      setLoading(false);
    }
  };

  const fetchLevels = async () => {
    try {
      const res = await axios.get("http://localhost:5000/api/levels", { headers });
      setLevelsData(res.data);
    } catch (error) {
      console.error("Error fetching levels:", error);
    }
  };

  const fetchTeachers = async () => {
    try {
      const res = await axios.get("http://localhost:5000/api/teachers", { headers });
      setTeachersData(res.data);
    } catch (error) {
      console.error("Error fetching teachers:", error);
    }
  };

  const resetForm = () => {
    setFormData({
      name: "",
      level_id: "",
      teacher_id: "",
      schedule: "",
      meeting_link: "",
    });
    setEditingId(null);
  };

  const handleOpenAddModal = () => {
    resetForm();
    setOpenModal(true);
  };

  const handleOpenEditModal = (group: Group) => {
    setEditingId(group.id);
    setFormData({
      name: group.name || "",
      level_id: group.level_id ? String(group.level_id) : "",
      teacher_id: group.teacher_id ? String(group.teacher_id) : "",
      schedule: group.schedule || "",
      meeting_link: group.meeting_link || "",
    });
    setOpenModal(true);
  };

  const handleSaveGroup = async () => {
    if (!formData.name.trim()) return alert("Veuillez entrer le nom du groupe");
    try {
      const payload = {
        name: formData.name,
        level_id: formData.level_id ? Number(formData.level_id) : null,
        teacher_id: formData.teacher_id ? Number(formData.teacher_id) : null,
        schedule: formData.schedule,
        meeting_link: formData.meeting_link,
      };
      if (editingId !== null) {
        await axios.put(`http://localhost:5000/api/groups/${editingId}`, payload, { headers });
      } else {
        await axios.post("http://localhost:5000/api/groups", payload, { headers });
      }
      await fetchGroups();
      setOpenModal(false);
      resetForm();
    } catch (error) {
      alert("Erreur lors de l'enregistrement du groupe");
    }
  };

  const handleDeleteGroup = async (id: number) => {
    if (!window.confirm("Voulez-vous vraiment supprimer ce groupe ?")) return;
    try {
      await axios.delete(`http://localhost:5000/api/groups/${id}`, { headers });
      await fetchGroups();
    } catch (error) {
      alert("Erreur lors de la suppression du groupe");
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Gestion des Groupes</h1>
          <p className="mt-1 text-slate-500">Gérez les groupes et leurs informations</p>
        </div>
        <button
          onClick={handleOpenAddModal}
          className="flex items-center gap-2 rounded-xl bg-blue-500 px-5 py-3 text-white hover:bg-blue-600"
        >
          <Plus size={18} /> Nouveau Groupe
        </button>
      </div>

      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <h2 className="mb-6 text-xl font-semibold text-slate-800">
          Groupes ({groupsData.length})
        </h2>
        {loading ? (
          <p className="text-slate-500">Chargement...</p>
        ) : (
          <table className="w-full">
            <thead className="border-b text-left text-sm text-slate-500">
              <tr>
                <th className="pb-3">Nom du groupe</th>
                <th className="pb-3">Niveau</th>
                <th className="pb-3">Enseignant</th>
                <th className="pb-3">Horaire</th>
                <th className="pb-3">Lien Meet</th>
                <th className="pb-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {groupsData.map((group) => (
                <tr key={group.id} className="h-20">
                  <td className="font-medium text-slate-800">{group.name}</td>
                  <td className="text-slate-600">{group.level_name || "-"}</td>
                  <td className="text-slate-600">{group.teacher_name || "-"}</td>
                  <td className="text-slate-600">{group.schedule || "-"}</td>
                  <td className="text-slate-600">
                    {group.meeting_link ? (
                      <a href={group.meeting_link} target="_blank" rel="noreferrer"
                        className="text-blue-600 hover:underline">
                        Ouvrir
                      </a>
                    ) : "-"}
                  </td>
                  <td className="text-right">
                    <div className="flex justify-end gap-3">
                      <button onClick={() => handleOpenEditModal(group)}
                        className="rounded-lg p-2 hover:bg-slate-100">
                        <Pencil size={18} className="text-slate-600" />
                      </button>
                      <button onClick={() => handleDeleteGroup(group.id)}
                        className="rounded-lg p-2 hover:bg-red-50">
                        <Trash2 size={18} className="text-red-500" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {openModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-slate-800">
                {editingId !== null ? "Modifier le Groupe" : "Ajouter un Groupe"}
              </h2>
              <button onClick={() => { setOpenModal(false); resetForm(); }}
                className="rounded-lg p-2 hover:bg-slate-100">
                <X size={20} className="text-slate-600" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Nom du groupe</label>
                <input type="text" value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="Ex: G1 - A1"
                  className="w-full rounded-lg border border-slate-300 p-3 outline-none focus:border-blue-500" />
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Niveau</label>
                <select value={formData.level_id}
                  onChange={(e) => setFormData({ ...formData, level_id: e.target.value })}
                  className="w-full rounded-lg border border-slate-300 p-3 outline-none focus:border-blue-500">
                  <option value="">Sélectionner un niveau</option>
                  {levelsData.map((level) => (
                    <option key={level.id} value={level.id}>{level.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Enseignant</label>
                <select value={formData.teacher_id}
                  onChange={(e) => setFormData({ ...formData, teacher_id: e.target.value })}
                  className="w-full rounded-lg border border-slate-300 p-3 outline-none focus:border-blue-500">
                  <option value="">Sélectionner un enseignant</option>
                  {teachersData.map((teacher) => (
                    <option key={teacher.id} value={teacher.id}>{teacher.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Horaire</label>
                <input type="text" value={formData.schedule}
                  onChange={(e) => setFormData({ ...formData, schedule: e.target.value })}
                  placeholder="Lundi / Mercredi - 18:00"
                  className="w-full rounded-lg border border-slate-300 p-3 outline-none focus:border-blue-500" />
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Lien Meet</label>
                <input type="text" value={formData.meeting_link}
                  onChange={(e) => setFormData({ ...formData, meeting_link: e.target.value })}
                  placeholder="https://meet.google.com/..."
                  className="w-full rounded-lg border border-slate-300 p-3 outline-none focus:border-blue-500" />
              </div>

              <button onClick={handleSaveGroup}
                className="w-full rounded-lg bg-blue-500 py-3 font-medium text-white hover:bg-blue-600">
                {editingId !== null ? "Mettre à jour" : "Ajouter"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}