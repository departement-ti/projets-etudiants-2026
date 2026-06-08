import { Link, Outlet, useLocation } from "react-router-dom";
import { useEffect, useState } from "react";
import axios from "axios";

const API = "http://localhost:5000/api";

interface ContactSettings {
  primary_phone: string;
  email: string;
  address: string;
  topbar_logo: string;
  footer_logo: string;
}

interface SocialLink {
  id: number;
  name: string;
  url: string;
  icon: string;
}

export default function PublicLayout() {
  const location = useLocation();
  const [contact, setContact] = useState<ContactSettings | null>(null);
  const [socials, setSocials] = useState<SocialLink[]>([]);

  useEffect(() => {
    axios.get(`${API}/settings/contact`).then((res) => setContact(res.data)).catch(() => {});
    axios.get(`${API}/settings/social`).then((res) => setSocials(res.data)).catch(() => {});
  }, []);

  return (
    <div className="min-h-screen flex flex-col">
      {/* Navbar */}
      <header className="sticky top-0 z-50 bg-white shadow-sm">
        
         
            <div className="mx-auto flex max-w-7x1 items-center justify-between px-7 py-3 h-20">
              
          <Link to="/" className="flex items-center gap-2">
            {contact?.topbar_logo ? (
              <img
                src={contact.topbar_logo}
                alt="EduLive Logo"
               
               
               className="h-16 w-auto max-w-[160px] object-contain"
              />
              
            ) : (
              <>
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-orange-500 text-white font-bold text-lg">E</div>
                <div>
                  <span className="text-xl font-bold text-slate-900">EDULIVE</span>
                  <p className="text-xs text-slate-400 leading-none">CONNECTED EDUCATIONAL COMMUNITY</p>
                </div>
              </>
            )}
          </Link>

          <nav className="hidden md:flex items-center gap-8">
            {[
              { to: "/", label: "Accueil" },
              { to: "/niveaux", label: "Niveaux" },
              { to: "/avis", label: "Avis" },
              { to: "/contact", label: "Contact" },
            ].map((item) => (
              <Link
                key={item.to}
                to={item.to}
                className={`text-sm font-medium transition ${
                  location.pathname === item.to ? "text-orange-500" : "text-slate-700 hover:text-orange-500"
                }`}
              >
                {item.label}
              </Link>
            ))}
          </nav>

          <Link
            to="/login"
            className="rounded-full border-2 border-slate-800 px-6 py-2 text-sm font-semibold text-slate-800 hover:bg-slate-800 hover:text-white transition"
          >
            Connexion
          </Link>
        </div>
      </header>

      {/* Page Content */}
      <main className="flex-1">
        <Outlet />
      </main>

      {/* Footer */}
      <footer className="bg-slate-900 text-white">
        <div className="mx-auto max-w-7xl px-6 py-12">
          <div className="grid grid-cols-1 gap-10 md:grid-cols-3">
            <div>
              {contact?.footer_logo ? (
                <img
                  src={contact.footer_logo}
                  alt="EduLive Footer Logo"
                  className="h-20 w-auto max-w-[180px] object-contain"
                />
              ) : (
                <div className="flex h-16 w-16 items-center justify-center rounded-xl bg-orange-500 text-white font-bold text-2xl">E</div>
              )}
            </div>

            <div>
              <h3 className="mb-4 font-semibold text-white">© Contact</h3>
              <div className="space-y-3 text-slate-400 text-sm">
                {contact?.primary_phone && (
                  <div className="flex items-center gap-2">
                    <span>📱</span>
                    <span>{contact.primary_phone}</span>
                  </div>
                )}
                {contact?.email && (
                  <div className="flex items-center gap-2">
                    <span>✉️</span>
                    <span>{contact.email}</span>
                  </div>
                )}
                {contact?.address && (
                  <div className="flex items-center gap-2">
                    <span>📍</span>
                    <span>{contact.address}</span>
                  </div>
                )}
              </div>
            </div>

            <div>
              <h3 className="mb-4 font-semibold text-white">Rejoignez notre newsletter</h3>
              <div className="flex gap-3">
                {socials.length > 0 ? socials.map((s) => (
                  <a key={s.id} href={s.url} target="_blank" rel="noopener noreferrer"
                    className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-600 text-white hover:opacity-80 text-xs font-bold">
                    {s.name.charAt(0)}
                  </a>
                )) : (
                  <>
                    <a href="#" className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-600 text-white">f</a>
                    <a href="#" className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-purple-500 to-pink-500 text-white text-xs">IG</a>
                  </>
                )}
              </div>
            </div>
          </div>

          <div className="mt-10 border-t border-slate-700 pt-6 text-center text-sm text-slate-500">
            © Platform created by <strong>WOWSOFT</strong>. All rights reserved.
          </div>
        </div>
      </footer>
    </div>
  );
}