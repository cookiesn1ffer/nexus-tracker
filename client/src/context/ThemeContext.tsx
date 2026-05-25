import React, { createContext, useContext, useState, useEffect } from 'react';

interface ThemeContextType {
  soundEnabled: boolean;
  setSoundEnabled: (enabled: boolean) => void;
}

const ThemeContext = createContext<ThemeContextType | null>(null);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [soundEnabled, setSoundEnabled] = useState(() => {
    return localStorage.getItem('nexus_sound') !== 'false';
  });

  useEffect(() => {
    // Static monochrome accent styles
    const style = document.createElement('style');
    style.textContent = `
      .accent-text { color: #ffffff !important; }
      .accent-bg { background-color: #ffffff !important; }
      .accent-border { border-color: rgba(255, 255, 255, 0.2) !important; }
      .accent-shadow { box-shadow: none !important; }
    `;
    style.id = 'dynamic-accent';
    const existing = document.getElementById('dynamic-accent');
    if (existing) existing.remove();
    document.head.appendChild(style);
  }, []);

  useEffect(() => {
    localStorage.setItem('nexus_sound', String(soundEnabled));
  }, [soundEnabled]);

  return (
    <ThemeContext.Provider value={{ soundEnabled, setSoundEnabled }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) throw new Error('useTheme must be used inside ThemeProvider');
  return context;
}
