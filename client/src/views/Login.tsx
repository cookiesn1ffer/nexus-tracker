import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Sparkles, User, Lock, ArrowRight, Zap } from 'lucide-react';

export default function Login() {
  const { login, register } = useAuth();
  const [isLogin, setIsLogin] = useState(true);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      if (isLogin) {
        await login(username, password);
      } else {
        await register(username, password);
      }
    } catch (err: any) {
      setError(err.message || 'Authentication failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-black">
      <div className="w-full max-w-md glass-panel p-8 rounded-2xl relative z-10 border border-white/5">
        <div className="text-center mb-8">
          <div className="inline-flex p-3 rounded-xl bg-white/5 text-white mb-3 border border-white/10">
            <Sparkles className="w-6 h-6" />
          </div>
          <h1 className="text-3xl font-bold tracking-tight text-white">NEXUS TRACKER</h1>
          <p className="text-gray-500 text-sm mt-2">Dual accountability system for remote friends</p>
          
          {/* Feature highlights */}
          <div className="flex justify-center gap-4 mt-4">
            <div className="flex items-center gap-1 text-[10px] text-gray-500">
              <Zap className="w-3 h-3" />
              XP & Levels
            </div>
            <div className="flex items-center gap-1 text-[10px] text-gray-500">
              <Sparkles className="w-3 h-3" />
              Real-time Sync
            </div>
            <div className="flex items-center gap-1 text-[10px] text-gray-500">
              <Lock className="w-3 h-3" />
              Secure Auth
            </div>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {error && (
            <div className="p-3 bg-white/5 border border-white/10 text-gray-300 rounded-lg text-sm">
              {error}
            </div>
          )}

          <div>
            <label htmlFor="username" className="block text-gray-400 text-sm font-medium mb-1.5">Username</label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-500">
                <User className="w-4.5 h-4.5" />
              </span>
              <input id="username" type="text" value={username} onChange={e => setUsername(e.target.value)} className="w-full pl-10 pr-4 py-2.5 rounded-lg glass-input text-sm" placeholder="Enter username" required />
            </div>
          </div>

          <div>
            <label htmlFor="password" className="block text-gray-400 text-sm font-medium mb-1.5">Password</label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-500">
                <Lock className="w-4.5 h-4.5" />
              </span>
              <input id="password" type="password" value={password} onChange={e => setPassword(e.target.value)} className="w-full pl-10 pr-4 py-2.5 rounded-lg glass-input text-sm" placeholder="Enter password" required minLength={6} />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-2 bg-white hover:bg-gray-200 text-black font-medium py-2.5 rounded-lg text-sm transition-all flex items-center justify-center gap-2 group cursor-pointer disabled:opacity-50"
          >
            {loading ? 'Processing...' : isLogin ? 'Sign In' : 'Create Account'}
            <ArrowRight className="w-4.5 h-4.5 group-hover:translate-x-0.5 transition-transform" />
          </button>
        </form>

        <div className="mt-6 text-center">
          <button onClick={() => setIsLogin(!isLogin)} className="text-gray-400 hover:text-white text-xs font-medium focus:outline-none transition-colors">
            {isLogin ? "New pair? Register here" : "Already registered? Login here"}
          </button>
        </div>
      </div>
    </div>
  );
}
