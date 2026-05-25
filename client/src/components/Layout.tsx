import React from 'react';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import { Home, ClipboardList, BookOpen, BarChart3, LogOut, CheckCircle, Volume2, VolumeX, ShieldAlert } from 'lucide-react';

interface LayoutProps {
  children: React.ReactNode;
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

export default function Layout({ children, activeTab, setActiveTab }: LayoutProps) {
  const { user, logout } = useAuth();
  const { soundEnabled, setSoundEnabled } = useTheme();

  const navItems = [
    { id: 'dashboard', label: 'Dashboard', icon: Home },
    { id: 'rules', label: 'Ground Rules', icon: ClipboardList },
    { id: 'writeups', label: 'Writeups', icon: BookOpen },
    { id: 'analytics', label: 'Analytics', icon: BarChart3 },
  ];

  if (user?.isAdmin) {
    navItems.push({ id: 'admin', label: 'Admin Panel', icon: ShieldAlert });
  }

  return (
    <div className="min-h-screen flex flex-col md:flex-row bg-dark-bg text-gray-100">
      {/* Sidebar - Desktop */}
      <aside className="hidden md:flex flex-col w-72 bg-black border-r border-white/5 px-4 py-6 justify-between shrink-0">
        <div>
          {/* Logo */}
          <div className="flex items-center gap-3 px-3 mb-8">
            <div className="p-2 rounded-lg bg-white text-black">
              <CheckCircle className="w-5 h-5" />
            </div>
            <div>
              <span className="font-bold tracking-tight text-lg text-white">NEXUS</span>
              <span className="text-xs font-medium ml-1.5 px-1.5 py-0.5 bg-white/5 rounded-md border border-white/10 text-gray-400">TRACKER</span>
            </div>
          </div>

          {/* User profile */}
          <div className="px-3 py-2.5 rounded-xl bg-white/[0.02] border border-white/5 flex items-center justify-between mb-6">
            <div className="flex flex-col">
              <span className="text-[10px] text-gray-500 uppercase tracking-wider">Logged in as</span>
              <span className="text-sm font-medium text-white">@{user?.username}</span>
            </div>
          </div>

          {/* Nav */}
          <nav className="space-y-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => setActiveTab(item.id)}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all cursor-pointer ${
                    isActive
                      ? 'bg-white/5 text-white border border-white/10'
                      : 'text-gray-400 hover:text-white hover:bg-white/5'
                  }`}
                >
                  <Icon className="w-[18px] h-[18px]" />
                  {item.label}
                </button>
              );
            })}
          </nav>

          {/* Sound Controls */}
          <div className="mt-8 px-3">
            <button
              onClick={() => setSoundEnabled(!soundEnabled)}
              className="flex items-center gap-2 text-xs text-gray-500 hover:text-white transition-colors cursor-pointer"
            >
              {soundEnabled ? <Volume2 className="w-3.5 h-3.5" /> : <VolumeX className="w-3.5 h-3.5" />}
              <span>Sound {soundEnabled ? 'On' : 'Off'}</span>
            </button>
          </div>
        </div>

        {/* Logout */}
        <button
          onClick={logout}
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-gray-400 hover:text-white hover:bg-white/5 transition-all cursor-pointer"
        >
          <LogOut className="w-[18px] h-[18px]" />
          Logout
        </button>
      </aside>

      {/* Mobile Header */}
      <header className="md:hidden bg-black border-b border-white/5 px-4 py-3.5 flex items-center justify-between sticky top-0 z-50">
        <div className="flex items-center gap-2">
          <CheckCircle className="w-5 h-5 text-white" />
          <span className="font-bold tracking-tight text-white">NEXUS</span>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => setSoundEnabled(!soundEnabled)}
            className="p-1.5 text-gray-400 hover:text-white"
          >
            {soundEnabled ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
          </button>
          <span className="text-xs text-gray-400 bg-white/5 px-2 py-1 rounded border border-white/10">@{user?.username}</span>
          <button onClick={logout} className="p-1.5 text-gray-400 hover:text-white hover:bg-white/5 rounded-lg">
            <LogOut className="w-[18px] h-[18px]" />
          </button>
        </div>
      </header>

      {/* Content */}
      <main className="flex-1 overflow-y-auto px-4 md:px-8 py-6 md:py-8 pb-28 md:pb-8 max-w-7xl mx-auto w-full">
        {children}
      </main>

      {/* Mobile Bottom Nav */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-black/95 border-t border-white/5 py-2 px-4 flex justify-around items-center z-50 backdrop-blur-lg">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`flex flex-col items-center gap-0.5 py-1 text-[10px] font-medium transition-all ${isActive ? 'text-white scale-105' : 'text-gray-500'}`}
            >
              <Icon className="w-5 h-5" />
              {item.label}
            </button>
          );
        })}
      </nav>
    </div>
  );
}
