import React, { createContext, useContext, useState, useEffect } from 'react';
import { api } from '../api';

interface User {
  id: number;
  username: string;
  isAdmin?: boolean | number;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (username: string, password: string) => Promise<void>;
  register: (username: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadUser() {
      const token = localStorage.getItem('nexus_token');
      if (token) {
        try {
          const userData = await api.get('/api/auth/me');
          setUser(userData);
        } catch (err) {
          console.error("Failed to fetch user profiles", err);
          logout();
        }
      }
      setLoading(false);
    }
    loadUser();
  }, []);

  const login = async (username: string, password: string) => {
    const res = await api.post('/api/auth/login', { username, password });
    localStorage.setItem('nexus_token', res.token);
    setUser(res.user);
  };

  const register = async (username: string, password: string) => {
    const res = await api.post('/api/auth/register', { username, password });
    localStorage.setItem('nexus_token', res.token);
    setUser(res.user);
  };

  const logout = () => {
    localStorage.removeItem('nexus_token');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used inside AuthProvider');
  return context;
}
