'use client';

import { useEffect } from 'react';

export default function ErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error('App-level error caught by error.tsx:', error);
  }, [error]);

  return (
    <div className="min-h-[80vh] flex flex-col items-center justify-center p-6 text-center pt-24 pb-32">
      <div className="w-24 h-24 bg-error/10 rounded-full flex items-center justify-center mb-6">
        <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-error"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
      </div>
      <h2 className="font-display-xl text-4xl font-bold mb-4 text-on-surface">Oops! Something went wrong</h2>
      <p className="font-body-md text-on-surface-variant max-w-md mx-auto mb-8 text-lg">
        We encountered an unexpected error while rendering this page. Our team has been notified.
      </p>
      <div className="flex gap-4">
        <button
          onClick={() => reset()}
          className="bg-primary text-surface font-bold py-3 px-8 rounded-full hover:bg-primary-container transition-all shadow-[0_10px_20px_rgba(245,158,11,0.2)] active:scale-95"
        >
          Try Again
        </button>
        <button
          onClick={() => window.location.href = '/'}
          className="bg-surface-container border border-white/10 text-on-surface font-bold py-3 px-8 rounded-full hover:bg-white/10 transition-all active:scale-95"
        >
          Go Home
        </button>
      </div>
      {process.env.NODE_ENV === 'development' && (
        <div className="mt-12 w-full max-w-2xl bg-black/50 p-4 rounded-xl border border-error/20 overflow-auto text-left">
          <p className="text-error font-mono text-sm break-all">{error.message}</p>
          {error.stack && (
            <pre className="text-error/60 font-mono text-[10px] mt-2 whitespace-pre-wrap break-all">
              {error.stack}
            </pre>
          )}
        </div>
      )}
    </div>
  );
}
