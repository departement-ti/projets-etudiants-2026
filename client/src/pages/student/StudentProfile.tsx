import { useEffect, useState } from "react";
import axios from "axios";
import { getToken } from "../../services/auth";
import { User, Mail, Phone, Save, Lock, Eye, EyeOff } from "lucide-react";

const API = "http://localhost:5000/api";

export default function StudentProfile() {
  const [profile, setProfile] = useState<any>(null);
  const [formData, setFormData] = useState({ full_name: "", email: "", phone: "" });
  const [passwordData, setPasswordData] = useState({ current_password: "", new_password: "", confirm_password: "" });
  const [activeTab, setActiveTab] = useState<"info" | "password">("info");
  const [showPasswords, setShowPasswords] = useState({ current: false, new: false, confirm: false });
  const [successMsg, setSuccessMsg] = useState("");
  const [errorMsg, setErrorMsg] = useState("");

  useEffect(() => { fetchProfile(); }, []);

  const fetchProfile = async () => {
    try {
      const res = await axios.get(`${API}/profile`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      setProfile(res.data);
      setFormData({ full_name: res.data.full_name, email: res.data.email, phone: res.data.phone || "" });
    } catch {}
  };

  const handleUpdate = async () => {
    setSuccessMsg(""); setErrorMsg("");
    try {
      await axios.put(`${API}/profile`, formData, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      const currentUser = JSON.parse(localStorage.getItem("user") || "{}");
      localStorage.setItem("user", JSON.stringify({ ...currentUser, ...formData }));
      setSuccessMsg("Profil mis à jour ✓");
      fetchProfile();
    } catch (err: any) {
      setErrorMsg(err.response?.data?.error || "Erreur");
    }
  };

  const handleChangePassword = async () => {
    setSuccessMsg(""); setErrorMsg("");
    if (passwordData.new_password !== passwordData.confirm_password) {
      setErrorMsg("Les mots de passe ne correspondent pas");
      return;
    }
    try {
      await axios.put(`${API}/profile/password`, {
        current_password: passwordData.current_password,
        new_password: passwordData.new_password,
      }, { headers: { Authorization: `Bearer ${getToken()}` } });
      setSuccessMsg("Mot de passe modifié ✓");
      setPasswordData({ current_password: "", new_password: "", confirm_password: "" });
    } catch (err: any) {
      setErrorMsg(err.response?.data?.error || "Erreur");
    }
  };

  const tabClass = (tab: string) =>
    `px-6 py-3 text-sm font-medium rounded-xl transition ${
      activeTab === tab ? "bg-white text-slate-900 shadow-sm" : "text-slate-500 hover:text-slate-800"
    }`;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Mon Profil</h1>
        <p className="mt-1 text-slate-500">Gérez vos informations personnelles</p>
      </div>

      {profile && (
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <div className="flex items-center gap-4">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-green-100 text-2xl font-bold text-green-600">
              {profile.full_name?.charAt(0).toUpperCase()}
            </div>
            <div>
              <h2 className="text-xl font-bold text-slate-900">{profile.full_name}</h2>
              <p className="text-slate-500">{profile.email}</p>
              <span className="mt-1 inline-block rounded-full bg-green-100 px-3 py-1 text-xs font-medium text-green-700">
                Étudiant
              </span>
            </div>
          </div>
        </div>
      )}

      <div className="flex rounded-2xl bg-slate-100 p-1 w-fit">
        <button onClick={() => { setActiveTab("info"); setSuccessMsg(""); setErrorMsg(""); }} className={tabClass("info")}>
          Informations
        </button>
        <button onClick={() => { setActiveTab("password"); setSuccessMsg(""); setErrorMsg(""); }} className={tabClass("password")}>
          Mot de passe
        </button>
      </div>

      {successMsg && <div className="rounded-xl bg-green-50 border border-green-200 px-4 py-3 text-green-700 text-sm">{successMsg}</div>}
      {errorMsg && <div className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-red-700 text-sm">{errorMsg}</div>}

      {activeTab === "info" && (
        <div className="rounded-2xl bg-white p-6 shadow-sm max-w-lg">
          <div className="space-y-5">
            <div>
              <label className="mb-2 block text-sm font-medium">Nom complet *</label>
              <div className="relative">
                <User size={18} className="absolute left-3 top-3.5 text-slate-400" />
                <input type="text" value={formData.full_name}
                  onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                  className="w-full rounded-xl border py-3 pl-10 pr-4 outline-none focus:border-blue-500" />
              </div>
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium">Email *</label>
              <div className="relative">
                <Mail size={18} className="absolute left-3 top-3.5 text-slate-400" />
                <input type="email" value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="w-full rounded-xl border py-3 pl-10 pr-4 outline-none focus:border-blue-500" />
              </div>
            </div>
            <div>
              <label className="mb-2 block text-sm font-medium">Téléphone</label>
              <div className="relative">
                <Phone size={18} className="absolute left-3 top-3.5 text-slate-400" />
                <input type="text" value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="w-full rounded-xl border py-3 pl-10 pr-4 outline-none focus:border-blue-500" />
              </div>
            </div>
            <button onClick={handleUpdate}
              className="flex items-center gap-2 rounded-xl bg-blue-500 px-6 py-3 text-white hover:bg-blue-600">
              <Save size={18} /> Enregistrer
            </button>
          </div>
        </div>
      )}

      {activeTab === "password" && (
        <div className="rounded-2xl bg-white p-6 shadow-sm max-w-md">
          <div className="space-y-5">
            {[
              { label: "Mot de passe actuel", key: "current" as const, field: "current_password" as const },
              { label: "Nouveau mot de passe", key: "new" as const, field: "new_password" as const },
              { label: "Confirmer", key: "confirm" as const, field: "confirm_password" as const },
            ].map((item) => (
              <div key={item.key}>
                <label className="mb-2 block text-sm font-medium">{item.label}</label>
                <div className="relative">
                  <Lock size={18} className="absolute left-3 top-3.5 text-slate-400" />
                  <input
                    type={showPasswords[item.key] ? "text" : "password"}
                    value={passwordData[item.field]}
                    onChange={(e) => setPasswordData({ ...passwordData, [item.field]: e.target.value })}
                    className="w-full rounded-xl border py-3 pl-10 pr-10 outline-none focus:border-blue-500"
                  />
                  <button onClick={() => setShowPasswords({ ...showPasswords, [item.key]: !showPasswords[item.key] })}
                    className="absolute right-3 top-3.5 text-slate-400">
                    {showPasswords[item.key] ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
              </div>
            ))}
            <button onClick={handleChangePassword}
              className="flex items-center gap-2 rounded-xl bg-blue-500 px-6 py-3 text-white hover:bg-blue-600">
              <Save size={18} /> Modifier
            </button>
          </div>
        </div>
      )}
    </div>
  );
}