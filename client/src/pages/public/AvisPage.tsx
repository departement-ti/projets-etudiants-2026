import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import axios from "axios";

const API = "http://localhost:5000/api";

interface Review {
  id: number;
  full_name: string;
  job_title: string | null;
  content: string;
  status: string;
}

export default function AvisPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    axios.get(`${API}/settings/reviews`)
      
      .then((res) => setReviews(res.data.filter((r: Review) => r.status.toLowerCase() === "active")))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="bg-slate-50 min-h-screen py-16">
      <div className="mx-auto max-w-7xl px-6">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-slate-900">Avis de nos étudiants</h1>
          <p className="mt-3 text-slate-500 text-lg">Ce que disent nos apprenants</p>
        </div>

        {loading ? (
          <div className="text-center text-slate-400 py-20">Chargement...</div>
        ) : reviews.length === 0 ? (
          <div className="text-center text-slate-400 py-20">Aucun avis disponible.</div>
        ) : (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {reviews.map((review) => (
              <div key={review.id} className="rounded-2xl bg-white p-6 shadow-sm">
                <div className="flex items-center gap-3 mb-4">
                  <div className="flex h-12 w-12 items-center justify-center rounded-full bg-orange-100 text-orange-600 font-bold text-lg">
                    {review.full_name.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <p className="font-semibold text-slate-800">{review.full_name}</p>
                    {review.job_title && (
                      <p className="text-xs text-slate-400">{review.job_title}</p>
                    )}
                    <div className="flex gap-1 text-yellow-400 text-sm">⭐⭐⭐⭐⭐</div>
                  </div>
                </div>
                <p className="text-slate-600 leading-relaxed">"{review.content}"</p>
              </div>
            ))}
          </div>
        )}

        <div className="mt-16 text-center">
          <h2 className="text-2xl font-bold text-slate-900">Prêt à rejoindre notre communauté ?</h2>
          <Link
            to="/register"
            className="mt-6 inline-block rounded-full bg-blue-500 px-10 py-4 font-semibold text-white hover:bg-blue-600 transition"
          >
            Inscrivez-vous maintenant
          </Link>
        </div>
      </div>
    </div>
  );
}