import { useEffect, useState } from "react";
import axios from "axios";
import { getToken, getUser } from "../../services/auth";
import { Plus, Trash2, Send, Users, X, MessageCircle, Lock } from "lucide-react";

const API = "http://localhost:5000/api";

interface Conversation {
  id: number;
  title: string;
  type: string;
  type_detail: string;
  created_at: string;
}
interface Message {
  id: number;
  sender_name: string;
  content: string;
  created_at: string;
}
interface Student {
  id: number;
  user_id: number;
  full_name: string;
}

export default function TeacherMessages() {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [messageText, setMessageText] = useState("");
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showStudentsModal, setShowStudentsModal] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [students, setStudents] = useState<Student[]>([]);
  const [activeTab, setActiveTab] = useState<"group" | "private">("group");
  const user = getUser();

  useEffect(() => {
    fetchConversations();
    fetchStudents();
  }, []);

  useEffect(() => {
    if (selectedId) fetchMessages(selectedId);
    else setMessages([]);
  }, [selectedId]);

  const fetchConversations = async () => {
    try {
      const res = await axios.get(`${API}/messages/conversations`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      setConversations(res.data);
      const groups = res.data.filter((c: Conversation) => c.type_detail === "group");
      if (groups.length > 0) setSelectedId(groups[0].id);
    } catch {}
  };

  const fetchStudents = async () => {
    try {
      const res = await axios.get(`${API}/teacher/students`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      setStudents(res.data);
    } catch {}
  };

  const fetchMessages = async (id: number) => {
    try {
      const res = await axios.get(`${API}/messages/conversations/${id}/messages`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      setMessages(res.data);
    } catch {}
  };

  const handleSend = async () => {
    if (!messageText.trim() || !selectedId) return;
    try {
      const res = await axios.post(
        `${API}/messages/conversations/${selectedId}/messages`,
        { content: messageText, sender_name: user?.full_name || "Enseignant" },
        { headers: { Authorization: `Bearer ${getToken()}` } }
      );
      setMessages((prev) => [...prev, res.data]);
      setMessageText("");
    } catch {}
  };

  const handleCreate = async () => {
    if (!newTitle.trim()) return;
    try {
      const res = await axios.post(
        `${API}/messages/conversations`,
        { title: newTitle, type: "Groupe" },
        { headers: { Authorization: `Bearer ${getToken()}` } }
      );
      setConversations((prev) => [res.data, ...prev]);
      setSelectedId(res.data.id);
      setNewTitle("");
      setShowCreateModal(false);
    } catch {}
  };

  const handleStartPrivateChat = async (studentUserId: number) => {
    try {
      const res = await axios.post(
        `${API}/messages/conversations/private`,
        { targetUserId: studentUserId },
        { headers: { Authorization: `Bearer ${getToken()}` } }
      );
      const exists = conversations.find((c) => c.id === res.data.id);
      if (!exists) setConversations((prev) => [res.data, ...prev]);
      setSelectedId(res.data.id);
      setActiveTab("private");
      setShowStudentsModal(false);
    } catch {}
  };

  const handleDelete = async (id: number) => {
    try {
      await axios.delete(`${API}/messages/conversations/${id}`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      const updated = conversations.filter((c) => c.id !== id);
      setConversations(updated);
      setSelectedId(updated.length > 0 ? updated[0].id : null);
    } catch {}
  };

  const groupConversations = conversations.filter((c) => c.type_detail === "group");
  const privateConversations = conversations.filter((c) => c.type_detail === "private");
  const selectedConv = conversations.find((c) => c.id === selectedId);

  const tabClass = (tab: "group" | "private") =>
    `flex-1 py-2 text-sm font-medium rounded-xl transition ${
      activeTab === tab ? "bg-blue-500 text-white" : "text-slate-500 hover:text-slate-800"
    }`;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Messagerie</h1>
          <p className="mt-1 text-slate-500">Communiquez avec vos étudiants</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setShowStudentsModal(true)}
            className="flex items-center gap-2 rounded-xl border border-indigo-200 bg-indigo-50 px-4 py-2 text-sm text-indigo-700 hover:bg-indigo-100"
          >
            <Lock size={16} /> Message privé
          </button>
          <button
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 rounded-xl bg-blue-500 px-4 py-2 text-sm text-white hover:bg-blue-600"
          >
            <Plus size={16} /> Nouveau groupe
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* القائمة الجانبية */}
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
                groupConversations.map((c) => (
                  <button
                    key={c.id}
                    onClick={() => setSelectedId(c.id)}
                    className={`w-full rounded-xl border p-3 text-left transition ${
                      selectedId === c.id ? "border-blue-200 bg-blue-50" : "border-slate-100 hover:bg-slate-50"
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="rounded-lg bg-blue-100 p-1.5">
                          <Users size={14} className="text-blue-600" />
                        </div>
                        <span className="font-medium text-slate-800 text-sm">{c.title}</span>
                      </div>
                      <button
                        onClick={(e) => { e.stopPropagation(); handleDelete(c.id); }}
                        className="rounded p-1 hover:bg-red-50"
                      >
                        <Trash2 size={14} className="text-red-400" />
                      </button>
                    </div>
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
                privateConversations.map((c) => (
                  <button
                    key={c.id}
                    onClick={() => setSelectedId(c.id)}
                    className={`w-full rounded-xl border p-3 text-left transition ${
                      selectedId === c.id ? "border-indigo-200 bg-indigo-50" : "border-slate-100 hover:bg-slate-50"
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <div className="rounded-lg bg-indigo-100 p-1.5">
                        <Lock size={14} className="text-indigo-600" />
                      </div>
                      <span className="font-medium text-slate-800 text-sm">{c.title}</span>
                    </div>
                  </button>
                ))
              )}
            </div>
          )}
        </div>

        {/* منطقة المحادثة */}
        <div className="rounded-2xl bg-white p-6 shadow-sm lg:col-span-2">
          {selectedConv ? (
            <>
              <div className="mb-4 flex items-center gap-3 border-b pb-4">
                <div className={`rounded-xl p-2 ${selectedConv.type_detail === "group" ? "bg-blue-100" : "bg-indigo-100"}`}>
                  {selectedConv.type_detail === "group"
                    ? <Users size={18} className="text-blue-600" />
                    : <Lock size={18} className="text-indigo-600" />
                  }
                </div>
                <div>
                  <h2 className="text-lg font-semibold text-slate-900">{selectedConv.title}</h2>
                  <p className="text-xs text-slate-400">
                    {selectedConv.type_detail === "group" ? "Conversation de groupe" : "Message privé"}
                  </p>
                </div>
              </div>

              <div className="mb-4 min-h-[300px] max-h-[400px] overflow-y-auto rounded-xl border border-slate-100 bg-slate-50 p-4">
                {messages.length > 0 ? (
                  <div className="space-y-3">
                    {messages.map((m) => {
                      const isMe = m.sender_name === user?.full_name;
                      return (
                        <div key={m.id} className={`flex ${isMe ? "justify-end" : "justify-start"}`}>
                          <div className={`max-w-[70%] rounded-2xl px-4 py-3 ${
                            isMe ? "bg-blue-500 text-white rounded-br-sm" : "bg-white shadow-sm rounded-bl-sm"
                          }`}>
                            {!isMe && (
                              <p className="text-xs font-semibold text-slate-500 mb-1">{m.sender_name}</p>
                            )}
                            <p className={`text-sm ${isMe ? "text-white" : "text-slate-800"}`}>{m.content}</p>
                            <p className={`text-xs mt-1 ${isMe ? "text-blue-200" : "text-slate-400"}`}>
                              {new Date(m.created_at).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}
                            </p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div className="flex h-full items-center justify-center text-slate-400 text-sm">
                    Aucun message — commencez la conversation !
                  </div>
                )}
              </div>

              <div className="flex gap-3">
                <input
                  type="text"
                  value={messageText}
                  onChange={(e) => setMessageText(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && handleSend()}
                  placeholder="Tapez votre message..."
                  className="flex-1 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-blue-400 focus:bg-white"
                />
                <button onClick={handleSend} className="rounded-xl bg-blue-500 p-3 text-white hover:bg-blue-600">
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
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold">Nouvelle conversation de groupe</h2>
              <button onClick={() => setShowCreateModal(false)}><X size={20} /></button>
            </div>
            <input
              type="text"
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              placeholder="Titre de la conversation..."
              className="w-full rounded-xl border border-slate-200 p-3 text-sm outline-none focus:border-blue-400 mb-4"
            />
            <div className="flex gap-3">
              <button
                onClick={() => setShowCreateModal(false)}
                className="flex-1 rounded-xl border border-slate-200 py-2 text-sm text-slate-600 hover:bg-slate-50"
              >
                Annuler
              </button>
              <button
                onClick={handleCreate}
                className="flex-1 rounded-xl bg-blue-500 py-2 text-sm font-medium text-white hover:bg-blue-600"
              >
                Créer
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal اختيار الطالب */}
      {showStudentsModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-slate-800">Choisir un étudiant</h2>
              <button onClick={() => setShowStudentsModal(false)}><X size={20} /></button>
            </div>
            <div className="space-y-2 max-h-64 overflow-y-auto">
              {students.length === 0 ? (
                <p className="text-sm text-slate-400 text-center py-4">Aucun étudiant disponible.</p>
              ) : (
                students.map((s) => (
                  <button
                    key={s.user_id}
                    onClick={() => handleStartPrivateChat(s.user_id)}
                    className="w-full rounded-xl border border-slate-100 p-3 text-left hover:bg-slate-50 transition"
                  >
                    <div className="flex items-center gap-3">
                      <div className="rounded-full bg-indigo-100 p-2">
                        <Users size={14} className="text-indigo-600" />
                      </div>
                      <span className="font-medium text-slate-800 text-sm">{s.full_name}</span>
                    </div>
                  </button>
                ))
              )}
            </div>
            <button
              onClick={() => setShowStudentsModal(false)}
              className="mt-4 w-full rounded-xl border border-slate-200 py-2 text-sm text-slate-600 hover:bg-slate-50"
            >
              Annuler
            </button>
          </div>
        </div>
      )}
    </div>
  );
}