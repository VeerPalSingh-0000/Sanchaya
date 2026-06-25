import Link from 'next/link';
import { Film, AlertCircle, Compass } from 'lucide-react';

export default function NotFound() {
  return (
    <div className="min-h-[70vh] flex flex-col items-center justify-center text-center px-4">
      <div className="mb-6 relative">
        <Film className="w-[100px] h-[100px] text-primary opacity-20" />
        <AlertCircle className="w-[60px] h-[60px] text-error absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2" />
      </div>
      
      <h1 className="text-4xl font-bold font-display text-white mb-4">
        404 - Not Found
      </h1>
      
      <p className="text-on-surface-variant max-w-md mx-auto mb-8 text-lg">
        We couldn't find the media you're looking for. It may have been removed or the ID is invalid.
      </p>
      
      <Link 
        href="/discover"
        className="bg-primary text-black font-semibold px-6 py-3 rounded-full hover:bg-primary/90 transition-all shadow-[0_0_20px_rgba(255,193,116,0.3)] flex items-center gap-2 inline-flex"
      >
        <Compass className="w-5 h-5" />
        Discover New Media
      </Link>
    </div>
  );
}
