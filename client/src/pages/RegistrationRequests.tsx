import React, { useEffect, useState } from "react";
import axios from "axios";
import { Eye, CheckCircle, XCircle, X } from "lucide-react";

type RequestStatus = "pending" | "approved" | "rejected";
type FilterTab = "pending" | "approved" | "rejected" | "all";

type Registration = {
  id: number;
  full_name: string;
  email: string;
  phone: string | null;
  level_id: number | null;
  level_name?: string | null;
  message: string | null;
  status: RequestStatus;
  rejection_reason: string | null;
  created_at: string;
};

export default function RegistrationRequests() {
  const [requests, setRequests] = useState<Registration[]>([]);
  const [activeTab, setActiveTab] = useState<FilterTab>("pending");
  const [loading, setLoading] = useState(false);
  const [actionLoadingId, setActionLoadingId] = useState<number | null>(null);

  const [selectedRequest, setSelectedRequest] = useState<Registration | null>(null);
  const [openDetailsModal, setOpenDetailsModal] = useState(false);

  // Modal الرفض
  const [openRejectModal, setOpenRejectModal] = useState(false);
  const [rejectTargetId, setRejectTargetId] = useState<number | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");

  // رسالة النجاح
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  useEffect(() => {
    fetchRegistrations();
  }, []);

  const fetchRegistrations = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem("token");
      const res = await axios.get("http://localhost:5000/api/registrations", {
        headers: { Authorization: `Bearer ${token}` },
      });
      setRequests(res.data);
    } catch (error) {
      console.error("Error fetching registrations:", error);
    } finally {
      setLoading(false);
    }
  };

  const showSuccess = (msg: string) => {
    setSuccessMessage(msg);
    setTimeout(() => setSuccessMessage(null), 4000);
  };

  const pendingCount = requests.filter((r) => r.status === "pending").length;
  const approvedCount = requests.filter((r) => r.status === "approved").length;
  const rejectedCount = requests.filter((r) => r.status === "rejected").length;

  const filteredRequests =
    activeTab === "all" ? requests : requests.filter((r) => r.status === activeTab);

  // القبول
  const handleApprove = async (id: number) => {
    try {
      setActionLoadingId(id);
      const token = localStorage.getItem("token");
      const res = await axios.put(
        `http://localhost:5000/api/registrations/${id}`,
        { status: "approved" },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      await fetchRegistrations();

      if (res.data.message?.includes("email sent")) {
        showSuccess("✅ تم قبول الطلب وإنشاء الحساب وإرسال بيانات الدخول بالبريد الإلكتروني.");
      } else if (res.data.message?.includes("already exists")) {
        showSuccess("✅ تم قبول الطلب — الحساب موجود مسبقاً.");
      } else {
        showSuccess("✅ تم قبول الطلب بنجاح.");
      }
    } catch (error) {
      console.error("Error approving:", error);
      alert("Erreur lors de l'approbation");
    } finally {
      setActionLoadingId(null);
    }
  };

  // فتح Modal الرفض
  const openRejectDialog = (id: number) => {
    setRejectTargetId(id);
    setRejectionReason("");
    setOpenRejectModal(true);
  };

  // تأكيد الرفض
  const handleRejectConfirm = async () => {
    if (!rejectTargetId) return;
    try {
      setActionLoadingId(rejectTargetId);
      const token = localStorage.getItem("token");
      await axios.put(
        `http://localhost:5000/api/registrations/${rejectTargetId}`,
        { status: "rejected", rejection_reason: rejectionReason || null },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      setOpenRejectModal(false);
      setRejectTargetId(null);
      setRejectionReason("");
      await fetchRegistrations();
      showSuccess("❌ تم رفض الطلب بنجاح.");
    } catch (error) {
      console.error("Error rejecting:", error);
      alert("Erreur lors du refus");
    } finally {
      setActionLoadingId(null);
    }
  };

  const getStatusBadge = (status: RequestStatus) => {
    if (status === "pending") return "bg-yellow-100 text-yellow-700";
    if (status === "approved") return "bg-green-100 text-green-700";
    return "bg-red-100 text-red-700";
  };

  const getStatusText = (status: RequestStatus) => {
    if (status === "pending") return "En attente";
    if (status === "approved") return "Approuvée";
    return "Refusée";
  };

  const tabClass = (tab: FilterTab) =>
    `rounded-xl px-4 py-2 text-sm font-medium transition ${
      activeTab === tab
        ? "bg-white text-slate-900 shadow-sm"
        : "text-slate-500 hover:text-slate-800"
    }`;

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString("fr-FR");
  };

  const openDetails = (request: Registration) => {
    setSelectedRequest(request);
    setOpenDetailsModal(true);
  };

  return (
    <div className="space-y-6">

      {/* رسالة النجاح */}
      {successMessage && (
        <div className="flex items-center gap-3 rounded-xl bg-green-50 border border-green-200 px-5 py-4 text-green-800 shadow-sm">
          <span className="text-sm font-medium">{successMessage}</span>
          <button onClick={() => setSuccessMessage(null)} className="ml-auto">
            <X size={16} />
          </button>
        </div>
      )}

      <div>
        <h1 className="text-3xl font-bold text-slate-900">Demandes d'Inscription</h1>
        <p className="mt-1 text-slate-500">Approuvez ou refusez les demandes d'inscription.</p>
      </div>

      {/* الإحصائيات */}
      <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <div className="flex items-start justify-between">
            <div>
              <p className="font-medium text-slate-800">En Attente</p>
              <h2 className="mt-10 text-4xl font-bold text-slate-900">{pendingCount}</h2>
              <p className="mt-2 text-sm text-slate-500">Demandes à traiter</p>
            </div>
            <span className="text-xl text-yellow-500">⏳</span>
          </div>
        </div>

        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <div className="flex items-start justify-between">
            <div>
              <p className="font-medium text-slate-800">Approuvées</p>
              <h2 className="mt-10 text-4xl font-bold text-slate-900">{approvedCount}</h2>
              <p className="mt-2 text-sm text-slate-500">Demandes validées</p>
            </div>
            <span className="text-xl text-green-500">✔</span>
          </div>
        </div>

        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <div className="flex items-start justify-between">
            <div>
              <p className="font-medium text-slate-800">Refusées</p>
              <h2 className="mt-10 text-4xl font-bold text-slate-900">{rejectedCount}</h2>
              <p className="mt-2 text-sm text-slate-500">Demandes rejetées</p>
            </div>
            <span className="text-xl text-red-500">✖</span>
          </div>
        </div>
      </div>

      {/* التبويبات */}
      <div className="inline-flex rounded-2xl bg-slate-100 p-1">
        <button onClick={() => setActiveTab("pending")} className={tabClass("pending")}>
          En Attente ({pendingCount})
        </button>
        <button onClick={() => setActiveTab("approved")} className={tabClass("approved")}>
          Approuvées ({approvedCount})
        </button>
        <button onClick={() => setActiveTab("rejected")} className={tabClass("rejected")}>
          Refusées ({rejectedCount})
        </button>
        <button onClick={() => setActiveTab("all")} className={tabClass("all")}>
          Toutes
        </button>
      </div>

      {/* الجدول */}
      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <h2 className="text-2xl font-semibold text-slate-900">Liste des Demandes</h2>
        <p className="mt-1 text-slate-500">
          {activeTab === "pending" ? "Demandes en attente d'approbation"
            : activeTab === "approved" ? "Demandes approuvées"
            : activeTab === "rejected" ? "Demandes refusées"
            : "Toutes les demandes"}
        </p>

        <div className="mt-6 overflow-x-auto">
          {loading ? (
            <p className="py-8 text-center text-slate-500">Chargement...</p>
          ) : (
            <table className="w-full">
              <thead className="border-b text-left text-sm text-slate-500">
                <tr>
                  <th className="pb-4">Candidat</th>
                  <th className="pb-4">Email</th>
                  <th className="pb-4">Téléphone</th>
                  <th className="pb-4">Niveau</th>
                  <th className="pb-4">Statut</th>
                  <th className="pb-4">Date</th>
                  <th className="pb-4 text-right">Actions</th>
                </tr>
              </thead>

              <tbody className="divide-y">
                {filteredRequests.length > 0 ? (
                  filteredRequests.map((request) => (
                    <tr key={request.id} className="h-24">
                      <td className="font-medium text-slate-800">{request.full_name}</td>
                      <td className="text-slate-600">{request.email}</td>
                      <td className="text-slate-600">{request.phone || "-"}</td>
                      <td className="text-slate-600">{request.level_name || "-"}</td>
                      <td>
                        <span className={`rounded-full px-3 py-1 text-xs font-medium ${getStatusBadge(request.status)}`}>
                          {getStatusText(request.status)}
                        </span>
                      </td>
                      <td className="text-slate-500">{formatDate(request.created_at)}</td>
                      <td>
                        <div className="flex justify-end gap-3">
                          <button
                            onClick={() => openDetails(request)}
                            className="rounded-lg p-2 hover:bg-slate-100"
                            title="Voir"
                          >
                            <Eye size={18} className="text-slate-600" />
                          </button>

                          <button
                            onClick={() => handleApprove(request.id)}
                            disabled={actionLoadingId === request.id || request.status === "approved"}
                            className="rounded-lg p-2 hover:bg-green-50 disabled:opacity-40"
                            title="Approuver"
                          >
                            {actionLoadingId === request.id ? (
                              <span className="text-xs text-green-600">...</span>
                            ) : (
                              <CheckCircle size={18} className="text-green-600" />
                            )}
                          </button>

                          <button
                            onClick={() => openRejectDialog(request.id)}
                            disabled={actionLoadingId === request.id || request.status === "rejected"}
                            className="rounded-lg p-2 hover:bg-red-50 disabled:opacity-40"
                            title="Refuser"
                          >
                            <XCircle size={18} className="text-red-600" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-slate-500">
                      Aucune demande trouvée.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Modal تفاصيل الطلب */}
      {openDetailsModal && selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-slate-800">Détails de la Demande</h2>
              <button
                onClick={() => { setOpenDetailsModal(false); setSelectedRequest(null); }}
                className="rounded-lg p-2 hover:bg-slate-100"
              >
                <X size={20} className="text-slate-600" />
              </button>
            </div>
            <div className="space-y-3 text-sm text-slate-700">
              <p><strong>Nom :</strong> {selectedRequest.full_name}</p>
              <p><strong>Email :</strong> {selectedRequest.email}</p>
              <p><strong>Téléphone :</strong> {selectedRequest.phone || "-"}</p>
              <p><strong>Niveau :</strong> {selectedRequest.level_name || "-"}</p>
              <p><strong>Statut :</strong> {getStatusText(selectedRequest.status)}</p>
              <p><strong>Date :</strong> {formatDate(selectedRequest.created_at)}</p>
              <p><strong>Message :</strong> {selectedRequest.message || "-"}</p>
              {selectedRequest.rejection_reason && (
                <p><strong>Raison du refus :</strong> {selectedRequest.rejection_reason}</p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Modal سبب الرفض */}
      {openRejectModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-slate-800">Raison du Refus</h2>
              <button
                onClick={() => { setOpenRejectModal(false); setRejectionReason(""); }}
                className="rounded-lg p-2 hover:bg-slate-100"
              >
                <X size={20} className="text-slate-600" />
              </button>
            </div>

            <p className="mb-4 text-sm text-slate-500">
              Vous pouvez laisser ce champ vide si vous ne souhaitez pas préciser de raison.
            </p>

            <textarea
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="Ex: Le niveau demandé est complet..."
              rows={4}
              className="w-full rounded-xl border border-slate-200 p-3 text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-red-300"
            />

            <div className="mt-5 flex justify-end gap-3">
              <button
                onClick={() => { setOpenRejectModal(false); setRejectionReason(""); }}
                className="rounded-xl border border-slate-200 px-5 py-2 text-sm text-slate-600 hover:bg-slate-50"
              >
                Annuler
              </button>
              <button
                onClick={handleRejectConfirm}
                disabled={actionLoadingId === rejectTargetId}
                className="rounded-xl bg-red-500 px-5 py-2 text-sm font-medium text-white hover:bg-red-600 disabled:opacity-50"
              >
                {actionLoadingId === rejectTargetId ? "En cours..." : "Confirmer le Refus"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}