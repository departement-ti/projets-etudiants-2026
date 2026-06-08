import { useState, useEffect } from "react";
import { Link, useSearchParams } from "react-router-dom"; // أضفنا useSearchParams
import axios from "axios";

const API = "http://localhost:5000/api";

interface Level {
  id: number;
  name: string;
}

export default function RegisterPage() {
  const [levels, setLevels] = useState<Level[]>([]);
  const [searchParams] = useSearchParams(); // لاستخراج البيانات من الرابط
  const [form, setForm] = useState({
    full_name: "", email: "", phone: "", level_id: "", message: "",
  });
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  // جلب المستويات عند تحميل الصفحة
  useEffect(() => {
    axios.get(`${API}/levels`)
      .then((res) => setLevels(res.data))
      .catch(() => {});
  }, []);

  // التقاط level_id من الرابط وتحديث الفورم تلقائياً
  useEffect(() => {
    const levelIdFromUrl = searchParams.get("level");
    if (levelIdFromUrl) {
      setForm((prev) => ({ ...prev, level_id: levelIdFromUrl }));
    }
  }, [searchParams]);

  const handleSubmit = async () => {
    setError("");
    if (!form.full_name || !form.email) {
      setError("Nom et email sont obligatoires");
      return;
    }
    setLoading(true);
    try {
      await axios.post(`${API}/registrations`, form);
      setSuccess(true);
    } catch {
      setError("Erreur lors de l'envoi de la demande");
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <div className="text-center">
          <div className="text-6xl mb-4">✅</div>
          <h2 className="text-2xl font-bold text-slate-900">Demande envoyée !</h2>
          <p className="mt-2 text-slate-500">Votre demande d'inscription a été reçue. Nous vous contacterون bientôt.</p>
          <Link to="/" className="mt-6 inline-block rounded-xl bg-blue-500 px-6 py-3 text-white hover:bg-blue-600">
            Retour à l'accueil
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-slate-50 py-16">
      <div className="mx-auto max-w-2xl px-6">
        <div className="text-center mb-10">
          <h1 className="text-4xl font-bold text-slate-900">Inscription</h1>
          <p className="mt-3 text-slate-500">Remplissez le formulaire pour soumettre votre demande</p>
        </div>

        <div className="rounded-2xl bg-white p-8 shadow-sm">
          {error && <div className="mb-4 rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-red-700 text-sm">{error}</div>}

          <div className="space-y-5">
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Nom complet *</label>
              <input type="text" value={form.full_name} onChange={(e) => setForm({...form, full_name: e.target.value})}
                placeholder="Votre nom complet"
                className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500" />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Email *</label>
              <input type="email" value={form.email} onChange={(e) => setForm({...form, email: e.target.value})}
                placeholder="votre@email.com"
                className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500" />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Téléphone</label>
              <input type="text" value={form.phone} onChange={(e) => setForm({...form, phone: e.target.value})}
                placeholder="+216 XX XXX XXX"
                className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500" />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Niveau souhaité</label>
              <select value={form.level_id} onChange={(e) => setForm({...form, level_id: e.target.value})}
                className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500">
                <option value="">-- Choisir un niveau --</option>
                {levels.map((l) => (
                  <option key={l.id} value={l.id}>{l.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Message</label>
              <textarea value={form.message} onChange={(e) => setForm({...form, message: e.target.value})}
                placeholder="Informations supplémentaires..." rows={4}
                className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500" />
            </div>
            <button onClick={handleSubmit} disabled={loading}
              className="w-full rounded-xl bg-blue-500 py-3 font-semibold text-white hover:bg-blue-600 disabled:opacity-50">
              {loading ? "Envoi..." : "Soumettre ma demande"}
            </button>
          </div>

          <p className="mt-4 text-center text-sm text-slate-500">
            Déjà inscrit ?{" "}
            <Link to="/login" className="text-blue-500 hover:underline">Connectez-vous</Link>
          </p>
        </div>
      </div>
    </div>
  );
}