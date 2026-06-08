import React, { useState } from "react";
import { Link } from "react-router-dom";
import axios from "axios";

const API = "http://localhost:5000/api";

export default function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async () => {
    setError("");
    if (!email.trim()) {
      setError("Veuillez saisir votre email");
      return;
    }
    setLoading(true);
    try {
      await axios.post(`${API}/auth/forgot-password`, { email });
      setSuccess(true);
    } catch (err: any) {
      setError(err.response?.data?.error || "Une erreur s'est produite");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50">
      <div className="w-full max-w-md rounded-2xl bg-white p-8 shadow-sm">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-slate-900">EduLive</h1>
          <p className="mt-2 text-slate-500">Réinitialisation du mot de passe</p>
        </div>

        {success ? (
          <div className="space-y-4 text-center">
            <div className="rounded-xl bg-green-50 border border-green-200 px-4 py-6">
              <p className="text-2xl mb-2">📧</p>
              <p className="font-medium text-green-800">Email envoyé !</p>
              <p className="mt-1 text-sm text-green-700">
                Si cet email existe dans notre système, vous recevrez un lien de réinitialisation.
              </p>
            </div>
            <Link
              to="/login"
              className="block text-sm text-blue-500 hover:underline"
            >
              Retour à la connexion
            </Link>
          </div>
        ) : (
          <div className="space-y-5">
            <p className="text-sm text-slate-500">
              Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.
            </p>

            {error && (
              <div className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
                {error}
              </div>
            )}

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSubmit()}
                placeholder="email@example.com"
                className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500"
              />
            </div>

            <button
              onClick={handleSubmit}
              disabled={loading}
              className="w-full rounded-xl bg-blue-500 py-3 font-medium text-white hover:bg-blue-600 disabled:opacity-50"
            >
              {loading ? "Envoi en cours..." : "Envoyer le lien"}
            </button>

            <div className="text-center">
              <Link to="/login" className="text-sm text-slate-500 hover:text-slate-700 hover:underline">
                Retour à la connexion
              </Link>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}