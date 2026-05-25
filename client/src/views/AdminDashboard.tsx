import { useState, useEffect } from 'react';
import { api } from '../api';
import { useAuth } from '../context/AuthContext';
import { Shield, Users, Database, Trash2, Key, AlertTriangle } from 'lucide-react';

interface UserAdmin {
  id: number;
  username: string;
  isAdmin: boolean | number;
  created_at: string;
}

export default function AdminDashboard() {
  const { user } = useAuth();
  const [users, setUsers] = useState<UserAdmin[]>([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<any>(null);

  useEffect(() => {
    async function fetchAdminData() {
      try {
        const [usersData, statsData] = await Promise.all([
          api.get('/api/admin/users'),
          api.get('/api/admin/stats')
        ]);
        setUsers(usersData);
        setStats(statsData);
      } catch (err) {
        console.error("Admin fetch error:", err);
      } finally {
        setLoading(false);
      }
    }
    if (user?.isAdmin) {
      fetchAdminData();
    }
  }, [user]);

  const handleDeleteUser = async (userId: number) => {
    if (!window.confirm("Are you sure you want to delete this user? This action is irreversible.")) return;
    try {
      await api.delete(`/api/admin/users/${userId}`);
      setUsers(users.filter(u => u.id !== userId));
    } catch (err) {
      alert("Failed to delete user");
    }
  };

  const handleToggleAdmin = async (userId: number, currentStatus: boolean | number) => {
    try {
      const newStatus = currentStatus ? 0 : 1;
      await api.post(`/api/admin/users/${userId}/toggle-admin`, { isAdmin: newStatus });
      setUsers(users.map(u => u.id === userId ? { ...u, isAdmin: newStatus } : u));
    } catch (err) {
      alert("Failed to toggle admin status");
    }
  };

  if (!user?.isAdmin) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-center">
        <AlertTriangle className="w-16 h-16 text-gray-600 mb-4" />
        <h2 className="text-2xl font-bold text-white">Access Denied</h2>
        <p className="text-gray-500 mt-2">You do not have administrative privileges.</p>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight flex items-center gap-2">
            <Shield className="w-6 h-6 text-white" />
            Nexus Control Center
          </h2>
          <p className="text-gray-500 text-sm mt-1">Global system management and user oversight.</p>
        </div>
      </div>

      {loading ? (
        <div className="py-20 text-center text-gray-600 uppercase tracking-widest text-xs animate-pulse font-bold">
          Loading system diagnostics...
        </div>
      ) : (
        <>
          {/* Global Stats */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="glass-panel p-6 rounded-2xl border border-white/5">
              <div className="flex items-center gap-3 text-gray-500 mb-4">
                <Users className="w-4 h-4" />
                <span className="text-[10px] uppercase font-bold tracking-widest">Total Users</span>
              </div>
              <div className="text-3xl font-bold text-white">{stats?.userCount || 0}</div>
            </div>
            <div className="glass-panel p-6 rounded-2xl border border-white/5">
              <div className="flex items-center gap-3 text-gray-500 mb-4">
                <Database className="w-4 h-4" />
                <span className="text-[10px] uppercase font-bold tracking-widest">Rule Logs</span>
              </div>
              <div className="text-3xl font-bold text-white">{stats?.logCount || 0}</div>
            </div>
            <div className="glass-panel p-6 rounded-2xl border border-white/5">
              <div className="flex items-center gap-3 text-gray-500 mb-4">
                <Key className="w-4 h-4" />
                <span className="text-[10px] uppercase font-bold tracking-widest">Active Rules</span>
              </div>
              <div className="text-3xl font-bold text-white">{stats?.ruleCount || 0}</div>
            </div>
            <div className="glass-panel p-6 rounded-2xl border border-white/5">
              <div className="flex items-center gap-3 text-gray-500 mb-4">
                <Shield className="w-4 h-4" />
                <span className="text-[10px] uppercase font-bold tracking-widest">Admins</span>
              </div>
              <div className="text-3xl font-bold text-white">{stats?.adminCount || 0}</div>
            </div>
          </div>

          {/* User Management */}
          <div className="glass-panel rounded-2xl border border-white/5 overflow-hidden">
            <div className="px-6 py-4 border-b border-white/5 bg-white/[0.02] flex items-center justify-between">
              <h3 className="text-sm font-bold text-gray-400 uppercase tracking-wider">User Directory</h3>
              <span className="text-[10px] font-bold bg-white/[0.02] px-2 py-0.5 rounded border border-white/5 text-gray-600 uppercase">
                {users.length} Registered
              </span>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="text-[10px] uppercase tracking-widest text-gray-600 border-b border-white/5">
                    <th className="px-6 py-4 font-bold">Username</th>
                    <th className="px-6 py-4 font-bold">Joined Date</th>
                    <th className="px-6 py-4 font-bold">Role</th>
                    <th className="px-6 py-4 font-bold text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5">
                  {users.map((u) => (
                    <tr key={u.id} className="hover:bg-white/[0.02] transition-colors group">
                      <td className="px-6 py-4">
                        <span className="font-bold text-white">@{u.username}</span>
                      </td>
                      <td className="px-6 py-4 text-xs text-gray-500">
                        {new Date(u.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4">
                        {u.isAdmin ? (
                          <span className="text-[10px] font-bold text-white bg-white/5 border border-white/10 px-2 py-0.5 rounded">ADMIN</span>
                        ) : (
                          <span className="text-[10px] font-bold text-gray-500 bg-white/[0.02] border border-white/5 px-2 py-0.5 rounded">USER</span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => handleToggleAdmin(u.id, u.isAdmin)}
                            title={u.isAdmin ? "Revoke Admin" : "Grant Admin"}
                            className="p-1.5 rounded-lg bg-white/5 text-gray-500 hover:text-white hover:bg-white/10 transition-all cursor-pointer"
                          >
                            <Shield className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDeleteUser(u.id)}
                            title="Delete User"
                            className="p-1.5 rounded-lg bg-white/5 text-gray-500 hover:text-white hover:bg-white/10 transition-all cursor-pointer"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
