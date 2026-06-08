import React, { useState, useEffect } from "react";
import { Send, Trash2, Plus, Users, X, Lock, MessageCircle } from "lucide-react";
import axios from "axios";
import { getToken } from "../services/auth";

const API = "http://localhost:5000/api";

interface Message {
  id: number;
  sender_name: string;
  content: string;
  created_at: string;
}

interface Conversation {
  id: number;
  title: string;
  type: string;
  type_detail: string;
  created_at: string;
}

interface AppUser {
  id: number;
  full_name: string;
  role: string;
}

export default function Messages() {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [messageText, setMessageText] = useState("");
  const [openModal, setOpenModal] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [activeTab, setActiveTab] = useState<"group" | "private">("group");
  const [deleteModal, setDeleteModal] = useState(false);
  const [deleteTargetId, setDeleteTargetId] = useState<number | null>(null);
  const [showUsersModal, setShowUsersModal] = useState(false);
  const [allUsers, setAllUsers] = useState<AppUser[]>([]);

  const headers = { Authorization: `Bearer ${getToken()}` };

  useEffect(() => {
    fetchConversations();
  }, []);

  useEffect(() => {
    if (selectedId) fetchMessages(selectedId);
    else setMessages([]);
  }, [selectedId]);

  const fetchConversations = async () => {
    try {
      const res = await axios.get(`${API}/messages/conversations`, { headers });
      setConversations(res.data);
      const groups = res.data.filter((c: Conversation) => c.type_detail === "group");
      if (groups.length > 0) setSelectedId(groups[0].id);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchMessages = async (convId: number) => {
    try {
      const res = await axios.get(`${API}/messages/conversations/${convId}/messages`, { headers });
      setMessages(res.data);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchAllUsers = async () => {
    try {
      const res = await axios.get(`${API}/users`, { headers });
      setAllUsers(res.data.filter((u: AppUser) => u.role !== "admin"));
    } catch (err) {
      console.error(err);
    }
  };

  const handleSendMessage = async () => {
    if (!messageText.trim() || !selectedId) return;
    try {
      const res = await axios.post(
        `${API}/messages/conversations/${selectedId}/messages`,
        { content: messageText, sender_name: "Admin" },
        { headers }
      );
      setMessages((prev) => [...prev, res.data]);
      setMessageText("");
    } catch (err) {
      console.error(err);
    }
  };

  const confirmDelete = (id: number) => {
    setDeleteTargetId(id);
    setDeleteModal(true);
  };

  const handleDeleteConversation = async () => {
    if (!deleteTargetId) return;
    try {
      await axios.delete(`${API}/messages/conversations/${deleteTargetId}`, { headers });
      const updated = conversations.filter((c) => c.id !== deleteTargetId);
      setConversations(updated);
      if (selectedId === deleteTargetId) {
        setSelectedId(updated.length > 0 ? updated[0].id : null);
      }
      setDeleteModal(false);
      setDeleteTargetId(null);
    } catch (err) {
      console.error(err);
    }
  };

  const handleCreateConversation = async () => {
    if (!newTitle.trim()) return alert("Veuillez entrer le titre");
    try {
      const res = await axios.post(
        `${API}/messages/conversations`,
        { title: newTitle, type: "Groupe" },
        { headers }
      );
      setConversations((prev) => [res.data, ...prev]);
      setSelectedId(res.data.id);
      setNewTitle("");
      setOpenModal(false);
    } catch (err) {
      console.error(err);
    }
  };

  const handleStartPrivateChat = async (targetUserId: number) => {
    try {
      const res = await axios.post(
        `${API}/messages/conversations/private`,
        { targetUserId },
        { headers }
      );
      const exists = conversations.find((c) => c.id === res.data.id);
      if (!exists) setConversations((prev) => [res.data, ...prev]);
      setSelectedId(res.data.id);
      setActiveTab("private");
      setShowUsersModal(false);
    } catch (err) {
      console.error(err);
    }
  };

  const groupConversations = conversations.filter((c) => c.type_detail === "group");
  const privateConversations = conversations.filter((c) => c.type_detail === "private");
  const selectedConversation = conversations.find((c) => c.id === selectedId) || null;

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleString("fr-FR", {
      day: "numeric", month: "short", hour: "2-digit", minute: "2-digit",
    });
  };

  const tabClass = (tab: "group" | "private") =>
    `flex-1 py-2 text-sm font-medium rounded-xl transition ${
      activeTab === tab ? "bg-blue-500 text-white" : "text-slate-500 hover:text-slate-800"
    }`;

  return (
    <div className="space-y-6">

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Messagerie</h1>
          <p className="mt-1 text-slate-500">Communiquez avec les enseignants et les étudiants</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => { fetchAllUsers(); setShowUsersModal(true); }}
            className="flex items-center gap-2 rounded-xl border border-indigo-200 bg-indigo-50 px-4 py-2 text-sm text-indigo-700 hover:bg-indigo-100"
          >
            <Lock size={16} /> Message privé
          </button>
          <button
            onClick={() => setOpenModal(true)}
            className="flex items-center gap-2 rounded-xl bg-blue-500 px-4 py-2 text-sm text-white hover:bg-blue-600"
          >
            <Plus size={18} /> Nouveau groupe
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">

        {/* قائمة المحادثات */}
        <div className="rounded-2xl bg-white p-4 shadow-sm">
          <div className="flex gap-1 rounded-xl bg-slate-100 p-1 mb-4">
            <button onClick={() => setActiveTab("group")} className={tabClass("group")}>
              <span className="flex items-center justify-center gap-1">
                <Users size={14} /> Groupe
              </span>
            </button>
            <button onClick={() => setActiveTab("private")} className={tabClass("private")}>
              <span className="flex items-center justify-center gap-1">
                <Lock size={14} /> Privé
              </span>
            </button>
          </div>

          {activeTab === "group" && (
            <div className="space-y-2">
              {groupConversations.length === 0 ? (
                <p className="text-sm text-slate-400 text-center py-4">Aucune conversation.</p>
              ) : (
                groupConversations.map((conv) => (
                  <button
                    key={conv.id}
                    onClick={() => setSelectedId(conv.id)}
                    className={`w-full rounded-xl border p-3 text-left transition ${
                      selectedId === conv.id ? "border-blue-200 bg-blue-50" : "border-slate-100 hover:bg-slate-50"
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="rounded-lg bg-blue-100 p-1.5">
                          <Users size={14} className="text-blue-600" />
                        </div>
                        <span className="font-medium text-slate-800 text-sm">{conv.title}</span>
                      </div>
                      <button
                        onClick={(e) => { e.stopPropagation(); confirmDelete(conv.id); }}
                        className="rounded p-1 hover:bg-red-50"
                      >
                        <Trash2 size={14} className="text-red-400" />
                      </button>
                    </div>
                    <p className="mt-1 text-xs text-slate-400 pl-8">{formatDate(conv.created_at)}</p>
                  </button>
                ))
              )}
            </div>
          )}

          {activeTab === "private" && (
            <div className="space-y-2">
              {privateConversations.length === 0 ? (
                <div className="text-center py-6">
                  <MessageCircle size={32} className="mx-auto text-slate-300 mb-2" />
                  <p className="text-sm text-slate-400">Aucun message privé.</p>
                </div>
              ) : (
                privateConversations.map((conv) => (
                  <button
                    key={conv.id}
                    onClick={() => setSelectedId(conv.id)}
                    className={`w-full rounded-xl border p-3 text-left transition ${
                      selectedId === conv.id ? "border-indigo-200 bg-indigo-50" : "border-slate-100 hover:bg-slate-50"
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="rounded-lg bg-indigo-100 p-1.5">
                          <Lock size={14} className="text-indigo-600" />
                        </div>
                        <span className="font-medium text-slate-800 text-sm">{conv.title}</span>
                      </div>
                      <button
                        onClick={(e) => { e.stopPropagation(); confirmDelete(conv.id); }}
                        className="rounded p-1 hover:bg-red-50"
                      >
                        <Trash2 size={14} className="text-red-400" />
                      </button>
                    </div>
                    <p className="mt-1 text-xs text-slate-400 pl-8">{formatDate(conv.created_at)}</p>
                  </button>
                ))
              )}
            </div>
          )}
        </div>

        {/* نافذة الدردشة */}
        <div className="rounded-2xl bg-white p-6 shadow-sm lg:col-span-2">
          {selectedConversation ? (
            <>
              <div className="mb-4 flex items-center gap-3 border-b pb-4">
                <div className={`rounded-xl p-2 ${selectedConversation.type_detail === "group" ? "bg-blue-100" : "bg-indigo-100"}`}>
                  {selectedConversation.type_detail === "group"
                    ? <Users size={18} className="text-blue-600" />
                    : <Lock size={18} className="text-indigo-600" />
                  }
                </div>
                <div>
                  <h2 className="text-lg font-semibold text-slate-900">{selectedConversation.title}</h2>
                  <p className="text-xs text-slate-400">
                    {selectedConversation.type_detail === "group" ? "Conversation de groupe" : "Message privé"}
                  </p>
                </div>
              </div>

              <div className="mb-4 min-h-[320px] max-h-[400px] overflow-y-auto rounded-xl border border-slate-100 bg-slate-50 p-4">
                {messages.length > 0 ? (
                  <div className="space-y-3">
                    {messages.map((msg) => {
                      const isAdmin = msg.sender_name === "Admin";
                      return (
                        <div key={msg.id} className={`flex ${isAdmin ? "justify-end" : "justify-start"}`}>
                          <div className={`max-w-[70%] rounded-2xl px-4 py-3 ${
                            isAdmin ? "bg-blue-500 text-white rounded-br-sm" : "bg-white shadow-sm rounded-bl-sm"
                          }`}>
                            {!isAdmin && (
                              <p className="text-xs font-semibold text-slate-500 mb-1">{msg.sender_name}</p>
                            )}
                            <p className={`text-sm ${isAdmin ? "text-white" : "text-slate-800"}`}>{msg.content}</p>
                            <p className={`text-xs mt-1 ${isAdmin ? "text-blue-200" : "text-slate-400"}`}>
                              {formatDate(msg.created_at)}
                            </p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div className="flex h-full items-center justify-center text-slate-400 text-sm">
                    Aucun message dans cette conversation
                  </div>
                )}
              </div>

              <div className="flex items-center gap-3">
                <input
                  type="text"
                  value={messageText}
                  onChange={(e) => setMessageText(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && handleSendMessage()}
                  placeholder="Tapez votre message..."
                  className="flex-1 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-blue-400 focus:bg-white"
                />
                <button
                  onClick={handleSendMessage}
                  className="rounded-xl bg-blue-500 p-3 text-white hover:bg-blue-600"
                >
                  <Send size={18} />
                </button>
              </div>
            </>
          ) : (
            <div className="flex min-h-[400px] flex-col items-center justify-center text-slate-400 gap-3">
              <MessageCircle size={48} className="text-slate-200" />
              <p>Sélectionnez une conversation</p>
            </div>
          )}
        </div>
      </div>

      {/* Modal إنشاء محادثة جماعية */}
      {openModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-slate-800">Nouvelle conversation de groupe</h2>
              <button onClick={() => { setOpenModal(false); setNewTitle(""); }} className="rounded-lg p-2 hover:bg-slate-100">
                <X size={20} className="text-slate-600" />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700">Titre</label>
                <input
                  type="text"
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  placeholder="Ex: Groupe Maths A"
                  className="w-full rounded-xl border border-slate-200 p-3 text-sm outline-none focus:border-blue-400"
                />
              </div>
              <div className="flex gap-3">
                <button
                  onClick={() => { setOpenModal(false); setNewTitle(""); }}
                  className="flex-1 rounded-xl border border-slate-200 py-2 text-sm text-slate-600 hover:bg-slate-50"
                >
                  Annuler
                </button>
                <button
                  onClick={handleCreateConversation}
                  className="flex-1 rounded-xl bg-blue-500 py-2 text-sm font-medium text-white hover:bg-blue-600"
                >
                  Créer
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Modal اختيار المستخدم للرسالة الخاصة */}
      {showUsersModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-slate-800">Choisir un utilisateur</h2>
              <button onClick={() => setShowUsersModal(false)}><X size={20} /></button>
            </div>

            {/* أساتذة */}
            <p className="text-xs font-semibold text-slate-400 uppercase mb-2">Enseignants</p>
            <div className="space-y-2 mb-4">
              {allUsers.filter(u => u.role === "teacher").length === 0 ? (
                <p className="text-xs text-slate-400 py-1">Aucun enseignant.</p>
              ) : (
                allUsers.filter(u => u.role === "teacher").map((u) => (
                  <button
                    key={u.id}
                    onClick={() => handleStartPrivateChat(u.id)}
                    className="w-full rounded-xl border border-slate-100 p-3 text-left hover:bg-slate-50 transition"
                  >
                    <div className="flex items-center gap-3">
                      <div className="rounded-full bg-blue-100 p-2">
                        <Users size={14} className="text-blue-600" />
                      </div>
                      <span className="font-medium text-slate-800 text-sm">{u.full_name}</span>
                    </div>
                  </button>
                ))
              )}
            </div>

            {/* طلاب */}
            <p className="text-xs font-semibold text-slate-400 uppercase mb-2">Étudiants</p>
            <div className="space-y-2 max-h-48 overflow-y-auto">
              {allUsers.filter(u => u.role === "student").length === 0 ? (
                <p className="text-xs text-slate-400 py-1">Aucun étudiant.</p>
              ) : (
                allUsers.filter(u => u.role === "student").map((u) => (
                  <button
                    key={u.id}
                    onClick={() => handleStartPrivateChat(u.id)}
                    className="w-full rounded-xl border border-slate-100 p-3 text-left hover:bg-slate-50 transition"
                  >
                    <div className="flex items-center gap-3">
                      <div className="rounded-full bg-indigo-100 p-2">
                        <Users size={14} className="text-indigo-600" />
                      </div>
                      <span className="font-medium text-slate-800 text-sm">{u.full_name}</span>
                    </div>
                  </button>
                ))
              )}
            </div>

            <button
              onClick={() => setShowUsersModal(false)}
              className="mt-4 w-full rounded-xl border border-slate-200 py-2 text-sm text-slate-600 hover:bg-slate-50"
            >
              Annuler
            </button>
          </div>
        </div>
      )}

      {/* Modal تأكيد الحذف */}
      {deleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-semibold text-slate-800">Confirmer la suppression</h2>
            <p className="mt-2 text-sm text-slate-500">
              Voulez-vous vraiment supprimer cette conversation et tous ses messages ?
            </p>
            <div className="mt-5 flex justify-end gap-3">
              <button
                onClick={() => { setDeleteModal(false); setDeleteTargetId(null); }}
                className="rounded-xl border border-slate-200 px-4 py-2 text-sm text-slate-600 hover:bg-slate-50"
              >
                Annuler
              </button>
              <button
                onClick={handleDeleteConversation}
                className="rounded-xl bg-red-500 px-4 py-2 text-sm font-medium text-white hover:bg-red-600"
              >
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}