'use client';

import { motion } from 'framer-motion';
import { useEffect } from 'react';

export default function Template({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    const savedTheme = localStorage.getItem('sanchaya_theme') || 'theme-oled';
    document.body.classList.remove('theme-oled', 'theme-midnight', 'theme-slate');
    document.body.classList.add(savedTheme);
  }, []);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 20 }}
      transition={{ type: 'spring', stiffness: 200, damping: 20 }}
    >
      {children}
    </motion.div>
  );
}
