import { useState, useEffect } from 'react';
import { api } from '../api';
import { useAuth } from '../context/AuthContext';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import { Medal, Calendar, CheckSquare, Trophy, Crown } from 'lucide-react';

interface UserStat {
  userId: number;
  completedCount: number;
  currentStreak: number;
  maxStreak: number;
  completedDates: string[];
}

interface LeaderboardEntry {
  username: string;
  total_xp: number;
  level: number;
  rankTitle: string;
}

export default function Analytics() {
  const { user } = useAuth();
  const [userStats, setUserStats] = useState<Record<string, UserStat>>({});
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [myGamification, setMyGamification] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      try {
        const [statsData, leaderboardData, gamificationData] = await Promise.all([
          api.get('/api/stats'),
          api.get('/api/gamification/leaderboard').catch(() => []),
          api.get('/api/gamification/me').catch(() => null),
        ]);
        
        if (!statsData) return;

        setUserStats(statsData.userStats || {});
        setLeaderboard(leaderboardData || []);
        setMyGamification(gamificationData);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, []);

  const chartData = Object.entries(userStats).map(([name, stats]) => ({
    name: `@${name}`,
    Completions: stats.completedCount
  }));

  const getHeatmapDays = () => {
    const arr = [];
    const today = new Date();
    for (let i = 59; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(today.getDate() - i);
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      arr.push(`${year}-${month}-${day}`);
    }
    return arr;
  };

  const heatmapDays = getHeatmapDays();

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Performance Stats</h2>
        <p className="text-gray-500 text-sm mt-1">Visualize comparative progress and streak analytics.</p>
      </div>

      {loading ? (
        <div className="text-gray-500 text-sm py-12 text-center">Loading stats...</div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            {/* Rank Title Banner */}
            {myGamification && (
              <div className="glass-panel p-6 rounded-2xl border border-white/5 flex items-center gap-4">
                <div className="p-3 rounded-xl bg-white/5 border border-white/10">
                  <Crown className="w-8 h-8 text-white" />
                </div>
                <div>
                  <div className="text-xs text-gray-500 uppercase tracking-wider font-semibold">Current Rank</div>
                  <div className="text-2xl font-bold text-white">{myGamification.rankTitle}</div>
                  <div className="text-xs text-gray-400 mt-0.5">Level {myGamification.level} • {myGamification.totalXP} XP</div>
                </div>
                <div className="ml-auto text-right">
                  <div className="text-xs text-gray-500">Next Level</div>
                  <div className="text-sm font-bold text-white">{myGamification.nextLevelXP} XP</div>
                  <div className="w-24 h-1.5 bg-white/10 rounded-full mt-1 overflow-hidden">
                    <div className="h-full bg-white rounded-full transition-all" style={{ width: `${myGamification.progressToNext}%` }} />
                  </div>
                </div>
              </div>
            )}

            {/* Stats Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {Object.entries(userStats).map(([name, stats]) => {
                const isMe = name === user?.username;
                return (
                  <div key={name} className={`glass-panel p-6 rounded-2xl border flex flex-col justify-between ${isMe ? 'border-white/10' : 'border-white/5'}`}>
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-bold text-white">@{name} {isMe && '(You)'}</span>
                      <Medal className="w-5 h-5 text-gray-400" />
                    </div>
                    <div className="grid grid-cols-3 gap-2 mt-6">
                      <div className="text-center">
                        <span className="text-[9px] uppercase tracking-wider text-gray-500 font-bold block">Checked</span>
                        <span className="text-xl font-bold text-white mt-1 block">{stats.completedCount}</span>
                      </div>
                      <div className="text-center border-x border-white/5">
                        <span className="text-[9px] uppercase tracking-wider text-gray-500 font-bold block">Streak</span>
                        <span className="text-xl font-bold text-white mt-1 block">{stats.currentStreak}d</span>
                      </div>
                      <div className="text-center">
                        <span className="text-[9px] uppercase tracking-wider text-gray-500 font-bold block">Max</span>
                        <span className="text-xl font-bold text-white mt-1 block">{stats.maxStreak}d</span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Heatmap */}
            <div className="glass-panel p-6 rounded-2xl border border-white/5 space-y-6">
              <h3 className="text-sm font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
                <Calendar className="w-4.5 h-4.5 text-gray-400" />
                Consistency Heatmap (Last 60 Days)
              </h3>
              <div className="space-y-6">
                {Object.entries(userStats).map(([name, stats]) => (
                  <div key={name} className="space-y-2">
                    <span className="text-xs font-semibold text-gray-500">@{name}</span>
                    <div className="flex flex-wrap gap-1">
                      {heatmapDays.map((dayStr) => {
                        const isCompleted = stats.completedDates.includes(dayStr);
                        return (
                          <div
                            key={dayStr}
                            title={`${dayStr}: ${isCompleted ? 'Checked Rule(s)' : 'No completions'}`}
                            className={`w-3.5 h-3.5 rounded-sm transition-all duration-300 hover:scale-125 ${isCompleted ? 'bg-white' : 'bg-white/5 border border-white/5'}`}
                          />
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Right Column: Leaderboard + Chart */}
          <div className="space-y-6">
            {/* XP Leaderboard */}
            {leaderboard.length > 0 && (
              <div className="glass-panel p-6 rounded-2xl border border-white/5 space-y-4">
                <h3 className="text-sm font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
                  <Trophy className="w-4.5 h-4.5 text-white" />
                  XP Leaderboard
                </h3>
                <div className="space-y-3">
                  {leaderboard.map((entry, idx) => (
                    <div key={entry.username} className={`flex items-center gap-3 p-3 rounded-lg ${entry.username === user?.username ? 'bg-white/[0.02] border border-white/10' : 'bg-white/[0.01] border border-white/5'}`}>
                      <span className={`text-sm font-bold w-6 text-center ${idx === 0 ? 'text-white' : idx === 1 ? 'text-gray-300' : idx === 2 ? 'text-gray-400' : 'text-gray-600'}`}>
                        {idx === 0 ? '👑' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : `#${idx + 1}`}
                      </span>
                      <div className="flex-1">
                        <div className="text-sm font-bold text-white">@{entry.username}</div>
                        <div className="text-[10px] text-gray-500">{entry.rankTitle} • Level {entry.level}</div>
                      </div>
                      <div className="text-right">
                        <div className="text-sm font-bold text-white">{entry.total_xp} XP</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Chart */}
            <div className="glass-panel p-6 rounded-2xl border border-white/5 flex flex-col justify-between">
              <div>
                <h3 className="text-sm font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
                  <CheckSquare className="w-4.5 h-4.5 text-gray-400" />
                  Total Completions
                </h3>
                <p className="text-xs text-gray-500 mt-1">Comparative rule check count.</p>
              </div>
              <div className="h-48 mt-4">
                {chartData.length === 0 ? (
                  <div className="h-full flex items-center justify-center text-xs text-gray-600">No data yet.</div>
                ) : (
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                      <XAxis dataKey="name" stroke="#525252" fontSize={11} tickLine={false} axisLine={false} />
                      <YAxis stroke="#525252" fontSize={11} tickLine={false} axisLine={false} />
                      <Tooltip contentStyle={{ backgroundColor: '#0a0a0a', border: '1px solid rgba(255,255,255,0.08)', borderRadius: '10px' }} labelStyle={{ color: '#ffffff', fontWeight: 'bold' }} />
                      <Bar dataKey="Completions" radius={[8, 8, 0, 0]}>
                        {chartData.map((_entry, index) => (
                          <Cell key={`cell-${index}`} fill={index === 0 ? '#ffffff' : '#a3a3a3'} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
