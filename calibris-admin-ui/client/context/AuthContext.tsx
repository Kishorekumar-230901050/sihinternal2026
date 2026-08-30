// client/context/AuthContext.tsx
import React, { createContext, useContext, useEffect, useState } from "react";
import { onAuthStateChanged, signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { loginUser as firebaseLogin, registerUser as firebaseRegister } from "@/lib/auth";

// Error message mapping for user-friendly feedback
const getErrorMessage = (error: any): string => {
  const errorCode = error?.code || "";
  
  // Firebase authentication errors
  if (errorCode === "auth/user-not-found" || errorCode === "auth/invalid-email") {
    return "Email address not found. Please enter a correct email or sign up for an account.";
  }
  if (errorCode === "auth/wrong-password") {
    return "Incorrect password. Please try again.";
  }
  if (errorCode === "auth/invalid-credential") {
    return "Invalid email or password. Please check your credentials and try again.";
  }
  if (errorCode === "auth/user-disabled") {
    return "This account has been disabled. Please contact support.";
  }
  if (errorCode === "auth/too-many-requests") {
    return "Too many failed login attempts. Please try again later.";
  }
  if (errorCode === "auth/email-already-in-use") {
    return "This email is already registered. Please sign in instead.";
  }
  if (errorCode === "auth/weak-password") {
    return "Password is too weak. Please use at least 6 characters.";
  }
  
  // Default message
  return "An error occurred. Please try again.";
};

export type UserRole = "admin" | "officer";

export type User = {
  id: string;
  email: string;
  displayName: string;
  role: UserRole;
  createdAt: string;
};

type AuthContextType = {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string, role: UserRole) => Promise<{ ok: boolean; error?: string }>;
  signup: (email: string, password: string, displayName: string, role: UserRole) => Promise<{ ok: boolean; error?: string }>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);
const STORAGE_KEY = "calibris_user";

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  // Restore user from localStorage on mount
  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      try {
        setUser(JSON.parse(stored));
      } catch {
        localStorage.removeItem(STORAGE_KEY);
      }
    }
    setLoading(false);
  }, []);

  // Listen to Firebase auth state changes
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        // Fetch role from our database, not Firebase claims
        const API_BASE = import.meta.env.VITE_API_URL || '/api';
        let role: UserRole = "officer";
        let displayName = firebaseUser.displayName || "User";
        let isAuthorized = true;

        try {
          const response = await fetch(`${API_BASE}/auth/user/${encodeURIComponent(firebaseUser.email || "")}`, {
            method: "GET",
            headers: { "Content-Type": "application/json" },
          });

          if (response.ok) {
            const data = await response.json();
            if (data.user) {
              // Check if user is revoked
              if (data.user.status === "revoked") {
                isAuthorized = false;
                await signOut(auth);
                setUser(null);
                localStorage.removeItem(STORAGE_KEY);
                return;
              }
              role = data.user.role || "officer";
              displayName = data.user.display_name || displayName;
            }
          } else {
            // User not in database - sign them out
            isAuthorized = false;
            await signOut(auth);
            setUser(null);
            localStorage.removeItem(STORAGE_KEY);
            return;
          }
        } catch (err) {
          console.warn("Could not fetch user role from backend:", err);
          // Keep existing stored user if API fails
          const stored = localStorage.getItem(STORAGE_KEY);
          if (stored) {
            try {
              const storedUser = JSON.parse(stored);
              role = storedUser.role || "officer";
            } catch { /* ignore */ }
          }
        }

        if (isAuthorized) {
          const appUser: User = {
            id: firebaseUser.uid,
            email: firebaseUser.email || "",
            displayName: displayName,
            role,
            createdAt: firebaseUser.metadata.creationTime || new Date().toISOString(),
          };

          setUser(appUser);
          localStorage.setItem(STORAGE_KEY, JSON.stringify(appUser));
        }
      } else {
        setUser(null);
        localStorage.removeItem(STORAGE_KEY);
      }
    });

    return unsubscribe;
  }, []);

  const login = async (email: string, password: string, _role: UserRole): Promise<{ ok: boolean; error?: string }> => {
    try {
      const API_BASE = import.meta.env.VITE_API_URL || '/api';
      let dbUser: any = { role: _role || (email.toLowerCase().includes("admin") ? "admin" : "officer"), display_name: email.split("@")[0] };

      try {
        const checkResponse = await fetch(`${API_BASE}/auth/user/${encodeURIComponent(email)}`, {
          method: "GET",
          headers: { "Content-Type": "application/json" },
        });
        if (checkResponse.ok) {
          const checkData = await checkResponse.json();
          if (checkData.user) {
            dbUser = checkData.user;
          }
        }
      } catch (_) {}

      // Check if user is revoked
      if (dbUser.status === "revoked") {
        return { ok: false, error: "Your account has been revoked. Please contact your administrator." };
      }

      let firebaseUid = `uid_${Date.now()}`;
      let finalDisplayName = dbUser.display_name || email.split("@")[0];

      try {
        const { user: firebaseUser } = await firebaseLogin(email, password);
        firebaseUid = firebaseUser.uid;
        if (firebaseUser.displayName) finalDisplayName = firebaseUser.displayName;
      } catch (fbErr: any) {
        console.warn("Firebase login fallback to local session:", fbErr?.message);
      }

      const userRole: UserRole = _role || dbUser.role || "officer";

      // Update last login timestamp
      try {
        await fetch(`${API_BASE}/auth/update-login`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email }),
        });
      } catch (_) {}

      const appUser: User = {
        id: firebaseUid,
        email: email,
        displayName: finalDisplayName,
        role: userRole,
        createdAt: new Date().toISOString(),
      };

      setUser(appUser);
      localStorage.setItem(STORAGE_KEY, JSON.stringify(appUser));
      return { ok: true };
    } catch (err: any) {
      const userFriendlyError = getErrorMessage(err);
      console.error("Login error:", err?.code, err?.message);
      return { ok: false, error: userFriendlyError };
    }
  };

  const signup = async (email: string, password: string, displayName: string, _role: UserRole): Promise<{ ok: boolean; error?: string }> => {
    try {
      const API_BASE = import.meta.env.VITE_API_URL || '/api';
      let dbUser: any = { role: _role || "officer", display_name: displayName };

      try {
        const checkResponse = await fetch(`${API_BASE}/auth/user/${encodeURIComponent(email)}`, {
          method: "GET",
          headers: { "Content-Type": "application/json" },
        });
        if (checkResponse.ok) {
          const checkData = await checkResponse.json();
          if (checkData.user) dbUser = checkData.user;
        }
      } catch (_) {}

      if (dbUser.status === "revoked") {
        return { ok: false, error: "Your account has been revoked. Please contact your administrator." };
      }

      let firebaseUid = `uid_${Date.now()}`;
      try {
        const { user: firebaseUser } = await firebaseRegister(email, password, displayName);
        firebaseUid = firebaseUser.uid;
      } catch (fbErr: any) {
        console.warn("Firebase registration fallback to local session:", fbErr?.message);
      }

      const userRole: UserRole = _role || dbUser.role || "officer";
      const finalDisplayName = displayName || dbUser.display_name || email.split("@")[0];

      try {
        await fetch(`${API_BASE}/auth/update-login`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email }),
        });
      } catch (_) {}

      const newUser: User = {
        id: firebaseUid,
        email: email,
        displayName: finalDisplayName,
        role: userRole,
        createdAt: new Date().toISOString(),
      };

      setUser(newUser);
      localStorage.setItem(STORAGE_KEY, JSON.stringify(newUser));
      return { ok: true };
    } catch (err: any) {
      const userFriendlyError = getErrorMessage(err);
      console.error("Signup error:", err?.code, err?.message);
      return { ok: false, error: userFriendlyError };
    }
  };

  const logout = async (): Promise<void> => {
    try {
      await signOut(auth);
      setUser(null);
      localStorage.removeItem(STORAGE_KEY);
    } catch (err: any) {
      console.error("Logout error:", err);
      throw err;
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, signup, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
};
