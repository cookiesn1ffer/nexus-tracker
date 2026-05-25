import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { api } from '../api';
import { Plus, Trash2, Tag, Calendar, User } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import rehypeSanitize from 'rehype-sanitize';

interface Writeup {
  id: number;
  user_id: number;
  username: string;
  title: string;
  content: string;
  tags: string;
  created_at: string;
}

export default function WriteupsBoard() {
  const { user } = useAuth();
  const [writeups, setWriteups] = useState<Writeup[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Note input states
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [tags, setTags] = useState('');
  const [error, setError] = useState('');

  const fetchWriteups = async () => {
    try {
      const data = await api.get('/api/writeups');
      if (data) setWriteups(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWriteups();
  }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !content) return;
    setError('');
    try {
      await api.post('/api/writeups', { title, content, tags });
      setTitle('');
      setContent('');
      setTags('');
      fetchWriteups();
    } catch (err: any) {
      setError(err.message || 'Failed to submit writeup');
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this writeup?')) return;
    try {
      await api.delete(`/api/writeups/${id}`);
      fetchWriteups();
    } catch (err) {
      setError('Failed to delete writeup');
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Writeups Shared Notebook</h2>
        <p className="text-gray-500 text-sm mt-1">Log progress diaries, design briefs, snippets, and blockers.</p>
      </div>

      {error && (
        <div className="p-3 bg-white/5 border border-white/10 text-gray-300 rounded-lg text-sm">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Creator Panel */}
        <div className="glass-panel p-6 rounded-2xl border border-white/5 h-fit space-y-4">
          <h3 className="text-lg font-bold text-white flex items-center gap-2">
            <Plus className="w-5 h-5 text-gray-400" />
            Add Writeup Note
          </h3>
          <form onSubmit={handleCreate} className="space-y-4">
            <div>
              <label htmlFor="writeup-title" className="block text-xs font-semibold text-gray-500 mb-1 uppercase tracking-wider">Title</label>
              <input
                id="writeup-title"
                type="text"
                placeholder="e.g. SQLite schema defined"
                value={title}
                onChange={e => setTitle(e.target.value)}
                className="w-full py-2 px-3 rounded-lg glass-input text-sm"
                required
              />
            </div>
            <div>
              <label htmlFor="writeup-content" className="block text-xs font-semibold text-gray-500 mb-1 uppercase tracking-wider">Writeup Content</label>
              <textarea
                id="writeup-content"
                placeholder="Provide notes/blockers/details..."
                value={content}
                onChange={e => setContent(e.target.value)}
                className="w-full py-2 px-3 rounded-lg glass-input text-sm h-32 resize-none"
                required
              />
            </div>
            <div>
              <label htmlFor="writeup-tags" className="block text-xs font-semibold text-gray-500 mb-1 uppercase tracking-wider">Tags</label>
              <input
                id="writeup-tags"
                type="text"
                placeholder="e.g. database, block, roadmap (comma separated)"
                value={tags}
                onChange={e => setTags(e.target.value)}
                className="w-full py-2 px-3 rounded-lg glass-input text-sm"
              />
            </div>
            <button
              type="submit"
              className="w-full bg-white hover:bg-gray-200 text-black font-medium py-2 rounded-lg text-sm transition-all cursor-pointer"
            >
              Post Note
            </button>
          </form>
        </div>

        {/* Shared Notebook Logs list */}
        <div className="lg:col-span-2 space-y-4">
          <h3 className="text-lg font-bold text-white">Active Logs</h3>
          {loading ? (
            <div className="text-gray-500 text-sm py-12 text-center">Loading logs...</div>
          ) : writeups.length === 0 ? (
            <div className="glass-panel p-8 rounded-2xl text-center border border-white/5 text-gray-500 text-sm">
              The shared board is empty! Be the first to publish a project update writeup.
            </div>
          ) : (
            <div className="space-y-4 max-h-[600px] overflow-y-auto no-scrollbar pr-1">
              {writeups.map((note) => (
                <div key={note.id} className="glass-panel p-6 rounded-2xl border border-white/5 relative group hover:border-white/10 transition-all space-y-4">
                  {/* Badge & author info */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <div className="p-2 rounded-full bg-white/5 text-gray-400 border border-white/5">
                        <User className="w-4 h-4" />
                      </div>
                      <div>
                        <span className="text-sm font-bold text-white">@{note.username}</span>
                        <div className="flex items-center gap-2 text-[10px] text-gray-600 mt-0.5">
                          <Calendar className="w-3.5 h-3.5" />
                          {new Date(note.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                        </div>
                      </div>
                    </div>

                    {note.user_id === user?.id && (
                      <button
                        onClick={() => handleDelete(note.id)}
                        className="p-1.5 text-gray-500 hover:text-white hover:bg-white/5 rounded-lg transition-colors cursor-pointer"
                      >
                        <Trash2 className="w-4.5 h-4.5" />
                      </button>
                    )}
                  </div>

                  {/* Title & Body */}
                  <div className="space-y-2">
                    <h4 className="text-md font-bold text-white">{note.title}</h4>
                    <div className="markdown-body text-gray-300 text-sm leading-relaxed bg-white/[0.02] p-4 rounded-xl border border-white/5">
                      <ReactMarkdown rehypePlugins={[rehypeSanitize]}>{note.content}</ReactMarkdown>
                    </div>
                  </div>

                  {/* Tags */}
                  {note.tags && (
                    <div className="flex gap-1.5 flex-wrap">
                      {note.tags.split(',').map((tag, tIdx) => {
                        const cleanTag = tag.trim();
                        if (!cleanTag) return null;
                        return (
                          <span key={tIdx} className="inline-flex items-center gap-1 px-2 py-0.5 text-[10px] font-bold tracking-wider uppercase rounded bg-white/[0.02] border border-white/5 text-gray-400">
                            <Tag className="w-3 h-3" />
                            {cleanTag}
                          </span>
                        );
                      })}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
