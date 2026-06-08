import React, { useState } from "react";
import { useNavigate, useSearchParams, Link } from "react-router-dom";
import axios from "axios";

const API = "http://localhost:5000/api";

export default function ResetPassword() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const token = searchParams.get("token");

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async () => {
    setError("");
    if (!password || !confirmPassword) {
      setError("Veuillez remplir tous les champs");
      return;
    }
    if (password.length < 6) {
      setError("Le mot de passe doit contenir au moins 6 caractères");
      return;
    }
    if (password !== confirmPassword) {
      setError("Les mots de passe ne correspondent pas");
      return;
    }
    if (!token) {
      setError("Lien invalide");
      return;
    }
    setLoading(true);
    try {
      await axios.post(`${API}/auth/reset-password`, { token, password });
      setSuccess(true);
      setTimeout(() => navigate("/login"), 3000);
    } catch (err: any) {
      setError(err.response?.data?.error || "Lien invalide ou expiré");
    } finally {
      setLoading(false);
    }
  };

  if (!token) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <div className="w-full max-w-md rounded-2xl bg-white p-8 shadow-sm text-center">
          <p className="text-2xl mb-4">❌</p>
          <h2 className="text-xl font-semibold text-slate-800">Lien invalide</h2>
          <p className="mt-2 text-sm text-slate-500">Ce lien de réinitialisation est invalide.</p>
          <Link to="/login" className="mt-4 block text-sm text-blue-500 hover:underline">
            Retour à la connexion
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50">
      <div className="w-full max-w-md rounded-2xl bg-white p-8 shadow-sm">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-slate-900">EduLive</h1>
          <p className="mt-2 text-slate-500">Nouveau mot de passe</p>
        </div>

        {success ? (
          <div className="space-y-4 text-center">
            <div className="rounded-xl bg-green-50 border border-green-200 px-4 py-6">
              <p className="text-2xl mb-2">✅</p>
              <p className="font-medium text-green-800">Mot de passe modifié !</p>
              <p className="mt-1 text-sm text-green-700">
                Vous serez redirigé vers la page de connexion dans 3 secondes...
              </p>
            </div>
          </div>
        ) : (
          <div className="space-y-5">
            {error && (
              <div className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
                {error}
              </div>
            )}

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">
                Nouveau mot de passe
              </label>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full rounded-xl border border-slate-300 px-4 py-3 pr-12 outline-none focus:border-blue-500"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-3.5 text-slate-400 hover:text-slate-600"
                >
                  {showPassword ? "🙈" : "👁️"}
                </button>
              </div>
            </div>

            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">
                Confirmer le mot de passe
              </label>
              <input
                type={showPassword ? "text" : "password"}
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSubmit()}
                placeholder="••••••••"
                className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500"
              />
            </div>

            <button
              onClick={handleSubmit}
              disabled={loading}
              className="w-full rounded-xl bg-blue-500 py-3 font-medium text-white hover:bg-blue-600 disabled:opacity-50"
            >
              {loading ? "Modification en cours..." : "Modifier le mot de passe"}
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