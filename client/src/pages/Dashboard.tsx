import React, { useState, useEffect } from "react";
import axios from "axios";
import { getToken } from "../services/auth";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend,
  LineChart, Line,
} from "recharts";

const API_URL = "http://localhost:5000/api/dashboard";

interface Registration {
  id: number;
  full_name: string;
  email: string;
  course: string;
  date: string;
}

const COLORS = ["#3b82f6", "#8b5cf6", "#10b981", "#f59e0b", "#ef4444", "#06b6d4"];

export default function Dashboard() {
  const [statsData, setStatsData] = useState({
    students: 0,
    teachers: 0,
    classes: 0,
    pendingRequests: 0,
  });
  const [requests, setRequests] = useState<Registration[]>([]);
  const [studentsPerGroup, setStudentsPerGroup] = useState([]);
  const [attendanceStats, setAttendanceStats] = useState([]);
  const [studentsPerLevel, setStudentsPerLevel] = useState([]);
  const [loading, setLoading] = useState(true);

  // Modal تأكيد الموافقة
  const [confirmModal, setConfirmModal] = useState(false);
  const [confirmTarget, setConfirmTarget] = useState<{ id: number; status: string } | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  const config = { headers: { Authorization: `Bearer ${getToken()}` } };

  const fetchData = async () => {
    try {
      const [statsRes, regRes, groupRes, attRes, levelRes] = await Promise.all([
        axios.get(`${API_URL}/stats`, config),
        axios.get(`${API_URL}/recent-registrations`, config),
        axios.get(`${API_URL}/students-per-group`, config),
        axios.get(`${API_URL}/attendance-stats`, config),
        axios.get(`${API_URL}/students-per-level`, config),
      ]);

      setStatsData({
        students: statsRes.data.students || 0,
        teachers: statsRes.data.teachers || 0,
        classes: statsRes.data.classes || 0,
        pendingRequests: statsRes.data.pendingRequests || 0,
      });
      setRequests(regRes.data);
      setStudentsPerGroup(groupRes.data);
      setAttendanceStats(attRes.data);
      setStudentsPerLevel(levelRes.data);
    } catch (error) {
      console.error("Erreur data fetching:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const openConfirmModal = (id: number, status: string) => {
    setConfirmTarget({ id, status });
    setConfirmModal(true);
  };

  const handleStatusUpdate = async () => {
    if (!confirmTarget) return;
    setActionLoading(true);
    try {
      await axios.put(
        `http://localhost:5000/api/registrations/${confirmTarget.id}`,
        { status: confirmTarget.status },
        { headers: { Authorization: `Bearer ${getToken()}` } }
      );
      setConfirmModal(false);
      setConfirmTarget(null);
      await fetchData();
    } catch (error) {
      alert("Erreur lors de la mise à jour");
    } finally {
      setActionLoading(false);
    }
  };

  const stats = [
    { title: "Élèves", value: statsData.students, color: "text-blue-600" },
    { title: "Enseignants", value: statsData.teachers, color: "text-purple-600" },
    { title: "Classes", value: statsData.classes, color: "text-green-600" },
    { title: "Demandes en attente", value: statsData.pendingRequests, color: "text-orange-600" },
  ];

  if (loading)
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
      </div>
    );

  return (
    <div className="space-y-8">
      <h1 className="text-3xl font-bold text-slate-900">Tableau de bord</h1>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <div key={index} className="rounded-2xl bg-white p-6 shadow-sm border border-slate-100">
            <p className="text-slate-500 text-sm font-medium">{stat.title}</p>
            <h2 className={`text-3xl font-bold mt-2 ${stat.color}`}>{stat.value}</h2>
          </div>
        ))}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* Bar Chart */}
        <div className="rounded-2xl bg-white p-6 shadow-sm border border-slate-100">
          <h2 className="text-lg font-semibold text-slate-800 mb-5">Élèves par Groupe</h2>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={studentsPerGroup} barSize={40}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="group_name" tick={{ fontSize: 11, fill: "#94a3b8" }} tickLine={false} />
              <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: "#94a3b8" }} tickLine={false} axisLine={false} />
              <Tooltip contentStyle={{ borderRadius: "12px", border: "none", boxShadow: "0 4px 20px rgba(0,0,0,0.1)" }} />
              <Bar dataKey="count" name="Élèves" radius={[6, 6, 0, 0]}>
                {studentsPerGroup.map((_: any, index: number) => (
                  <Cell key={index} fill={COLORS[index % COLORS.length]} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Pie Chart */}
      
                <div className="rounded-2xl bg-white p-6 shadow-sm border border-slate-100">
               <h2 className="text-lg font-semibold text-slate-800 mb-5">Répartition par Niveau</h2>
              <ResponsiveContainer width="100%" height={320}>
              <PieChart>
              <Pie
                data={studentsPerLevel}
                 dataKey="count"
                  nameKey="level_name"
                 cx="50%"
                 cy="50%"
                 outerRadius={100}
                 label={({ level_name, percent }: any) => `${level_name} (${(percent * 100).toFixed(0)}%)`}
                labelLine={true}
      >
                {studentsPerLevel.map((_: any, index: number) => (
                  <Cell key={index} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip contentStyle={{ borderRadius: "12px", border: "none", boxShadow: "0 4px 20px rgba(0,0,0,0.1)" }} />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Line Chart */}
      <div className="rounded-2xl bg-white p-6 shadow-sm border border-slate-100">
        <h2 className="text-lg font-semibold text-slate-800 mb-5">Taux de Présence par Groupe (%)</h2>
        <ResponsiveContainer width="100%" height={250}>
          <LineChart data={attendanceStats}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
            <XAxis dataKey="group_name" tick={{ fontSize: 11, fill: "#94a3b8" }} tickLine={false} />
            <YAxis domain={[0, 100]} tick={{ fontSize: 11, fill: "#94a3b8" }} tickLine={false} axisLine={false} unit="%" />
            <Tooltip
              formatter={(value: any) => [`${value}%`, "Présence"]}
              contentStyle={{ borderRadius: "12px", border: "none", boxShadow: "0 4px 20px rgba(0,0,0,0.1)" }}
            />
            <Line type="monotone" dataKey="rate" name="Taux" stroke="#3b82f6" strokeWidth={3} dot={{ fill: "#3b82f6", r: 5 }} activeDot={{ r: 7 }} />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Pending Registrations */}
      <div className="rounded-2xl bg-white p-6 shadow-sm border border-slate-100">
        <h2 className="text-xl font-semibold mb-6">Demandes d'inscription (En attente)</h2>
        <div className="space-y-4">
          {requests.length === 0 ? (
            <p className="text-slate-400 text-center py-4">Aucune demande en attente.</p>
          ) : (
            requests.map((req) => (
              <div key={req.id} className="flex items-center justify-between border rounded-xl p-4 hover:bg-slate-50 transition">
                <div>
                  <p className="font-semibold text-slate-800">{req.full_name}</p>
                  <p className="text-sm text-slate-500">{req.email}</p>
                  <div className="flex gap-4 mt-1">
                    <p className="text-xs font-medium text-blue-600 bg-blue-50 px-2 py-0.5 rounded">{req.course}</p>
                    <p className="text-xs text-slate-400">{req.date}</p>
                  </div>
                </div>
                <div className="flex gap-3">
                  <button
                    onClick={() => openConfirmModal(req.id, "approved")}
                    className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition"
                  >
                    Approuver
                  </button>
                  <button
                    onClick={() => openConfirmModal(req.id, "rejected")}
                    className="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition"
                  >
                    Rejeter
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Modal تأكيد */}
      {confirmModal && confirmTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-semibold text-slate-800">
              {confirmTarget.status === "approved" ? "Confirmer l'approbation" : "Confirmer le rejet"}
            </h2>
            <p className="mt-2 text-sm text-slate-500">
              {confirmTarget.status === "approved"
                ? "Un compte sera créé automatiquement et les identifiants envoyés par email."
                : "Voulez-vous vraiment rejeter cette demande ?"}
            </p>
            <div className="mt-5 flex justify-end gap-3">
              <button
                onClick={() => { setConfirmModal(false); setConfirmTarget(null); }}
                className="rounded-xl border border-slate-200 px-4 py-2 text-sm text-slate-600 hover:bg-slate-50"
              >
                Annuler
              </button>
              <button
                onClick={handleStatusUpdate}
                disabled={actionLoading}
                className={`rounded-xl px-4 py-2 text-sm font-medium text-white disabled:opacity-50 ${
                  confirmTarget.status === "approved"
                    ? "bg-green-500 hover:bg-green-600"
                    : "bg-red-500 hover:bg-red-600"
                }`}
              >
                {actionLoading ? "En cours..." : confirmTarget.status === "approved" ? "Approuver" : "Rejeter"}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}