import React, { useEffect, useState } from "react";
import axios from "axios";
import { Pencil, Trash2, Plus, X } from "lucide-react";

type Student = {
  id: number;
  name: string;
  email: string | null;
  phone: string | null;
  level_id: number | null;
  level_name?: string | null;
};

type Level = {
  id: number;
  name: string;
  description: string | null;
  image: string | null;
};

export default function Students() {
  const [studentsData, setStudentsData] = useState<Student[]>([]);
  const [levelsData, setLevelsData] = useState<Level[]>([]);
  const [openModal, setOpenModal] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);

  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    level_id: "",
  });

  useEffect(() => {
    fetchStudents();
    fetchLevels();
  }, []);

  const fetchStudents = async () => {
    try {
      setLoading(true);
      const res = await axios.get("http://localhost:5000/api/students");
      setStudentsData(res.data);
    } catch (error) {
      console.error("Error fetching students:", error);
      alert("Erreur lors du chargement des élèves");
    } finally {
      setLoading(false);
    }
  };

  const fetchLevels = async () => {
    try {
      const res = await axios.get("http://localhost:5000/api/levels");
      setLevelsData(res.data);
    } catch (error) {
      console.error("Error fetching levels:", error);
    }
  };

  const resetForm = () => {
    setFormData({
      name: "",
      email: "",
      phone: "",
      level_id: "",
    });
    setEditingId(null);
  };

  const handleOpenAddModal = () => {
    resetForm();
    setOpenModal(true);
  };

  const handleOpenEditModal = (student: Student) => {
    setEditingId(student.id);
    setFormData({
      name: student.name || "",
      email: student.email || "",
      phone: student.phone || "",
      level_id: student.level_id ? String(student.level_id) : "",
    });
    setOpenModal(true);
  };

  const handleSaveStudent = async () => {
    if (!formData.name.trim()) {
      alert("Veuillez remplir au moins le nom");
      return;
    }

    try {
      const payload = {
        name: formData.name,
        email: formData.email,
        phone: formData.phone,
        level_id: formData.level_id ? Number(formData.level_id) : null,
      };

      if (editingId !== null) {
        await axios.put(`http://localhost:5000/api/students/${editingId}`, payload);
      } else {
        await axios.post("http://localhost:5000/api/students", payload);
      }

      await fetchStudents();
      setOpenModal(false);
      resetForm();
    } catch (error) {
      console.error("Error saving student:", error);
      alert("Erreur lors de l'enregistrement de l'élève");
    }
  };

  const handleDeleteStudent = async (id: number) => {
    const confirmed = window.confirm(
      "Voulez-vous vraiment supprimer cet élève ?"
    );
    if (!confirmed) return;

    try {
      await axios.delete(`http://localhost:5000/api/students/${id}`);
      await fetchStudents();
    } catch (error) {
      console.error("Error deleting student:", error);
      alert("Erreur lors de la suppression de l'élève");
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">
            Gestion des Élèves
          </h1>
          <p className="mt-1 text-slate-500">
            Gérez les élèves de la plateforme
          </p>
        </div>

        <button
          onClick={handleOpenAddModal}
          className="flex items-center gap-2 rounded-xl bg-blue-500 px-5 py-3 text-white hover:bg-blue-600"
        >
          <Plus size={18} />
          Nouvel Élève
        </button>
      </div>

      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <h2 className="mb-6 text-xl font-semibold text-slate-800">
          Élèves ({studentsData.length})
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
                <th className="pb-3">Niveau</th>
                <th className="pb-3 text-right">Actions</th>
              </tr>
            </thead>

            <tbody className="divide-y">
              {studentsData.map((student) => (
                <tr key={student.id} className="h-20">
                  <td className="font-medium text-slate-800">{student.name}</td>
                  <td className="text-slate-600">{student.email || "-"}</td>
                  <td className="text-slate-600">{student.phone || "-"}</td>
                  <td className="text-slate-600">{student.level_name || "-"}</td>

                  <td className="text-right">
                    <div className="flex justify-end gap-3">
                      <button
                        onClick={() => handleOpenEditModal(student)}
                        className="rounded-lg p-2 hover:bg-slate-100"
                      >
                        <Pencil size={18} className="text-slate-600" />
                      </button>

                      <button
                        onClick={() => handleDeleteStudent(student.id)}
                        className="rounded-lg p-2 hover:bg-red-50"
                      >
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
                {editingId !== null ? "Modifier l'Élève" : "Ajouter un Élève"}
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
                  Niveau
                </label>
                <select
                  value={formData.level_id}
                  onChange={(e) =>
                    setFormData({ ...formData, level_id: e.target.value })
                  }
                  className="w-full rounded-lg border border-slate-300 p-3 outline-none focus:border-blue-500"
                >
                  <option value="">Sélectionner un niveau</option>
                  {levelsData.map((level) => (
                    <option key={level.id} value={level.id}>
                      {level.name}
                    </option>
                  ))}
                </select>
              </div>

              <button
                onClick={handleSaveStudent}
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