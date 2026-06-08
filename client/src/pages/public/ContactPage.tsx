import { useState, useEffect } from "react";
import axios from "axios";

const API = "http://localhost:5000/api";

interface ContactSettings {
  primary_phone: string;
  secondary_phone: string;
  email: string;
  address: string;
  working_hours: string;
}

export default function ContactPage() {
  const [form, setForm] = useState({
    full_name: "", email: "", phone: "", subject: "", message: "",
  });
  const [settings, setSettings] = useState<ContactSettings | null>(null);
  const [success, setSuccess] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    axios.get(`${API}/settings/contact`)
      .then((res) => setSettings(res.data))
      .catch(() => {});
  }, []);

  const handleSubmit = async () => {
    setError(""); setSuccess("");
    if (!form.full_name || !form.email || !form.message) {
      setError("Veuillez remplir les champs obligatoires");
      return;
    }
    setLoading(true);
    try {
      await axios.post(`${API}/contact-messages`, form);
      setSuccess("Message envoyé avec succès ✓");
      setForm({ full_name: "", email: "", phone: "", subject: "", message: "" });
    } catch {
      setError("Erreur lors de l'envoi");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white py-16">
      <div className="mx-auto max-w-7xl px-6">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-slate-900">Contactez-nous</h1>
          <p className="mt-3 text-slate-500">Nous sommes là pour répondre à toutes vos questions</p>
        </div>

        <div className="grid grid-cols-1 gap-8 lg:grid-cols-2">
          {/* Form */}
          <div className="rounded-2xl border border-slate-200 p-8">
            <h2 className="text-xl font-semibold text-slate-800 mb-2">Envoyez-nous un message</h2>
            <p className="text-sm text-slate-500 mb-6">Remplissez le formulaire ci-dessous</p>

            {success && <div className="mb-4 rounded-xl bg-green-50 border border-green-200 px-4 py-3 text-green-700 text-sm">{success}</div>}
            {error && <div className="mb-4 rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-red-700 text-sm">{error}</div>}

            <div className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Nom complet *</label>
                <input type="text" value={form.full_name}
                  onChange={(e) => setForm({...form, full_name: e.target.value})}
                  placeholder="Votre nom"
                  className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Email *</label>
                <input type="email" value={form.email}
                  onChange={(e) => setForm({...form, email: e.target.value})}
                  placeholder="votre@email.com"
                  className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Téléphone</label>
                <input type="text" value={form.phone}
                  onChange={(e) => setForm({...form, phone: e.target.value})}
                  placeholder="+216 XX XXX XXX"
                  className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Sujet</label>
                <input type="text" value={form.subject}
                  onChange={(e) => setForm({...form, subject: e.target.value})}
                  placeholder="Sujet de votre message"
                  className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Message *</label>
                <textarea value={form.message}
                  onChange={(e) => setForm({...form, message: e.target.value})}
                  placeholder="Votre message..." rows={5}
                  className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500" />
              </div>
              <button onClick={handleSubmit} disabled={loading}
                className="w-full rounded-xl bg-blue-500 py-3 font-semibold text-white hover:bg-blue-600 disabled:opacity-50">
                {loading ? "Envoi..." : "Envoyer le message"}
              </button>
            </div>
          </div>

          {/* Info from DB */}
          <div className="space-y-6">
            <div className="rounded-2xl border border-slate-200 p-8">
              <h2 className="text-xl font-semibold text-slate-800 mb-6">Informations de contact</h2>
              <div className="space-y-4">
                {settings?.email && (
                  <div className="flex items-start gap-3">
                    <span className="text-blue-500 text-xl">✉️</span>
                    <div>
                      <p className="font-medium text-slate-700">Email</p>
                      <p className="text-slate-500">{settings.email}</p>
                    </div>
                  </div>
                )}
                {settings?.primary_phone && (
                  <div className="flex items-start gap-3">
                    <span className="text-blue-500 text-xl">📞</span>
                    <div>
                      <p className="font-medium text-slate-700">Téléphone</p>
                      <p className="text-slate-500">{settings.primary_phone}</p>
                      {settings?.secondary_phone && (
                        <p className="text-slate-500">{settings.secondary_phone}</p>
                      )}
                    </div>
                  </div>
                )}
                {settings?.address && (
                  <div className="flex items-start gap-3">
                    <span className="text-blue-500 text-xl">📍</span>
                    <div>
                      <p className="font-medium text-slate-700">Adresse</p>
                      <p className="text-slate-500">{settings.address}</p>
                    </div>
                  </div>
                )}
              </div>
            </div>

            <div className="rounded-2xl border border-slate-200 p-8">
              <h2 className="text-xl font-semibold text-slate-800 mb-6">Horaires de travail</h2>
              <div className="space-y-3 text-sm">
                <div className="flex justify-between">
                  <span className="text-slate-600">Lundi - Vendredi</span>
                  <span className="font-medium text-slate-800">08h00 - 20h00</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-600">Samedi</span>
                  <span className="font-medium text-slate-800">9h00 - 13h00</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-600">Dimanche</span>
                  <span className="font-medium text-red-500">Fermé</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}