'use client';

import Link from 'next/link';
import { motion } from 'framer-motion';
import { Clapperboard, ListTodo, Compass, Sparkles, ArrowRight, CodeXml, Smartphone, Download, CheckCircle2, Zap } from 'lucide-react';

const FEATURES = [
  {
    title: 'Track Everything',
    description: 'Keep a comprehensive list of movies, TV shows, and anime you have watched or plan to watch.',
    icon: ListTodo,
    color: 'from-blue-500 to-cyan-400'
  },
  {
    title: 'Discover New Favorites',
    description: 'Get personalized recommendations and explore trending media across the globe.',
    icon: Compass,
    color: 'from-purple-500 to-pink-500'
  },
  {
    title: 'Flutter Mobile App',
    description: 'Track media anywhere with our high-performance Flutter mobile app featuring offline sync & episode tracking.',
    icon: Smartphone,
    color: 'from-emerald-400 to-teal-500'
  },
  {
    title: 'Beautiful Interface',
    description: 'Enjoy a premium, ad-free experience designed for media lovers, by media lovers.',
    icon: Sparkles,
    color: 'from-orange-400 to-rose-400'
  }
];

export default function LandingPage() {
  const apkDownloadUrl = 'https://raw.githubusercontent.com/VeerPalSingh-0000/Sanchaya/main/releases/sanchaya-app.apk';

  return (
    <div className="min-h-screen bg-[#06090e] text-white overflow-x-hidden selection:bg-primary/30">
      
      {/* Immersive Background */}
      <div className="fixed inset-0 z-0 pointer-events-none">
        <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] bg-primary/20 rounded-full blur-[120px] mix-blend-screen opacity-50" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] bg-secondary/20 rounded-full blur-[120px] mix-blend-screen opacity-50" />
        <div className="absolute top-[40%] left-[20%] w-[60%] h-[20%] bg-purple-500/10 rounded-full blur-[100px] mix-blend-screen" />
      </div>

      <div className="relative z-10 flex flex-col items-center justify-center min-h-[90vh] px-6 text-center max-w-5xl mx-auto pt-24 md:pt-0">
        
        {/* Badge */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="flex items-center gap-2 px-4 py-2 rounded-full bg-white/5 border border-white/10 backdrop-blur-md mb-8"
        >
          <Clapperboard className="text-primary w-5 h-5" />
          <span className="text-sm font-medium tracking-wide">Web + Flutter Mobile App</span>
        </motion.div>

        {/* Hero Title */}
        <motion.h1 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="text-5xl md:text-7xl lg:text-8xl font-bold font-display tracking-tight leading-tight mb-6"
        >
          Your Entertainment <br />
          <span className="bg-gradient-to-r from-primary via-[#ffb0cd] to-secondary bg-clip-text text-transparent">
            Universe
          </span>
        </motion.h1>

        {/* Subtitle */}
        <motion.p 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="text-lg md:text-2xl text-white/60 max-w-2xl mb-12 leading-relaxed"
        >
          Discover, save, and track your favorite movies, TV series, and anime on the web or on the go with our native Flutter app.
        </motion.p>

        {/* CTAs */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="flex flex-col sm:flex-row items-center gap-4 w-full sm:w-auto"
        >
          <Link 
            href="/auth/signin"
            className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-primary text-black font-bold text-lg hover:scale-105 hover:shadow-[0_0_30px_rgba(255,193,116,0.4)] transition-all duration-300 flex items-center justify-center gap-2"
          >
            Get Started <ArrowRight className="w-5 h-5" />
          </Link>

          <a 
            href={apkDownloadUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-gradient-to-r from-teal-500/20 to-emerald-500/20 border border-emerald-500/40 text-emerald-300 font-bold text-lg hover:scale-105 hover:bg-emerald-500/30 transition-all duration-300 flex items-center justify-center gap-2"
          >
            <Download className="w-5 h-5" /> Download App (APK)
          </a>
          
          <a 
            href="https://github.com/VeerPalSingh-0000/Sanchaya" 
            target="_blank" 
            rel="noopener noreferrer"
            className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-white/5 text-white font-semibold text-lg border border-white/10 hover:bg-white/10 hover:scale-105 transition-all duration-300 flex items-center justify-center gap-2"
          >
            <CodeXml className="w-5 h-5" /> View GitHub
          </a>
        </motion.div>
      </div>

      {/* Features Section */}
      <div className="relative z-10 max-w-7xl mx-auto px-6 py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {FEATURES.map((feature, i) => (
            <motion.div 
              key={i}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.5, delay: i * 0.1 }}
              className="bg-white/5 border border-white/10 rounded-3xl p-8 backdrop-blur-sm hover:bg-white/10 transition-colors group"
            >
              <div className={`w-14 h-14 rounded-2xl mb-6 flex items-center justify-center bg-gradient-to-br ${feature.color} bg-opacity-20 shadow-lg group-hover:scale-110 transition-transform`}>
                <feature.icon className="text-white w-8 h-8 drop-shadow-md" />
              </div>
              <h3 className="text-2xl font-bold mb-3">{feature.title}</h3>
              <p className="text-white/60 leading-relaxed">{feature.description}</p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Flutter Mobile App Showcase Section */}
      <div className="relative z-10 max-w-6xl mx-auto px-6 py-16">
        <motion.div 
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-emerald-950/40 via-[#0a151b] to-black border border-emerald-500/20 p-8 md:p-12 backdrop-blur-md shadow-2xl"
        >
          <div className="absolute top-0 right-0 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
            <div>
              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-6">
                <Zap className="w-4 h-4" /> Flutter Native App
              </div>
              <h2 className="text-3xl md:text-5xl font-bold font-display tracking-tight mb-4">
                Sanchaya On The Go 📱
              </h2>
              <p className="text-white/70 text-lg mb-6 leading-relaxed">
                Take your media vault everywhere. Experience 60fps performance, episode progress tracking, dynamic poster color palettes, and real-time cloud sync.
              </p>

              <div className="space-y-3 mb-8">
                {[
                  'Real-time Supabase Watchlist Synchronization',
                  'Interactive Anime & TV Series Episode Tracker',
                  'Dynamic Color Themes from Poster Artwork',
                  'Offline Storage & Hive Caching Support'
                ].map((item, idx) => (
                  <div key={idx} className="flex items-center gap-3 text-white/90">
                    <CheckCircle2 className="w-5 h-5 text-emerald-400 flex-shrink-0" />
                    <span>{item}</span>
                  </div>
                ))}
              </div>

              <a 
                href={apkDownloadUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-3 px-8 py-4 rounded-2xl bg-emerald-400 text-black font-bold text-lg hover:bg-emerald-300 hover:scale-105 transition-all shadow-[0_0_25px_rgba(52,211,153,0.3)]"
              >
                <Download className="w-5 h-5" /> Download Android APK
              </a>
            </div>

            <div className="flex justify-center items-center">
              <div className="relative w-64 h-[420px] rounded-[40px] border-4 border-white/10 bg-black/80 p-4 shadow-2xl flex flex-col justify-between overflow-hidden group hover:border-emerald-500/40 transition-colors">
                <div className="absolute top-2 left-1/2 -translate-x-1/2 w-24 h-4 bg-white/10 rounded-full" />
                <div className="pt-6 text-center">
                  <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-emerald-400 to-teal-500 mx-auto flex items-center justify-center mb-3 shadow-md">
                    <Clapperboard className="w-6 h-6 text-black" />
                  </div>
                  <span className="font-bold text-lg text-white">Sanchaya Mobile</span>
                  <p className="text-xs text-emerald-400 font-mono mt-1">Built with Flutter 3.x</p>
                </div>

                <div className="bg-white/5 rounded-2xl p-4 border border-white/10 space-y-3">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-white/60">Watch Status</span>
                    <span className="text-emerald-400 font-bold">Watching (12)</span>
                  </div>
                  <div className="w-full h-2 bg-white/10 rounded-full overflow-hidden">
                    <div className="h-full w-[70%] bg-emerald-400 rounded-full" />
                  </div>
                  <div className="text-xs text-white/50 text-center">
                    ⚡ Live Cloud Sync Active
                  </div>
                </div>

                <div className="text-center pb-2">
                  <span className="text-xs text-white/40">Ready for Android & iOS</span>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Gen Z Footer */}
      <footer className="relative z-10 py-12 flex flex-col items-center justify-center gap-2 mt-8 text-white/50">
        <p className="text-sm font-medium tracking-wide lowercase">made with 🍿 for the culture.</p>
        <p className="text-xs opacity-60">© {new Date().getFullYear()} sanchaya. your vibe, your media.</p>
      </footer>
    </div>
  );
}

