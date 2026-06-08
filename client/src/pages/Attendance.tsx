import React, { useState, useEffect } from "react";
import { Save, Calendar, Users, CheckCircle, XCircle } from "lucide-react";
import axios from "axios";

const API = "http://localhost:5000/api";

interface Group {
  id: number;
  name: string;
}

interface Student {
  id: number;
  full_name: string;
}

interface AttendanceRecord {
  student_id: number;
  status: "present" | "absent";
}

interface HistoryRecord {
  attendance_date: string;
  total: number;
  present_count: number;
  absent_count: number;
}

export default function Attendance() {
  const [groups, setGroups] = useState<Group[]>([]);
  const [selectedGroup, setSelectedGroup] = useState<string>("");
  const [selectedDate, setSelectedDate] = useState<string>(
    new Date().toISOString().split("T")[0]
  );
  const [students, setStudents] = useState<Student[]>([]);
  const [attendance, setAttendance] = useState<Record<number, "present" | "absent">>({});
  const [history, setHistory] = useState<HistoryRecord[]>([]);
  const [activeTab, setActiveTab] = useState<"prise" | "historique">("prise");
  const [successMsg, setSuccessMsg] = useState("");
  const [loading, setLoading] = useState(false);

  // جلب المجموعات
  useEffect(() => {
    axios.get(`${API}/groups`).then((res) => setGroups(res.data));
  }, []);

  // جلب الطلاب عند تغيير المجموعة
  useEffect(() => {
    if (!selectedGroup) return;
    fetchStudents();
    fetchHistory();
  }, [selectedGroup]);

  // جلب الحضور الموجود عند تغيير المجموعة أو التاريخ
  useEffect(() => {
    if (!selectedGroup || !selectedDate) return;
    fetchExistingAttendance();
  }, [selectedGroup, selectedDate]);

  const fetchStudents = async () => {
    try {
      const res = await axios.get(`${API}/attendance/students/${selectedGroup}`);
      setStudents(res.data);
      // تهيئة كل الطلاب بـ present افتراضياً
      const initial: Record<number, "present" | "absent"> = {};
      res.data.forEach((s: Student) => {
        initial[s.id] = "present";
      });
      setAttendance(initial);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchExistingAttendance = async () => {
    try {
      const res = await axios.get(`${API}/attendance`, {
        params: { group_id: selectedGroup, date: selectedDate },
      });
      if (res.data.length > 0) {
        const existing: Record<number, "present" | "absent"> = {};
        res.data.forEach((r: any) => {
          existing[r.student_id] = r.status;
        });
        setAttendance(existing);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const fetchHistory = async () => {
    try {
      const res = await axios.get(`${API}/attendance/history/${selectedGroup}`);
      setHistory(res.data);
    } catch (err) {
      console.error(err);
    }
  };

  const toggleStatus = (studentId: number) => {
    setAttendance((prev) => ({
      ...prev,
      [studentId]: prev[studentId] === "present" ? "absent" : "present",
    }));
  };

  const handleSave = async () => {
    if (!selectedGroup || !selectedDate) return;
    setLoading(true);
    try {
      const attendanceArray = Object.entries(attendance).map(([student_id, status]) => ({
        student_id: Number(student_id),
        status,
      }));

      await axios.post(`${API}/attendance`, {
        group_id: selectedGroup,
        date: selectedDate,
        attendance: attendanceArray,
      });

      setSuccessMsg("Présence enregistrée avec succès ✓");
      fetchHistory();
      setTimeout(() => setSuccessMsg(""), 3000);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const presentCount = Object.values(attendance).filter((s) => s === "present").length;
  const absentCount = Object.values(attendance).filter((s) => s === "absent").length;

  const tabClass = (tab: "prise" | "historique") =>
    `px-6 py-3 text-sm font-medium rounded-xl transition ${
      activeTab === tab
        ? "bg-white text-slate-900 shadow-sm"
        : "text-slate-500 hover:text-slate-800"
    }`;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Présences</h1>
        <p className="mt-1 text-slate-500">Gérez les présences des étudiants</p>
      </div>

      {/* Tabs */}
      <div className="flex rounded-2xl bg-slate-100 p-1 w-fit">
        <button onClick={() => setActiveTab("prise")} className={tabClass("prise")}>
          Prise de présence
        </button>
        <button onClick={() => setActiveTab("historique")} className={tabClass("historique")}>
          Historique
        </button>
      </div>

      {/* Sélection groupe + date */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <div className="rounded-2xl bg-white p-5 shadow-sm">
          <label className="mb-2 flex items-center gap-2 text-sm font-medium text-slate-700">
            <Users size={16} />
            Sélectionner un groupe
          </label>
          <select
            value={selectedGroup}
            onChange={(e) => setSelectedGroup(e.target.value)}
            className="w-full rounded-xl border border-slate-300 p-3 outline-none focus:border-blue-500"
          >
            <option value="">-- Choisir un groupe --</option>
            {groups.map((g) => (
              <option key={g.id} value={g.id}>
                {g.name}
              </option>
            ))}
          </select>
        </div>

        <div className="rounded-2xl bg-white p-5 shadow-sm">
          <label className="mb-2 flex items-center gap-2 text-sm font-medium text-slate-700">
            <Calendar size={16} />
            Date
          </label>
          <input
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            className="w-full rounded-xl border border-slate-300 p-3 outline-none focus:border-blue-500"
          />
        </div>
      </div>

      {/* Tab: Prise de présence */}
      {activeTab === "prise" && (
        <>
          {selectedGroup && students.length > 0 && (
            <>
              {/* Stats */}
              <div className="grid grid-cols-2 gap-4">
                <div className="rounded-2xl bg-green-50 p-4 text-center">
                  <p className="text-3xl font-bold text-green-600">{presentCount}</p>
                  <p className="text-sm text-green-700">Présents</p>
                </div>
                <div className="rounded-2xl bg-red-50 p-4 text-center">
                  <p className="text-3xl font-bold text-red-600">{absentCount}</p>
                  <p className="text-sm text-red-700">Absents</p>
                </div>
              </div>

              {successMsg && (
                <div className="rounded-xl bg-green-50 border border-green-200 px-4 py-3 text-green-700 text-sm">
                  {successMsg}
                </div>
              )}

              {/* Liste des étudiants */}
              <div className="rounded-2xl bg-white p-6 shadow-sm">
                <div className="mb-4 flex items-center justify-between">
                  <h2 className="text-xl font-semibold text-slate-800">
                    Liste des étudiants ({students.length})
                  </h2>
                  <button
                    onClick={handleSave}
                    disabled={loading}
                    className="flex items-center gap-2 rounded-xl bg-blue-500 px-5 py-3 text-white hover:bg-blue-600 disabled:opacity-50"
                  >
                    <Save size={18} />
                    {loading ? "Enregistrement..." : "Enregistrer"}
                  </button>
                </div>

                <div className="space-y-3">
                  {students.map((student) => {
                    const status = attendance[student.id] || "present";
                    const isPresent = status === "present";

                    return (
                      <div
                        key={student.id}
                        className={`flex items-center justify-between rounded-xl border p-4 transition cursor-pointer ${
                          isPresent
                            ? "border-green-200 bg-green-50"
                            : "border-red-200 bg-red-50"
                        }`}
                        onClick={() => toggleStatus(student.id)}
                      >
                        <div className="flex items-center gap-3">
                          <div className={`flex h-10 w-10 items-center justify-center rounded-full text-white font-bold ${
                            isPresent ? "bg-green-500" : "bg-red-500"
                          }`}>
                            {student.full_name.charAt(0).toUpperCase()}
                          </div>
                          <span className="font-medium text-slate-800">
                            {student.full_name}
                          </span>
                        </div>

                        <div className="flex items-center gap-2">
                          {isPresent ? (
                            <>
                              <CheckCircle size={20} className="text-green-500" />
                              <span className="text-sm font-medium text-green-600">Présent</span>
                            </>
                          ) : (
                            <>
                              <XCircle size={20} className="text-red-500" />
                              <span className="text-sm font-medium text-red-600">Absent</span>
                            </>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </>
          )}

          {selectedGroup && students.length === 0 && (
            <div className="rounded-2xl bg-white p-10 text-center text-slate-400 shadow-sm">
              Aucun étudiant dans ce groupe.
            </div>
          )}

          {!selectedGroup && (
            <div className="rounded-2xl bg-white p-10 text-center text-slate-400 shadow-sm">
              Veuillez sélectionner un groupe pour commencer.
            </div>
          )}
        </>
      )}

      {/* Tab: Historique */}
      {activeTab === "historique" && (
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <h2 className="mb-6 text-xl font-semibold text-slate-800">
            Historique des présences
          </h2>

          {!selectedGroup ? (
            <p className="text-center text-slate-400 py-8">
              Veuillez sélectionner un groupe.
            </p>
          ) : history.length === 0 ? (
            <p className="text-center text-slate-400 py-8">
              Aucun historique trouvé.
            </p>
          ) : (
            <table className="w-full">
              <thead className="border-b text-left text-sm text-slate-500">
                <tr>
                  <th className="pb-3">Date</th>
                  <th className="pb-3">Total</th>
                  <th className="pb-3">Présents</th>
                  <th className="pb-3">Absents</th>
                  <th className="pb-3">Taux</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {history.map((h, i) => {
                  const rate = Math.round((h.present_count / h.total) * 100);
                  return (
                    <tr key={i} className="h-16">
                      <td className="font-medium text-slate-800">
                        {new Date(h.attendance_date).toLocaleDateString("fr-FR", {
                          day: "numeric", month: "long", year: "numeric",
                        })}
                      </td>
                      <td className="text-slate-600">{h.total}</td>
                      <td>
                        <span className="rounded-full bg-green-100 px-3 py-1 text-xs font-medium text-green-700">
                          {h.present_count}
                        </span>
                      </td>
                      <td>
                        <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-medium text-red-700">
                          {h.absent_count}
                        </span>
                      </td>
                      <td>
                        <div className="flex items-center gap-2">
                          <div className="h-2 w-24 rounded-full bg-slate-200">
                            <div
                              className="h-2 rounded-full bg-green-500"
                              style={{ width: `${rate}%` }}
                            />
                          </div>
                          <span className="text-sm text-slate-600">{rate}%</span>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
}