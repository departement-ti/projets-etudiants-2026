import React, { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import axios from "axios";
import { setToken, setUser } from "../services/auth";

const API = "http://localhost:5000/api";

export default function Login() {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleLogin = async () => {
    setError("");
    if (!email || !password) {
      setError("Veuillez remplir tous les champs");
      return;
    }
    setLoading(true);
    try {
      const res = await axios.post(`${API}/auth/login`, { email, password });
      setToken(res.data.token);
      setUser(res.data.user);
      const userRole = res.data.user.role;
      if (userRole === "admin") navigate("/dashboard");
      else if (userRole === "teacher") navigate("/teacher");
      else if (userRole === "student") navigate("/student");
      else setError("Accès refusé");
    } catch (err: any) {
      setError(err.response?.data?.error || "Erreur de connexion");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50">
      <div className="w-full max-w-md rounded-2xl bg-white p-8 shadow-sm">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-slate-900">EduLive</h1>
          <p className="mt-2 text-slate-500">Connectez-vous à votre espace</p>
        </div>

        {error && (
          <div className="mb-4 rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
            {error}
          </div>
        )}

        <div className="space-y-5">
          <div>
            <label className="mb-2 block text-sm font-medium text-slate-700">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleLogin()}
              placeholder="email@example.com"
              className="w-full rounded-xl border border-slate-300 px-4 py-3 outline-none focus:border-blue-500"
            />
          </div>

          <div>
            <label className="mb-2 block text-sm font-medium text-slate-700">Mot de passe</label>
            <div className="relative">
              <input
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleLogin()}
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
            {/* رابط نسيت كلمة المرور */}
            <div className="mt-2 text-right">
              <Link
                to="/forgot-password"
                className="text-sm text-blue-500 hover:text-blue-700 hover:underline"
              >
                Mot de passe oublié ?
              </Link>
            </div>
          </div>

          <button
            onClick={handleLogin}
            disabled={loading}
            className="w-full rounded-xl bg-blue-500 py-3 font-medium text-white hover:bg-blue-600 disabled:opacity-50"
          >
            {loading ? "Connexion..." : "Se connecter"}
          </button>
        </div>
      </div>
    </div>
  );
}