import React, { useEffect, useState } from "react";
import axios from "axios";
import { Pencil, Trash2, Plus, X } from "lucide-react";

type Teacher = {
  id: number;
  name: string;
  email: string | null;
  phone: string | null;
  specialty: string | null;
};

export default function Teachers() {
  const [teachersData, setTeachersData] = useState<Teacher[]>([]);
  const [openModal, setOpenModal] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);

  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    specialty: "",
  });

  useEffect(() => {
    fetchTeachers();
  }, []);

  const fetchTeachers = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem("token");
      const res = await axios.get("http://localhost:5000/api/teachers", {
        headers: { Authorization: `Bearer ${token}` },
      });
      setTeachersData(res.data);
    } catch (error) {
      console.error("Error fetching teachers:", error);
      alert("Erreur lors du chargement des enseignants");
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setFormData({
      name: "",
      email: "",
      phone: "",
      specialty: "",
    });
    setEditingId(null);
  };

  const handleOpenAddModal = () => {
    resetForm();
    setOpenModal(true);
  };

  const handleOpenEditModal = (teacher: Teacher) => {
    setEditingId(teacher.id);
    setFormData({
      name: teacher.name || "",
      email: teacher.email || "",
      phone: teacher.phone || "",
      specialty: teacher.specialty || "",
    });
    setOpenModal(true);
  };

  const handleSaveTeacher = async () => {
    if (!formData.name.trim()) {
      alert("Veuillez remplir au moins le nom");
      return;
    }

    const token = localStorage.getItem("token");
    const headers = { Authorization: `Bearer ${token}` };

    try {
      if (editingId !== null) {
        await axios.put(
          `http://localhost:5000/api/teachers/${editingId}`,
          {
            name: formData.name,
            email: formData.email,
            phone: formData.phone,
            specialty: formData.specialty,
          },
          { headers }
        );
      } else {
        await axios.post(
          "http://localhost:5000/api/teachers",
          {
            name: formData.name,
            email: formData.email,
            phone: formData.phone,
            specialty: formData.specialty,
          },
          { headers }
        );
      }

      await fetchTeachers();
      setOpenModal(false);
      resetForm();
    } catch (error) {
      console.error("Error saving teacher:", error);
      alert("Erreur lors de l'enregistrement de l'enseignant");
    }
  };

  const handleDeleteTeacher = async (id: number) => {
    const confirmed = window.confirm(
      "Voulez-vous vraiment supprimer cet enseignant ?"
    );
    if (!confirmed) return;

    const token = localStorage.getItem("token");

    try {
      await axios.delete(`http://localhost:5000/api/teachers/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      await fetchTeachers();
    } catch (error) {
      console.error("Error deleting teacher:", error);
      alert("Erreur lors de la suppression de l'enseignant");
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">
            Gestion des Enseignants
          </h1>
          <p className="mt-1 text-slate-500">
            Gérez les enseignants de la plateforme
          </p>
        </div>

        <button
          onClick={handleOpenAddModal}
          className="flex items-center gap-2 rounded-xl bg-blue-500 px-5 py-3 text-white hover:bg-blue-600"
        >
          <Plus size={18} />
          Nouvel Enseignant
        </button>
      </div>

      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <h2 className="mb-6 text-xl font-semibold text-slate-800">
          Enseignants ({teachersData.length})
        </h2>

        {loading ? (
          <p className="text-slate-500">Chargement...</p>
        ) : (
          <table className="w-full">
            <thead className="border-b text-left text-sm text-slate-500">
              <tr>
                <th className="pb-3">Nom</th>
                <th className="pb-3">Email</th>
                <th className="pb-3">Téléphone</th>
                <th className="pb-3">Spécialité</th>
                <th className="pb-3 text-right">Actions</th>
              </tr>
            </thead>

            <tbody className="divide-y">
              {teachersData.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-8 text-center text-slate-400">
                    Aucun enseignant trouvé
                  </td>
                </tr>
              ) : (
                teachersData.map((teacher) => (
                  <tr key={teacher.id} className="h-20">
                    <td className="font-medium text-slate-800">{teacher.name}</td>
                    <td className="text-slate-600">{teacher.email || "-"}</td>
                    <td className="text-slate-600">{teacher.phone || "-"}</td>
                    <td className="text-slate-600">{teacher.specialty || "-"}</td>

                    <td className="text-right">
                      <div className="flex justify-end gap-3">
                        <button
                          onClick={() => handleOpenEditModal(teacher)}
                          className="rounded-lg p-2 hover:bg-slate-100"
                        >
                          <Pencil size={18} className="text-slate-600" />
                        </button>

                        <button
                          onClick={() => handleDeleteTeacher(teacher.id)}
                          className="rounded-lg p-2 hover:bg-red-50"
                        >
                          <Trash2 size={18} className="text-red-500" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>

      {openModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-slate-800">
                {editingId !== null
                  ? "Modifier l'Enseignant"
                  : "Ajouter un Enseignant"}
              </h2>

              <button
                onClick={() => {
                  setOpenModal(false);
                  resetForm();
                }}
                className="rounded-lg p-2 hover:bg-slate-100"
              >
                <X size={20} className="text-slate-600" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">
                  Nom complet
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) =>
                    setFormData({ ...formData, name: e.target.value })
                  }
                  placeholder="Nom complet"
                  className="w-full rounded-lg border border-slate-300 p-3 outline-none focus:border-blue-500"
                />
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">
                  Email
                </label>
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) =>
                    setFormData({ ...formData, email: e.target.value })
                  }
                  placeholder="email@example.com"
                  className="w-full rounded-lg border border-slate-300 p-3 outline-none focus:border-blue-500"
                />
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">
                  Téléphone
                </label>
                <input
                  type="text"
                  value={formData.phone}
                  onChange={(e) =>
                    setFormData({ ...formData, phone: e.target.value })
                  }
                  placeholder="+216..."
                  className="w-full rounded-lg border border-slate-300 p-3 outline-none focus:border-blue-500"
                />
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">
                  Spécialité
                </label>
                <input
                  type="text"
                  value={formData.specialty}
                  onChange={(e) =>
                    setFormData({ ...formData, specialty: e.target.value })
                  }
                  placeholder="Mathématiques"
                  className="w-full rounded-lg border border-slate-300 p-3 outline-none focus:border-blue-500"
                />
              </div>

              <button
                onClick={handleSaveTeacher}
                className="w-full rounded-lg bg-blue-500 py-3 font-medium text-white hover:bg-blue-600"
              >
                {editingId !== null ? "Mettre à jour" : "Ajouter"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}