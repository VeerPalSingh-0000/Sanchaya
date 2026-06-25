'use client';

import { motion } from 'framer-motion';
import { signIn } from 'next-auth/react';
import Image from 'next/image';

const FEATURES = [
  {
    title: 'Track Everything',
    description: 'Keep a comprehensive list of movies, TV shows, and anime you have watched or plan to watch.',
    icon: 'list_alt',
    color: 'from-blue-500 to-cyan-400'
  },
  {
    title: 'Discover New Favorites',
    description: 'Get personalized recommendations and explore trending media across the globe.',
    icon: 'explore',
    color: 'from-purple-500 to-pink-500'
  },
  {
    title: 'Beautiful Interface',
    description: 'Enjoy a premium, ad-free experience designed for media lovers, by media lovers.',
    icon: 'auto_awesome',
    color: 'from-orange-400 to-rose-400'
  }
];

export default function LandingPage() {
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
          <span className="material-symbols-outlined text-primary text-[18px]">movie</span>
          <span className="text-sm font-medium tracking-wide">The Ultimate Media Tracker</span>
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
          Discover, save, and track your favorite movies, TV series, and anime all in one beautifully designed place.
        </motion.p>

        {/* CTAs */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="flex flex-col sm:flex-row items-center gap-4 w-full sm:w-auto"
        >
          <button 
            onClick={() => signIn()}
            className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-primary text-black font-bold text-lg hover:scale-105 hover:shadow-[0_0_30px_rgba(255,193,116,0.4)] transition-all duration-300 flex items-center justify-center gap-2"
          >
            Get Started <span className="material-symbols-outlined">arrow_forward</span>
          </button>
          
          <a 
            href="https://github.com/VeerPalSingh-0000/Sanchaya" 
            target="_blank" 
            rel="noopener noreferrer"
            className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-white/5 text-white font-semibold text-lg border border-white/10 hover:bg-white/10 hover:scale-105 transition-all duration-300 flex items-center justify-center gap-2"
          >
            <span className="material-symbols-outlined">code</span> View GitHub
          </a>
        </motion.div>
      </div>

      {/* Features Section */}
      <div className="relative z-10 max-w-7xl mx-auto px-6 py-24">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
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
                <span className="material-symbols-outlined text-white text-[28px] drop-shadow-md">{feature.icon}</span>
              </div>
              <h3 className="text-2xl font-bold mb-3">{feature.title}</h3>
              <p className="text-white/60 leading-relaxed">{feature.description}</p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Gen Z Footer */}
      <footer className="relative z-10 py-12 flex flex-col items-center justify-center gap-2 mt-8 text-white/50">
        <p className="text-sm font-medium tracking-wide lowercase">made with 🍿 for the culture.</p>
        <p className="text-xs opacity-60">© {new Date().getFullYear()} sanchaya. your vibe, your media.</p>
      </footer>
    </div>
  );
}
