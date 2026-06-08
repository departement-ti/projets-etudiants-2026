import { Navigate } from "react-router-dom";
import { isAuthenticated, getUser } from "../services/auth";

interface Props {
  children: React.ReactNode;
  allowedRoles?: string[];
}

export default function ProtectedRoute({ children, allowedRoles }: Props) {
  if (!isAuthenticated()) {
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles) {
    const user = getUser();
    if (!user || !allowedRoles.includes(user.role)) {
      return <Navigate to="/login" replace />;
    }
  }

  return <>{children}</>;
}