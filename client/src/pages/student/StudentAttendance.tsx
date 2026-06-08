import { useEffect, useState } from "react";
import axios from "axios";
import { getToken } from "../../services/auth";
import { CheckCircle, XCircle } from "lucide-react";

const API = "http://localhost:5000/api";

export default function StudentAttendance() {
  const [attendance, setAttendance] = useState<any[]>([]);

  useEffect(() => {
    axios.get(`${API}/student/attendance`, {
      headers: { Authorization: `Bearer ${getToken()}` },
    }).then((res) => setAttendance(res.data)).catch(() => {});
  }, []);

  const presentCount = attendance.filter((a) => a.status === "present").length;
  const absentCount = attendance.filter((a) => a.status === "absent").length;
  const rate = attendance.length > 0 ? Math.round((presentCount / attendance.length) * 100) : 0;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Mes Présences</h1>
        <p className="mt-1 text-slate-500">Votre historique de présence</p>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <div className="rounded-2xl bg-green-50 p-5 text-center">
          <p className="text-3xl font-bold text-green-600">{presentCount}</p>
          <p className="text-sm text-green-700 mt-1">Présences</p>
        </div>
        <div className="rounded-2xl bg-red-50 p-5 text-center">
          <p className="text-3xl font-bold text-red-600">{absentCount}</p>
          <p className="text-sm text-red-700 mt-1">Absences</p>
        </div>
        <div className="rounded-2xl bg-blue-50 p-5 text-center">
          <p className="text-3xl font-bold text-blue-600">{rate}%</p>
          <p className="text-sm text-blue-700 mt-1">Taux</p>
        </div>
      </div>

      <div className="rounded-2xl bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-slate-800 mb-4">Historique</h2>
        {attendance.length === 0 ? (
          <p className="text-center text-slate-400 py-8">Aucune donnée de présence.</p>
        ) : (
          <div className="space-y-2">
            {attendance.map((a, i) => (
              <div key={i} className={`flex items-center justify-between rounded-xl p-4 ${
                a.status === "present" ? "bg-green-50" : "bg-red-50"
              }`}>
                <span className="font-medium text-slate-700">
                  {new Date(a.attendance_date).toLocaleDateString("fr-FR", {
                    weekday: "long", day: "numeric", month: "long", year: "numeric"
                  })}
                </span>
                <div className="flex items-center gap-2">
                  {a.status === "present"
                    ? <><CheckCircle size={18} className="text-green-500" /><span className="text-sm text-green-600">Présent</span></>
                    : <><XCircle size={18} className="text-red-500" /><span className="text-sm text-red-600">Absent</span></>
                  }
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}