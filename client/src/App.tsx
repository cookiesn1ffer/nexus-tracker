import { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ThemeProvider } from './context/ThemeContext';
import ErrorBoundary from './components/ErrorBoundary';
import Login from './views/Login';
import Layout from './components/Layout';
import Dashboard from './views/Dashboard';
import RulesManager from './views/RulesManager';
import WriteupsBoard from './views/WriteupsBoard';
import Analytics from './views/Analytics';
import AdminDashboard from './views/AdminDashboard';

function AppContent() {
  const { user, loading } = useAuth();
  const [activeTab, setActiveTab] = useState('dashboard');

  if (loading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <div className="w-10 h-10 border-4 border-white/30 border-t-white rounded-full animate-spin" />
          <span className="text-xs text-gray-500 font-medium tracking-wider uppercase animate-pulse">Initializing...</span>
        </div>
      </div>
    );
  }

  if (!user) {
    return <Login />;
  }

  return (
    <Layout activeTab={activeTab} setActiveTab={setActiveTab}>
      {activeTab === 'dashboard' && <Dashboard />}
      {activeTab === 'rules' && <RulesManager />}
      {activeTab === 'writeups' && <WriteupsBoard />}
      {activeTab === 'analytics' && <Analytics />}
      {activeTab === 'admin' && <AdminDashboard />}
    </Layout>
  );
}

export default function App() {
  return (
    <ErrorBoundary>
      <AuthProvider>
        <ThemeProvider>
          <AppContent />
        </ThemeProvider>
      </AuthProvider>
    </ErrorBoundary>
  );
}
