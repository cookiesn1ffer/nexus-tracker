import { Component, type ReactNode } from 'react';
import { AlertTriangle, RefreshCw } from 'lucide-react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export default class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('ErrorBoundary caught an error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-black flex items-center justify-center p-6">
          <div className="glass-panel p-8 rounded-2xl border border-white/5 max-w-md w-full text-center space-y-5">
            <div className="inline-flex p-3 rounded-xl bg-white/5 text-white border border-white/10">
              <AlertTriangle className="w-8 h-8" />
            </div>
            <h1 className="text-xl font-bold text-white">Something Went Wrong</h1>
            <p className="text-gray-500 text-sm">
              The app encountered an unexpected error. Don&apos;t worry — your data is safe.
            </p>
            {this.state.error && (
              <div className="p-3 bg-white/[0.02] rounded-lg text-left overflow-auto max-h-32">
                <code className="text-xs text-gray-400 font-mono block">{this.state.error.message}</code>
              </div>
            )}
            <button
              onClick={() => window.location.reload()}
              className="w-full bg-white hover:bg-gray-200 text-black font-medium py-2.5 rounded-lg text-sm transition-all flex items-center justify-center gap-2 cursor-pointer"
            >
              <RefreshCw className="w-4 h-4" />
              Reload App
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
