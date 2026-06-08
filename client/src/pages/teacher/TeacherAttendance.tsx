import { useEffect, useState } from "react";
import axios from "axios";
import { getToken } from "../../services/auth";
import { Save, CheckCircle, XCircle } from "lucide-react";

const API = "http://localhost:5000/api";

interface Group { id: number; name: string; }
interface Student { id: number; full_name: string; }

export default function TeacherAttendance() {
  const [groups, setGroups] = useState<Group[]>([]);
  const [selectedGroup, setSelectedGroup] = useState<string>("");
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split("T")[0]);
  const [students, setStudents] = useState<Student[]>([]);
  const [attendance, setAttendance] = useState<Record<number, "present" | "absent">>({});
  const [activeTab, setActiveTab] = useState<"prise" | "historique">("prise");
  const [history, setHistory] = useState<any[]>([]);
  const [success, setSuccess] = useState("");

  useEffect(() => {
    axios.get(`${API}/teacher/groups`, {
      headers: { Authorization: `Bearer ${getToken()}` },
    }).then((res) => {
      setGroups(res.data);
      if (res.data.length > 0) setSelectedGroup(String(res.data[0].id));
    });
  }, []);

  useEffect(() => {
    if (selectedGroup) {
      fetchStudents();
      fetchHistory();
    }
  }, [selectedGroup]);

  useEffect(() => {
    if (selectedGroup && selectedDate) fetchExisting();
  }, [selectedGroup, selectedDate]);

  const fetchStudents = async () => {
    try {
      const res = await axios.get(`${API}/attendance/students/${selectedGroup}`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      setStudents(res.data);
      const init: Record<number, "present" | "absent"> = {};
      res.data.forEach((s: Student) => { init[s.id] = "present"; });
      setAttendance(init);
    } catch {}
  };

  const fetchExisting = async () => {
    try {
      const res = await axios.get(`${API}/attendance`, {
        params: { group_id: selectedGroup, date: selectedDate },
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      if (res.data.length > 0) {
        const ex: Record<number, "present" | "absent"> = {};
        res.data.forEach((r: any) => { ex[r.student_id] = r.status; });
        setAttendance(ex);
      }
    } catch {}
  };

  const fetchHistory = async () => {
    try {
      const res = await axios.get(`${API}/attendance/history/${selectedGroup}`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      setHistory(res.data);
    } catch {}
  };

  const handleSave = async () => {
    try {
      const arr = Object.entries(attendance).map(([id, status]) => ({
        student_id: Number(id), status,
      }));
      await axios.post(`${API}/attendance`, {
        group_id: selectedGroup, date: selectedDate, attendance: arr,
      }, { headers: { Authorization: `Bearer ${getToken()}` } });
      setSuccess("Présence enregistrée ✓");
      fetchHistory();
      setTimeout(() => setSuccess(""), 3000);
    } catch {}
  };

  const tabClass = (tab: string) =>
    `px-6 py-3 text-sm font-medium rounded-xl transition ${
      activeTab === tab ? "bg-white text-slate-900 shadow-sm" : "text-slate-500 hover:text-slate-800"
    }`;

  const presentCount = Object.values(attendance).filter(s => s === "present").length;
  const absentCount = Object.values(attendance).filter(s => s === "absent").length;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Présences</h1>
        <p className="mt-1 text-slate-500">Gérez les présences de vos étudiants</p>
      </div>

      <div className="flex rounded-2xl bg-slate-100 p-1 w-fit">
        <button onClick={() => setActiveTab("prise")} className={tabClass("prise")}>
          Prise de présence
        </button>
        <button onClick={() => setActiveTab("historique")} className={tabClass("historique")}>
          Historique
        </button>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <div className="rounded-2xl bg-white p-5 shadow-sm">
          <label className="mb-2 block text-sm font-medium text-slate-700">Groupe</label>
          <select
            value={selectedGroup}
            onChange={(e) => setSelectedGroup(e.target.value)}
            className="w-full rounded-xl border border-slate-300 p-3 outline-none focus:border-blue-500"
          >
            {groups.map((g) => <option key={g.id} value={g.id}>{g.name}</option>)}
          </select>
        </div>
        <div className="rounded-2xl bg-white p-5 shadow-sm">
          <label className="mb-2 block text-sm font-medium text-slate-700">Date</label>
          <input
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            className="w-full rounded-xl border border-slate-300 p-3 outline-none focus:border-blue-500"
          />
        </div>
      </div>

      {activeTab === "prise" && (
        <>
          {success && (
            <div className="rounded-xl bg-green-50 border border-green-200 px-4 py-3 text-green-700 text-sm">
              {success}
            </div>
          )}

          {students.length > 0 && (
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
          )}

          <div className="rounded-2xl bg-white p-6 shadow-sm">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-slate-800">
                Étudiants ({students.length})
              </h2>
              {students.length > 0 && (
                <button
                  onClick={handleSave}
                  className="flex items-center gap-2 rounded-xl bg-blue-500 px-5 py-2.5 text-white hover:bg-blue-600"
                >
                  <Save size={16} /> Enregistrer
                </button>
              )}
            </div>

            {students.length === 0 ? (
              <p className="text-center text-slate-400 py-8">
                Aucun étudiant dans ce groupe.
              </p>
            ) : (
              <div className="space-y-3">
                {students.map((s) => {
                  const isPresent = (attendance[s.id] || "present") === "present";
                  return (
                    <div
                      key={s.id}
                      onClick={() => setAttendance((prev) => ({
                        ...prev,
                        [s.id]: prev[s.id] === "present" ? "absent" : "present",
                      }))}
                      className={`flex cursor-pointer items-center justify-between rounded-xl border p-4 transition ${
                        isPresent ? "border-green-200 bg-green-50" : "border-red-200 bg-red-50"
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <div className={`flex h-10 w-10 items-center justify-center rounded-full text-white font-bold ${
                          isPresent ? "bg-green-500" : "bg-red-500"
                        }`}>
                          {s.full_name.charAt(0).toUpperCase()}
                        </div>
                        <span className="font-medium text-slate-800">{s.full_name}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        {isPresent ? (
                          <><CheckCircle size={20} className="text-green-500" /><span className="text-sm text-green-600">Présent</span></>
                        ) : (
                          <><XCircle size={20} className="text-red-500" /><span className="text-sm text-red-600">Absent</span></>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </>
      )}

      {activeTab === "historique" && (
        <div className="rounded-2xl bg-white p-6 shadow-sm">
          <h2 className="mb-6 text-lg font-semibold text-slate-800">Historique</h2>
          {history.length === 0 ? (
            <p className="text-center text-slate-400 py-8">Aucun historique.</p>
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
                    <tr key={i} className="h-14">
                      <td className="font-medium text-slate-800">
                        {new Date(h.attendance_date).toLocaleDateString("fr-FR", {
                          day: "numeric", month: "long", year: "numeric"
                        })}
                      </td>
                      <td>{h.total}</td>
                      <td><span className="rounded-full bg-green-100 px-3 py-1 text-xs text-green-700">{h.present_count}</span></td>
                      <td><span className="rounded-full bg-red-100 px-3 py-1 text-xs text-red-700">{h.absent_count}</span></td>
                      <td>
                        <div className="flex items-center gap-2">
                          <div className="h-2 w-20 rounded-full bg-slate-200">
                            <div className="h-2 rounded-full bg-green-500" style={{ width: `${rate}%` }} />
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