import React, { useState, useEffect } from "react";
import { User, Mail, Phone, Lock, Save, Eye, EyeOff } from "lucide-react";
import axios from "axios";
import { getToken } from "../services/auth";

const API = "http://localhost:5000/api";

interface Profile {
  id: number;
  full_name: string;
  email: string;
  phone: string;
  role: string;
  created_at: string;
}

export default function Profile() {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<"info" | "password">("info");

  const [formData, setFormData] = useState({
    full_name: "",
    email: "",
    phone: "",
  });

  const [passwordData, setPasswordData] = useState({
    current_password: "",
    new_password: "",
    confirm_password: "",
  });

  const [showPasswords, setShowPasswords] = useState({
    current: false,
    new: false,
    confirm: false,
  });

  const [successMsg, setSuccessMsg] = useState("");
  const [errorMsg, setErrorMsg] = useState("");

  const headers = { Authorization: `Bearer ${getToken()}` };

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const res = await axios.get(`${API}/profile`, { headers });
      setProfile(res.data);
      setFormData({
        full_name: res.data.full_name,
        email: res.data.email,
        phone: res.data.phone || "",
      });
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateProfile = async () => {
    setSuccessMsg("");
    setErrorMsg("");
    if (!formData.full_name || !formData.email) {
      setErrorMsg("Nom et email sont obligatoires");
      return;
    }
    try {
      await axios.put(`${API}/profile`, formData, { headers });
      setSuccessMsg("Profil mis à jour avec succès ✓");
      fetchProfile();
    } catch (err: any) {
      setErrorMsg(err.response?.data?.error || "Erreur lors de la mise à jour");
    }
  };

  const handleChangePassword = async () => {
    setSuccessMsg("");
    setErrorMsg("");
    if (!passwordData.current_password || !passwordData.new_password || !passwordData.confirm_password) {
      setErrorMsg("Tous les champs sont obligatoires");
      return;
    }
    if (passwordData.new_password !== passwordData.confirm_password) {
      setErrorMsg("Les nouveaux mots de passe ne correspondent pas");
      return;
    }
    if (passwordData.new_password.length < 6) {
      setErrorMsg("Le mot de passe doit contenir au moins 6 caractères");
      return;
    }
    try {
      await axios.put(`${API}/profile/password`, {
        current_password: passwordData.current_password,
        new_password: passwordData.new_password,
      }, { headers });
      setSuccessMsg("Mot de passe modifié avec succès ✓");
      setPasswordData({ current_password: "", new_password: "", confirm_password: "" });
    } catch (err: any) {
      setErrorMsg(err.response?.data?.error || "Erreur lors du changement");
    }
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString("fr-FR", {
      day: "numeric", month: "long", year: "numeric",
    });
  };

  const tabClass = (tab: "info" | "password") =>
    `px-6 py-3 text-sm font-medium rounded-xl transition ${
      activeTab === tab
        ? "bg-white text-slate-900 shadow-sm"
        : "text-slate-500 hover:text-slate-800"
    }`;

  if (loading) {
    return <div className="text-center py-20 text-slate-400">Chargement...</div>;
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Mon Profil</h1>
        <p className="mt-1 text-slate-500">Gérez vos informations personnelles</p>
      </div>

      {/* بطاقة المعلومات */}
      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <div className="flex items-center gap-5">
          <div className="flex h-20 w-20 items-center justify-center rounded-full bg-blue-100 text-3xl font-bold text-blue-600">
            {profile?.full_name?.charAt(0).toUpperCase()}
          </div>
          <div>
            <h2 className="text-2xl font-bold text-slate-900">{profile?.full_name}</h2>
            <p className="text-slate-500">{profile?.email}</p>
            <span className="mt-1 inline-block rounded-full bg-blue-100 px-3 py-1 text-xs font-medium text-blue-700 capitalize">
              {profile?.role}
            </span>
          </div>
        </div>
        <div className="mt-4 flex gap-6 border-t pt-4 text-sm text-slate-500">
          <span>Membre depuis : <strong className="text-slate-700">{profile?.created_at ? formatDate(profile.created_at) : "-"}</strong></span>
          {profile?.phone && <span>Tél : <strong className="text-slate-700">{profile.phone}</strong></span>}
        </div>
      </div>

      {/* Tabs */}
      <div className="flex rounded-2xl bg-slate-100 p-1 w-fit">
        <button onClick={() => { setActiveTab("info"); setSuccessMsg(""); setErrorMsg(""); }} className={tabClass("info")}>
          Informations
        </button>
        <button onClick={() => { setActiveTab("password"); setSuccessMsg(""); setErrorMsg(""); }} className={tabClass("password")}>
          Mot de passe
        </button>
      </div>

      {successMsg && (
        <div className="rounded-xl bg-green-50 border border-green-200 px-4 py-3 text-green-700 text-sm">
          {successMsg}
        </div>
      )}
      {errorMsg && (
        <div className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-red-700 text-sm">
          {errorMsg}
        </div>
      )}

      {/* Tab: Informations */}
      {activeTab === "info" && (
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <h2 className="mb-6 text-xl font-semibold text-slate-800">Modifier les informations</h2>
          <div className="space-y-5">
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Nom complet *</label>
              <div className="relative">
                <User size={18} className="absolute left-3 top-3.5 text-slate-400" />
                <input
                  type="text"
                  value={formData.full_name}
                  onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                  className="w-full rounded-xl border border-slate-300 py-3 pl-10 pr-4 outline-none focus:border-blue-500"
                  placeholder="Nom complet"
                />
              </div>
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Email *</label>
              <div className="relative">
                <Mail size={18} className="absolute left-3 top-3.5 text-slate-400" />
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="w-full rounded-xl border border-slate-300 py-3 pl-10 pr-4 outline-none focus:border-blue-500"
                  placeholder="Email"
                />
              </div>
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Téléphone</label>
              <div className="relative">
                <Phone size={18} className="absolute left-3 top-3.5 text-slate-400" />
                <input
                  type="text"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="w-full rounded-xl border border-slate-300 py-3 pl-10 pr-4 outline-none focus:border-blue-500"
                  placeholder="+216 XX XXX XXX"
                />
              </div>
            </div>
            <button
              onClick={handleUpdateProfile}
              className="flex items-center gap-2 rounded-xl bg-blue-500 px-6 py-3 text-white hover:bg-blue-600"
            >
              <Save size={18} /> Enregistrer
            </button>
          </div>
        </div>
      )}

      {/* Tab: Mot de passe */}
      {activeTab === "password" && (
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <h2 className="mb-6 text-xl font-semibold text-slate-800">Changer le mot de passe</h2>
          <div className="space-y-5 max-w-md">
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Mot de passe actuel</label>
              <div className="relative">
                <Lock size={18} className="absolute left-3 top-3.5 text-slate-400" />
                <input
                  type={showPasswords.current ? "text" : "password"}
                  value={passwordData.current_password}
                  onChange={(e) => setPasswordData({ ...passwordData, current_password: e.target.value })}
                  className="w-full rounded-xl border border-slate-300 py-3 pl-10 pr-10 outline-none focus:border-blue-500"
                  placeholder="••••••••"
                />
                <button onClick={() => setShowPasswords({ ...showPasswords, current: !showPasswords.current })} className="absolute right-3 top-3.5 text-slate-400">
                  {showPasswords.current ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Nouveau mot de passe</label>
              <div className="relative">
                <Lock size={18} className="absolute left-3 top-3.5 text-slate-400" />
                <input
                  type={showPasswords.new ? "text" : "password"}
                  value={passwordData.new_password}
                  onChange={(e) => setPasswordData({ ...passwordData, new_password: e.target.value })}
                  className="w-full rounded-xl border border-slate-300 py-3 pl-10 pr-10 outline-none focus:border-blue-500"
                  placeholder="••••••••"
                />
                <button onClick={() => setShowPasswords({ ...showPasswords, new: !showPasswords.new })} className="absolute right-3 top-3.5 text-slate-400">
                  {showPasswords.new ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Confirmer le nouveau mot de passe</label>
              <div className="relative">
                <Lock size={18} className="absolute left-3 top-3.5 text-slate-400" />
                <input
                  type={showPasswords.confirm ? "text" : "password"}
                  value={passwordData.confirm_password}
                  onChange={(e) => setPasswordData({ ...passwordData, confirm_password: e.target.value })}
                  className="w-full rounded-xl border border-slate-300 py-3 pl-10 pr-10 outline-none focus:border-blue-500"
                  placeholder="••••••••"
                />
                <button onClick={() => setShowPasswords({ ...showPasswords, confirm: !showPasswords.confirm })} className="absolute right-3 top-3.5 text-slate-400">
                  {showPasswords.confirm ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>
            <button
              onClick={handleChangePassword}
              className="flex items-center gap-2 rounded-xl bg-blue-500 px-6 py-3 text-white hover:bg-blue-600"
            >
              <Save size={18} /> Modifier le mot de passe
            </button>
          </div>
        </div>
      )}
    </div>
  );
}