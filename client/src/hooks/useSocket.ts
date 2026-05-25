import { useEffect, useRef, useCallback } from 'react';
import { io, Socket } from 'socket.io-client';

export function useSocket() {
  const socketRef = useRef<Socket | null>(null);

  useEffect(() => {
    const token = localStorage.getItem('nexus_token');
    const socket = io(window.location.origin, {
      transports: ['websocket', 'polling'],
      auth: { token },
    });
    socketRef.current = socket;
    
    socket.emit('join', { room: 'nexus-room' });
    
    return () => {
      socket.disconnect();
    };
  }, []);

  const onActivity = useCallback((callback: (data: any) => void) => {
    if (!socketRef.current) return;
    socketRef.current.on('activity', callback);
    return () => {
      socketRef.current?.off('activity', callback);
    };
  }, []);

  return { socket: socketRef.current, onActivity };
}
