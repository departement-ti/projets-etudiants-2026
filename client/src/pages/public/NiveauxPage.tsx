import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";

const API = "http://localhost:5000/api";

interface Level {
  id: number;
  name: string;
  description: string;
  image?: string;
  price?: number | null;
  duration?: string | null;
}

export default function NiveauxPage() {
  const [levels, setLevels] = useState<Level[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    axios.get(`${API}/levels`)
      .then((res) => setLevels(res.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const handleLevelClick = (levelId: number) => {
    navigate(`/register?level=${levelId}`);
  };

  return (
    <div className="bg-slate-50 min-h-screen py-16">
      <div className="mx-auto max-w-7xl px-6">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-slate-900">Inscrivez-vous maintenant</h1>
          <p className="mt-3 text-slate-500 text-lg">Choisissez un niveau</p>
        </div>

        {loading ? (
          <div className="text-center text-slate-400 py-20">Chargement...</div>
        ) : (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {levels.map((level) => (
              <div
                key={level.id}
                onClick={() => handleLevelClick(level.id)}
                className="group relative cursor-pointer overflow-hidden rounded-2xl shadow-md hover:shadow-xl transition-all duration-300"
              >
                {/* Image */}
                <div className="relative h-52">
                  {level.image ? (
                    <img
                      src={level.image}
                      alt={level.name}
                      className="absolute inset-0 h-full w-full object-cover transition duration-300 group-hover:scale-105"
                    />
                  ) : (
                    <div className="absolute inset-0 bg-slate-300" />
                  )}
                  {/* Blue overlay */}
                  <div className="absolute inset-0 bg-blue-900/50 group-hover:bg-blue-900/40 transition duration-300" />

                  {/* Content on image */}
                  <div className="absolute inset-0 flex flex-col items-center justify-center text-white">
                    <div className="flex h-14 w-14 items-center justify-center rounded-full bg-white/20 backdrop-blur-sm mb-3">
                      <span className="text-2xl">🎓</span>
                    </div>
                    <h2 className="text-2xl font-bold">{level.name}</h2>
                    {level.description && (
                      <p className="mt-2 text-sm text-white/80 text-center px-4">{level.description}</p>
                    )}
                  </div>
                </div>

                {/* Prix & Durée */}
                {(level.price || level.duration) && (
                  <div className="bg-white px-5 py-4 flex items-center justify-between">
                    {level.price ? (
                      <div className="flex items-center gap-2">
                        <span className="text-lg">💰</span>
                        <div>
                          <p className="text-xs text-slate-400">Prix</p>
                          <p className="font-bold text-green-600 text-sm">{level.price} DT</p>
                        </div>
                      </div>
                    ) : <div />}

                    {level.duration ? (
                      <div className="flex items-center gap-2">
                        <span className="text-lg">⏱️</span>
                        <div>
                          <p className="text-xs text-slate-400">Durée</p>
                          <p className="font-bold text-blue-600 text-sm">{level.duration}</p>
                        </div>
                      </div>
                    ) : <div />}

                    <div className="flex items-center gap-1 text-orange-500 text-sm font-medium">
                      S'inscrire
                      <span>→</span>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}