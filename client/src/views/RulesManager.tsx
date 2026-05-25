import React, { useState, useEffect } from 'react';
import { api } from '../api';
import { Plus, Trash2, Calendar, Award } from 'lucide-react';

interface Rule {
  id: number;
  title: string;
  description: string;
  frequency: 'daily' | 'weekly' | 'one-time';
  difficulty: 'easy' | 'medium' | 'hard';
  creator: string;
}

export default function RulesManager() {
  const [rules, setRules] = useState<Rule[]>([]);
  const [loading, setLoading] = useState(true);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [frequency, setFrequency] = useState<'daily' | 'weekly' | 'one-time'>('daily');
  const [difficulty, setDifficulty] = useState<'easy' | 'medium' | 'hard'>('medium');
  const [error, setError] = useState('');

  const fetchRules = async () => {
    try {
      const data = await api.get('/api/rules');
      if (data) setRules(data);
    } catch (err: any) {
      setError('Failed to fetch rules');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRules();
  }, []);

  const handleAddRule = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title) return;
    setError('');
    try {
      await api.post('/api/rules', { title, description, frequency, difficulty });
      setTitle('');
      setDescription('');
      setFrequency('daily');
      setDifficulty('medium');
      fetchRules();
    } catch (err: any) {
      setError(err.message || 'Failed to add rule');
    }
  };

  const handleDeleteRule = async (id: number) => {
    if (!confirm('Are you sure you want to delete this rule? This deletes all history completions.')) return;
    try {
      await api.delete(`/api/rules/${id}`);
      fetchRules();
    } catch (err) {
      setError('Failed to delete rule');
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Ground Rules</h2>
        <p className="text-gray-500 text-sm mt-1">Set targets, habits, and milestone challenges for accountability.</p>
      </div>

      {error && (
        <div className="p-3 bg-white/5 border border-white/10 text-gray-300 rounded-lg text-sm">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Creation Box */}
        <div className="glass-panel p-6 rounded-2xl h-fit border border-white/5 space-y-4">
          <h3 className="text-lg font-bold text-white flex items-center gap-2">
            <Plus className="w-5 h-5 text-gray-400" />
            Add New Rule
          </h3>
          <form onSubmit={handleAddRule} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-500 mb-1 uppercase tracking-wider">Rule Title</label>
              <input
                type="text"
                placeholder="e.g. Code for 1 hour"
                value={title}
                onChange={e => setTitle(e.target.value)}
                className="w-full py-2 px-3 rounded-lg glass-input text-sm"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-500 mb-1 uppercase tracking-wider">Description</label>
              <textarea
                placeholder="Details of the challenge..."
                value={description}
                onChange={e => setDescription(e.target.value)}
                className="w-full py-2 px-3 rounded-lg glass-input text-sm h-20 resize-none"
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-gray-500 mb-1 uppercase tracking-wider">Frequency</label>
                <select
                  value={frequency}
                  onChange={e => setFrequency(e.target.value as any)}
                  className="w-full py-2 px-3 rounded-lg glass-input text-sm bg-black cursor-pointer"
                >
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="one-time">One-time</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-500 mb-1 uppercase tracking-wider">Difficulty</label>
                <select
                  value={difficulty}
                  onChange={e => setDifficulty(e.target.value as any)}
                  className="w-full py-2 px-3 rounded-lg glass-input text-sm bg-black cursor-pointer"
                >
                  <option value="easy">Easy</option>
                  <option value="medium">Medium</option>
                  <option value="hard">Hard</option>
                </select>
              </div>
            </div>
            <button
              type="submit"
              className="w-full bg-white hover:bg-gray-200 text-black font-medium py-2 rounded-lg text-sm transition-all cursor-pointer"
            >
              Add Rule
            </button>
          </form>
        </div>

        {/* Active Rules List */}
        <div className="lg:col-span-2 space-y-4">
          <h3 className="text-lg font-bold text-white">Active Accountability Rules</h3>
          {loading ? (
            <div className="text-gray-500 text-sm py-12 text-center">Loading rules...</div>
          ) : rules.length === 0 ? (
            <div className="glass-panel p-8 rounded-2xl text-center border border-white/5 text-gray-500 text-sm">
              No ground rules defined. Add one above to kick off the accountability contest!
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {rules.map((rule) => (
                <div key={rule.id} className="glass-panel p-5 rounded-2xl border border-white/5 flex flex-col justify-between group hover:border-white/10 transition-all">
                  <div>
                    <div className="flex items-start justify-between">
                      <h4 className="font-bold text-white group-hover:text-gray-300 transition-colors">{rule.title}</h4>
                      <button
                        onClick={() => handleDeleteRule(rule.id)}
                        className="p-1 text-gray-500 hover:text-white rounded transition-colors cursor-pointer"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                    <p className="text-gray-500 text-xs mt-1.5 line-clamp-2">{rule.description || "No description provided."}</p>
                  </div>
                  <div className="flex gap-2 mt-4 flex-wrap">
                    <span className="inline-flex items-center gap-1.5 px-2 py-0.5 text-[10px] font-bold tracking-wider uppercase rounded bg-white/[0.03] text-gray-400 border border-white/10">
                      <Calendar className="w-3 h-3" />
                      {rule.frequency}
                    </span>
                    <span className="inline-flex items-center gap-1.5 px-2 py-0.5 text-[10px] font-bold tracking-wider uppercase rounded bg-white/[0.03] text-gray-400 border border-white/10">
                      <Award className="w-3 h-3" />
                      {rule.difficulty}
                    </span>
                    <span className="text-[10px] text-gray-600 self-center ml-auto">By @{rule.creator}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
