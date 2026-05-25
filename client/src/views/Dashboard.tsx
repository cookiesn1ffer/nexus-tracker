import { useState, useEffect, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { api } from '../api';
import { useSocket } from '../hooks/useSocket';
import { soundManager } from '../utils/sound';
import { fireConfetti, fireStreakConfetti } from '../utils/confetti';
import ProgressRing from '../components/ProgressRing';
import { CheckSquare, Square, Flame, History, Notebook, MessageSquare, Zap, Trophy } from 'lucide-react';

interface Rule {
  id: number;
  title: string;
  description: string;
  frequency: 'daily' | 'weekly' | 'one-time';
  difficulty: 'easy' | 'medium' | 'hard';
}

interface Completion {
  id: number;
  rule_id: number;
  user_id: number;
  username: string;
  completed_date: string;
}

interface FeedItem {
  type: 'checklist' | 'writeup';
  id: number;
  user_id: number;
  username: string;
  item_title: string;
  date?: string;
  timestamp: string;
  reactions?: Record<string, string[]>;
}

interface UserStat {
  userId: number;
  completedCount: number;
  currentStreak: number;
  maxStreak: number;
}

interface GamificationData {
  totalXP: number;
  level: number;
  rankTitle: string;
  nextLevelXP: number;
  progressToNext: number;
  achievements: Array<{ id: number; badge_id: string; badge_name: string; badge_icon: string }>;
}

const REACTION_EMOJIS = ['👍', '🔥', '💪', '🎯', '🚀', '⭐'];

export default function Dashboard() {
  const { user } = useAuth();
  const { onActivity } = useSocket();
  const [rules, setRules] = useState<Rule[]>([]);
  const [completions, setCompletions] = useState<Completion[]>([]);
  const [feed, setFeed] = useState<FeedItem[]>([]);
  const [userStats, setUserStats] = useState<Record<string, UserStat>>({});
  const [gamification, setGamification] = useState<GamificationData | null>(null);
  const [loading, setLoading] = useState(true);
  const [prevStreak, setPrevStreak] = useState(0);

  const [noteTitle, setNoteTitle] = useState('');
  const [noteContent, setNoteContent] = useState('');
  const [noteTags, setNoteTags] = useState('');
  const [noteSuccess, setNoteSuccess] = useState(false);
  const noteTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Use the user's local timezone date string, not UTC
  const now = new Date();
  const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

  const fetchData = async () => {
    try {
      const [rulesData, completionsData, statsData, gamificationData] = await Promise.all([
        api.get('/api/rules'),
        api.get(`/api/checklists?date=${todayStr}`),
        api.get(`/api/stats?today=${todayStr}`),
        api.get('/api/gamification/me').catch(() => null),
      ]);
      
      if (!rulesData || !completionsData || !statsData) return;

      setRules(rulesData);
      setCompletions(completionsData);
      setFeed(statsData.feed || []);
      setUserStats(statsData.userStats || {});
      if (gamificationData) setGamification(gamificationData);
      
      const myStreak = user?.username ? statsData.userStats[user.username]?.currentStreak || 0 : 0;
      if (myStreak > prevStreak && prevStreak > 0 && myStreak % 5 === 0) {
        fireStreakConfetti();
        soundManager.levelUp();
      }
      setPrevStreak(myStreak);
    } catch (err) {
      console.error('Dashboard fetch error:', err);
    } finally {
      setLoading(false);
    }
  };

  // Keep a ref to the latest fetchData to avoid stale closures in socket callbacks
  const fetchDataRef = useRef(fetchData);
  fetchDataRef.current = fetchData;

  useEffect(() => {
    fetchDataRef.current();
    const cleanup = onActivity(() => {
      fetchDataRef.current();
    });
    return () => {
      cleanup?.();
      if (noteTimeoutRef.current) clearTimeout(noteTimeoutRef.current);
    };
  }, [onActivity]);

  const handleToggle = async (ruleId: number) => {
    const wasCompleted = completions.some(c => c.user_id === user?.id && c.rule_id === ruleId);
    try {
      // Toggle and get xpResult back from server-side awarding
      const result = await api.post('/api/checklists/toggle', { ruleId, date: todayStr });
      
      if (!wasCompleted && result.checked) {
        // Just checked it off!
        fireConfetti({ particleCount: 60, spread: 50, origin: { y: 0.7 } });
        soundManager.check();
        
        // XP is awarded server-side inside the toggle route
        // The response includes xpResult when a new completion is inserted
        if (result.xpResult && result.xpResult.leveledUp) {
          setTimeout(() => {
            soundManager.levelUp();
            fireConfetti({ particleCount: 150, spread: 100 });
          }, 300);
        }
      } else {
        soundManager.uncheck();
      }
      
      fetchData();
    } catch (err) {
      console.error(err);
    }
  };

  const handleReaction = async (targetType: string, targetId: number, emoji: string) => {
    try {
      await api.post('/api/reactions', { targetType, targetId, emoji });
      fetchData();
    } catch (err) {
      console.error(err);
    }
  };

  const handleQuickNote = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!noteTitle || !noteContent) return;
    try {
      await api.post('/api/writeups', { title: noteTitle, content: noteContent, tags: noteTags });
      soundManager.notification();
      setNoteTitle('');
      setNoteContent('');
      setNoteTags('');
      setNoteSuccess(true);
      fetchData();
      if (noteTimeoutRef.current) clearTimeout(noteTimeoutRef.current);
      noteTimeoutRef.current = setTimeout(() => setNoteSuccess(false), 3000);
    } catch (err) {
      console.error(err);
    }
  };

  const userCompletions = completions.filter(c => c.user_id === user?.id).map(c => c.rule_id);
  const completionPercentage = rules.length > 0 ? (userCompletions.length / rules.length) * 100 : 0;
  const friendName = Object.keys(userStats).find(name => name !== user?.username);
  const friendStreak = friendName ? userStats[friendName]?.currentStreak || 0 : 0;
  const myStreak = user?.username ? userStats[user.username]?.currentStreak || 0 : 0;

  return (
    <div className="space-y-6">
      {/* Welcome Banner with XP */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Status Hub</h2>
          <p className="text-gray-500 text-sm mt-1">Consistency check with your accountability partner.</p>
        </div>
        
        <div className="flex gap-3 flex-wrap">
          {/* XP / Level Card */}
          {gamification && (
            <div className="flex items-center gap-2.5 px-4 py-2 rounded-xl bg-white/[0.02] border border-white/5">
              <Zap className="w-5 h-5 text-white" />
              <div>
                <div className="text-[9px] uppercase tracking-wider text-gray-500 font-semibold">Level {gamification.level}</div>
                <div className="text-sm font-bold text-white">{gamification.rankTitle}</div>
                <div className="w-20 h-1 bg-white/10 rounded-full mt-0.5 overflow-hidden">
                  <div 
                    className="h-full bg-white rounded-full transition-all duration-500"
                    style={{ width: `${gamification.progressToNext}%` }}
                  />
                </div>
              </div>
            </div>
          )}
          
          {/* Streak Flame */}
          <div className="flex items-center gap-2.5 px-4 py-2 rounded-xl bg-white/[0.02] border border-white/5">
            <Flame className={`w-5 h-5 ${myStreak > 0 ? 'text-white' : 'text-gray-700'}`} />
            <div>
              <div className="text-[9px] uppercase tracking-wider text-gray-500 font-semibold">Your Streak</div>
              <div className="text-sm font-bold text-white">{myStreak} Days</div>
            </div>
          </div>
          
          {friendName && (
            <div className="flex items-center gap-2.5 px-4 py-2 rounded-xl bg-white/[0.02] border border-white/5">
              <Flame className="w-5 h-5 text-gray-600" />
              <div>
                <div className="text-[9px] uppercase tracking-wider text-gray-500 font-semibold">@{friendName}'s</div>
                <div className="text-sm font-bold text-gray-400">{friendStreak} Days</div>
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Checklist Widget */}
        <div className="lg:col-span-2 space-y-6">
          <div className="glass-panel p-6 rounded-2xl border border-white/5 flex flex-col md:flex-row items-center gap-6 justify-between">
            <div className="space-y-1.5 text-center md:text-left">
              <h3 className="text-lg font-bold text-white">Your Targets Today</h3>
              <p className="text-gray-500 text-xs max-w-sm">Completing rules earns XP and extends your streak. Stay consistent!</p>
              <div className="text-xs text-gray-400 font-medium bg-white/[0.03] border border-white/5 rounded-md px-2 py-0.5 inline-block mt-1">
                {new Date().toLocaleDateString(undefined, { weekday: 'long', month: 'short', day: 'numeric' })}
              </div>
            </div>
            <div className="shrink-0">
              <ProgressRing progress={completionPercentage} />
            </div>
          </div>

          {/* Checklists */}
          <div className="glass-panel p-6 rounded-2xl border border-white/5 space-y-4">
            <div className="flex items-center justify-between">
              <h4 className="text-sm font-bold text-gray-400 uppercase tracking-widest">Rule Items</h4>
              {completionPercentage === 100 && rules.length > 0 && (
                <span className="text-xs font-bold text-white bg-white/5 px-2 py-0.5 rounded border border-white/10">
                  All Complete! +{rules.length * 25} XP
                </span>
              )}
            </div>
            
            {loading ? (
              <div className="text-gray-500 text-sm py-6 text-center">Loading list...</div>
            ) : rules.length === 0 ? (
              <div className="text-center py-8 text-gray-600 text-sm">
                No ground rules established yet. Go to &quot;Ground Rules&quot; tab to configure tasks.
              </div>
            ) : (
              <div className="space-y-2">
                {rules.map((rule) => {
                  const isCompleted = userCompletions.includes(rule.id);
                  return (
                    <button
                      key={rule.id}
                      onClick={() => handleToggle(rule.id)}
                      className={`w-full flex items-center justify-between text-left p-4 rounded-xl border transition-all cursor-pointer group ${
                        isCompleted
                          ? 'bg-white/[0.02] border-white/5'
                          : 'bg-transparent border-white/5 hover:border-white/10'
                      }`}
                    >
                      <div className="flex items-center gap-3.5 pr-4">
                        {isCompleted ? (
                          <CheckSquare className="w-5 h-5 text-white shrink-0" />
                        ) : (
                          <Square className="w-5 h-5 text-gray-600 shrink-0 group-hover:text-white transition-colors" />
                        )}
                        <div>
                          <p className={`font-semibold text-sm ${isCompleted ? 'line-through text-gray-500' : 'text-white'}`}>{rule.title}</p>
                          <p className="text-[11px] text-gray-500 mt-0.5 line-clamp-1">{rule.description || 'No description'}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 shrink-0">
                        {isCompleted && (
                          <span className="text-[10px] font-bold text-gray-400">+25 XP</span>
                        )}
                        <span className="text-[10px] font-bold px-2 py-0.5 rounded border uppercase bg-white/[0.03] text-gray-400 border-white/10">
                          {rule.difficulty}
                        </span>
                      </div>
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        </div>

        {/* Right Panel */}
        <div className="space-y-6">
          {/* Quick Writeup */}
          <div className="glass-panel p-6 rounded-2xl border border-white/5 space-y-4">
            <h3 className="text-md font-bold text-white flex items-center gap-2">
              <Notebook className="w-4.5 h-4.5 text-gray-400" />
              Quick Writeup Log
            </h3>
            {noteSuccess && (
              <div className="p-2.5 text-xs text-white bg-white/5 border border-white/10 rounded-lg relative z-50">
                Progress logged successfully to shared feed!
              </div>
            )}
            <form onSubmit={handleQuickNote} className="space-y-3">
              <label htmlFor="dash-note-title" className="sr-only">Writeup Title</label>
              <input id="dash-note-title" type="text" placeholder="Title..." value={noteTitle} onChange={e => setNoteTitle(e.target.value)} className="w-full px-3 py-2 rounded-lg glass-input text-xs" required />
              <label htmlFor="dash-note-content" className="sr-only">Writeup Content</label>
              <textarea id="dash-note-content" placeholder="What progress did you make?" value={noteContent} onChange={e => setNoteContent(e.target.value)} className="w-full px-3 py-2 rounded-lg glass-input text-xs h-16 resize-none" required />
              <label htmlFor="dash-note-tags" className="sr-only">Tags</label>
              <input id="dash-note-tags" type="text" placeholder="Tags: success, blockers..." value={noteTags} onChange={e => setNoteTags(e.target.value)} className="w-full px-3 py-2 rounded-lg glass-input text-xs" />
              <button type="submit" className="w-full py-1.5 text-xs font-semibold rounded-lg bg-white hover:bg-gray-200 transition-colors cursor-pointer text-black">
                Log Writeup
              </button>
            </form>
          </div>

          {/* Activity Feed with Reactions */}
          <div className="glass-panel p-6 rounded-2xl border border-white/5 space-y-4">
            <h3 className="text-md font-bold text-white flex items-center gap-2">
              <History className="w-4.5 h-4.5 text-gray-400" />
              Who Did What Feed
            </h3>
            <div className="space-y-4 max-h-[320px] overflow-y-auto no-scrollbar pr-1">
              {feed.length === 0 ? (
                <p className="text-xs text-gray-600 text-center py-6">No recent actions logged.</p>
              ) : (
                feed.map((item, idx) => (
                  <div key={`${item.type}-${item.id}-${idx}`} className="flex gap-3 text-xs group">
                    <div className="flex flex-col items-center">
                      <div className="p-1.5 rounded-full shrink-0 bg-white/5 text-gray-400">
                        {item.type === 'checklist' ? <CheckSquare className="w-3.5 h-3.5" /> : <MessageSquare className="w-3.5 h-3.5" />}
                      </div>
                      {idx < feed.length - 1 && <div className="w-px h-full bg-white/5 mt-1.5" />}
                    </div>
                    <div className="pb-2 flex-1">
                      <p className="text-gray-300">
                        <span className="font-bold text-white">@{item.username}</span>{' '}
                        {item.type === 'checklist' ? 'checked off' : 'posted'}{' '}
                        <span className="text-white font-medium">&quot;{item.item_title}&quot;</span>
                      </p>
                      <span className="text-[10px] text-gray-600 block mt-1">
                        {new Date(item.timestamp).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })}
                      </span>
                      
                      {/* Reactions */}
                      <div className="flex gap-1 mt-2">
                        {REACTION_EMOJIS.map(emoji => (
                          <button
                            key={emoji}
                            onClick={() => handleReaction(item.type, item.id, emoji)}
                            className="text-[10px] px-1.5 py-0.5 rounded bg-white/[0.02] border border-white/5 hover:border-white/20 hover:bg-white/5 transition-all cursor-pointer opacity-60 hover:opacity-100"
                          >
                            {emoji}
                          </button>
                        ))}
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Achievement Badges */}
          {gamification && gamification.achievements.length > 0 && (
            <div className="glass-panel p-6 rounded-2xl border border-white/5 space-y-3">
              <h3 className="text-sm font-bold text-white flex items-center gap-2">
                <Trophy className="w-4 h-4 text-white" />
                Achievements
              </h3>
              <div className="flex flex-wrap gap-2">
                {gamification.achievements.map(ach => (
                  <div key={ach.id} className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-white/[0.02] border border-white/5 text-xs">
                    <span>{ach.badge_icon}</span>
                    <span className="text-gray-300 font-medium">{ach.badge_name}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
