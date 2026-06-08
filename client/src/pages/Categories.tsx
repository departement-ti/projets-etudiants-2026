import React, { useEffect, useState } from "react";
import axios from "axios";
import { Plus, Pencil, Trash2, X, ChevronDown, ChevronRight } from "lucide-react";

type Category = {
  id: number;
  name: string;
  description: string | null;
  created_at: string;
};

type SubCategory = {
  id: number;
  name: string;
  description: string | null;
  category_id: number;
  category_name?: string;
  created_at: string;
};

const API = "http://localhost:5000/api";

export default function Categories() {
  const token = localStorage.getItem("token");
  const headers = { Authorization: `Bearer ${token}` };

  const [categories, setCategories] = useState<Category[]>([]);
  const [subCategories, setSubCategories] = useState<SubCategory[]>([]);
  const [activeTab, setActiveTab] = useState<"categories" | "subcategories">("categories");
  const [expandedCategory, setExpandedCategory] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);

  // Modal états
  const [openModal, setOpenModal] = useState(false);
  const [modalType, setModalType] = useState<"category" | "subcategory">("category");
  const [editItem, setEditItem] = useState<Category | SubCategory | null>(null);

  // Formulaire
  const [formName, setFormName] = useState("");
  const [formDescription, setFormDescription] = useState("");
  const [formCategoryId, setFormCategoryId] = useState<number | "">("");

  // Confirmation suppression
  const [deleteModal, setDeleteModal] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<{ id: number; type: "category" | "subcategory" } | null>(null);

  useEffect(() => {
    fetchCategories();
    fetchSubCategories();
  }, []);

  const fetchCategories = async () => {
    try {
      setLoading(true);
      const res = await axios.get(`${API}/categories`, { headers });
      setCategories(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchSubCategories = async () => {
    try {
      const res = await axios.get(`${API}/categories/sub`, { headers });
      setSubCategories(res.data);
    } catch (err) {
      console.error(err);
    }
  };

  const openAddModal = (type: "category" | "subcategory") => {
    setModalType(type);
    setEditItem(null);
    setFormName("");
    setFormDescription("");
    setFormCategoryId("");
    setOpenModal(true);
  };

  const openEditModal = (type: "category" | "subcategory", item: Category | SubCategory) => {
    setModalType(type);
    setEditItem(item);
    setFormName(item.name);
    setFormDescription(item.description || "");
    if (type === "subcategory") setFormCategoryId((item as SubCategory).category_id);
    setOpenModal(true);
  };

  const handleSubmit = async () => {
    if (!formName.trim()) return alert("Le nom est obligatoire");
    if (modalType === "subcategory" && !formCategoryId) return alert("Veuillez sélectionner une catégorie");

    try {
      if (modalType === "category") {
        if (editItem) {
          await axios.put(`${API}/categories/${editItem.id}`, { name: formName, description: formDescription }, { headers });
        } else {
          await axios.post(`${API}/categories`, { name: formName, description: formDescription }, { headers });
        }
        await fetchCategories();
      } else {
        if (editItem) {
          await axios.put(`${API}/categories/sub/${editItem.id}`, { name: formName, description: formDescription, category_id: formCategoryId }, { headers });
        } else {
          await axios.post(`${API}/categories/sub`, { name: formName, description: formDescription, category_id: formCategoryId }, { headers });
        }
        await fetchSubCategories();
      }
      setOpenModal(false);
    } catch (err) {
      console.error(err);
      alert("Une erreur s'est produite");
    }
  };

  const confirmDelete = (id: number, type: "category" | "subcategory") => {
    setDeleteTarget({ id, type });
    setDeleteModal(true);
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      if (deleteTarget.type === "category") {
        await axios.delete(`${API}/categories/${deleteTarget.id}`, { headers });
        await fetchCategories();
        await fetchSubCategories();
      } else {
        await axios.delete(`${API}/categories/sub/${deleteTarget.id}`, { headers });
        await fetchSubCategories();
      }
      setDeleteModal(false);
      setDeleteTarget(null);
    } catch (err) {
      console.error(err);
      alert("Erreur lors de la suppression");
    }
  };

  const getSubsForCategory = (categoryId: number) =>
    subCategories.filter((s) => s.category_id === categoryId);

  const tabClass = (tab: "categories" | "subcategories") =>
    `rounded-xl px-4 py-2 text-sm font-medium transition ${
      activeTab === tab ? "bg-white text-slate-900 shadow-sm" : "text-slate-500 hover:text-slate-800"
    }`;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Formations</h1>
          <p className="mt-1 text-slate-500">Gérez les catégories et sous-catégories de formations.</p>
        </div>
      </div>

      {/* Statistiques */}
      <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <div className="flex items-start justify-between">
            <div>
              <p className="font-medium text-slate-800">Catégories</p>
              <h2 className="mt-6 text-4xl font-bold text-slate-900">{categories.length}</h2>
              <p className="mt-2 text-sm text-slate-500">Catégories principales</p>
            </div>
            <span className="text-2xl">📚</span>
          </div>
        </div>
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <div className="flex items-start justify-between">
            <div>
              <p className="font-medium text-slate-800">Sous-catégories</p>
              <h2 className="mt-6 text-4xl font-bold text-slate-900">{subCategories.length}</h2>
              <p className="mt-2 text-sm text-slate-500">Sous-catégories au total</p>
            </div>
            <span className="text-2xl">🗂️</span>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center justify-between">
        <div className="inline-flex rounded-2xl bg-slate-100 p-1">
          <button onClick={() => setActiveTab("categories")} className={tabClass("categories")}>
            Catégories ({categories.length})
          </button>
          <button onClick={() => setActiveTab("subcategories")} className={tabClass("subcategories")}>
            Sous-catégories ({subCategories.length})
          </button>
        </div>
        <button
          onClick={() => openAddModal(activeTab === "categories" ? "category" : "subcategory")}
          className="flex items-center gap-2 rounded-xl bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
        >
          <Plus size={16} />
          {activeTab === "categories" ? "Ajouter Catégorie" : "Ajouter Sous-catégorie"}
        </button>
      </div>

      {/* Tab: Catégories avec sous-catégories */}
      {activeTab === "categories" && (
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-xl font-semibold text-slate-900">Liste des Catégories</h2>
          {loading ? (
            <p className="py-8 text-center text-slate-500">Chargement...</p>
          ) : categories.length === 0 ? (
            <p className="py-8 text-center text-slate-500">Aucune catégorie trouvée.</p>
          ) : (
            <div className="space-y-3">
              {categories.map((cat) => {
                const subs = getSubsForCategory(cat.id);
                const isExpanded = expandedCategory === cat.id;
                return (
                  <div key={cat.id} className="rounded-xl border border-slate-100 overflow-hidden">
                    <div className="flex items-center justify-between p-4 hover:bg-slate-50">
                      <div className="flex items-center gap-3">
                        <button
                          onClick={() => setExpandedCategory(isExpanded ? null : cat.id)}
                          className="text-slate-400 hover:text-slate-600"
                        >
                          {isExpanded ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
                        </button>
                        <div>
                          <p className="font-medium text-slate-800">{cat.name}</p>
                          {cat.description && (
                            <p className="text-sm text-slate-500">{cat.description}</p>
                          )}
                        </div>
                        <span className="rounded-full bg-indigo-100 px-2 py-0.5 text-xs text-indigo-700">
                          {subs.length} sous-catégorie{subs.length !== 1 ? "s" : ""}
                        </span>
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={() => openEditModal("category", cat)}
                          className="rounded-lg p-2 hover:bg-slate-100"
                        >
                          <Pencil size={16} className="text-slate-500" />
                        </button>
                        <button
                          onClick={() => confirmDelete(cat.id, "category")}
                          className="rounded-lg p-2 hover:bg-red-50"
                        >
                          <Trash2 size={16} className="text-red-500" />
                        </button>
                      </div>
                    </div>

                    {/* Sous-catégories dépliées */}
                    {isExpanded && (
                      <div className="border-t border-slate-100 bg-slate-50 px-4 py-3 space-y-2">
                        {subs.length === 0 ? (
                          <p className="text-sm text-slate-400 py-2">Aucune sous-catégorie.</p>
                        ) : (
                          subs.map((sub) => (
                            <div key={sub.id} className="flex items-center justify-between rounded-lg bg-white p-3 shadow-sm">
                              <div>
                                <p className="text-sm font-medium text-slate-700">{sub.name}</p>
                                {sub.description && (
                                  <p className="text-xs text-slate-400">{sub.description}</p>
                                )}
                              </div>
                              <div className="flex gap-2">
                                <button
                                  onClick={() => openEditModal("subcategory", sub)}
                                  className="rounded-lg p-1.5 hover:bg-slate-100"
                                >
                                  <Pencil size={14} className="text-slate-500" />
                                </button>
                                <button
                                  onClick={() => confirmDelete(sub.id, "subcategory")}
                                  className="rounded-lg p-1.5 hover:bg-red-50"
                                >
                                  <Trash2 size={14} className="text-red-500" />
                                </button>
                              </div>
                            </div>
                          ))
                        )}
                        <button
                          onClick={() => {
                            setModalType("subcategory");
                            setEditItem(null);
                            setFormName("");
                            setFormDescription("");
                            setFormCategoryId(cat.id);
                            setOpenModal(true);
                          }}
                          className="flex items-center gap-1 text-xs text-indigo-600 hover:text-indigo-800 mt-1"
                        >
                          <Plus size={13} /> Ajouter une sous-catégorie
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* Tab: Sous-catégories */}
      {activeTab === "subcategories" && (
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-xl font-semibold text-slate-900">Liste des Sous-catégories</h2>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="border-b text-left text-sm text-slate-500">
                <tr>
                  <th className="pb-4">Nom</th>
                  <th className="pb-4">Description</th>
                  <th className="pb-4">Catégorie</th>
                  <th className="pb-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {subCategories.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="py-8 text-center text-slate-500">Aucune sous-catégorie trouvée.</td>
                  </tr>
                ) : (
                  subCategories.map((sub) => (
                    <tr key={sub.id} className="h-16">
                      <td className="font-medium text-slate-800">{sub.name}</td>
                      <td className="text-slate-500">{sub.description || "-"}</td>
                      <td>
                        <span className="rounded-full bg-indigo-100 px-3 py-1 text-xs text-indigo-700">
                          {sub.category_name}
                        </span>
                      </td>
                      <td>
                        <div className="flex justify-end gap-2">
                          <button onClick={() => openEditModal("subcategory", sub)} className="rounded-lg p-2 hover:bg-slate-100">
                            <Pencil size={16} className="text-slate-500" />
                          </button>
                          <button onClick={() => confirmDelete(sub.id, "subcategory")} className="rounded-lg p-2 hover:bg-red-50">
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
      )}

      {/* Modal Ajout/Édition */}
      {openModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-slate-800">
                {editItem ? "Modifier" : "Ajouter"}{" "}
                {modalType === "category" ? "Catégorie" : "Sous-catégorie"}
              </h2>
              <button onClick={() => setOpenModal(false)} className="rounded-lg p-2 hover:bg-slate-100">
                <X size={20} className="text-slate-600" />
              </button>
            </div>

            <div className="space-y-4">
              {modalType === "subcategory" && (
                <div>
                  <label className="mb-1 block text-sm font-medium text-slate-700">Catégorie *</label>
                  <select
                    value={formCategoryId}
                    onChange={(e) => setFormCategoryId(Number(e.target.value))}
                    className="w-full rounded-xl border border-slate-200 p-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                  >
                    <option value="">Sélectionner une catégorie</option>
                    {categories.map((cat) => (
                      <option key={cat.id} value={cat.id}>{cat.name}</option>
                    ))}
                  </select>
                </div>
              )}

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Nom *</label>
                <input
                  type="text"
                  value={formName}
                  onChange={(e) => setFormName(e.target.value)}
                  placeholder="Nom..."
                  className="w-full rounded-xl border border-slate-200 p-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                />
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Description</label>
                <textarea
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  placeholder="Description (optionnel)..."
                  rows={3}
                  className="w-full rounded-xl border border-slate-200 p-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
                />
              </div>
            </div>

            <div className="mt-5 flex justify-end gap-3">
              <button
                onClick={() => setOpenModal(false)}
                className="rounded-xl border border-slate-200 px-5 py-2 text-sm text-slate-600 hover:bg-slate-50"
              >
                Annuler
              </button>
              <button
                onClick={handleSubmit}
                className="rounded-xl bg-indigo-600 px-5 py-2 text-sm font-medium text-white hover:bg-indigo-700"
              >
                {editItem ? "Modifier" : "Ajouter"}
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
            <p className="mt-2 text-sm text-slate-500">
              {deleteTarget?.type === "category"
                ? "La suppression de cette catégorie supprimera aussi toutes ses sous-catégories."
                : "Voulez-vous vraiment supprimer cette sous-catégorie ?"}
            </p>
            <div className="mt-5 flex justify-end gap-3">
              <button
                onClick={() => { setDeleteModal(false); setDeleteTarget(null); }}
                className="rounded-xl border border-slate-200 px-4 py-2 text-sm text-slate-600 hover:bg-slate-50"
              >
                Annuler
              </button>
              <button
                onClick={handleDelete}
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