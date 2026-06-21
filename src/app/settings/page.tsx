'use client';

import { useSession } from 'next-auth/react';
import { useState } from 'react';

const UserIcon = () => (
  <span className="material-symbols-outlined text-[24px]">person</span>
);

const BellIcon = () => (
  <span className="material-symbols-outlined text-[24px]">notifications</span>
);

const PaletteIcon = () => (
  <span className="material-symbols-outlined text-[24px]">palette</span>
);

const AlertTriangleIcon = () => (
  <span className="material-symbols-outlined text-[24px] text-error">warning</span>
);

export default function SettingsPage() {
  const { data: session } = useSession();
  
  const [notifications, setNotifications] = useState(true);
  const [darkMode, setDarkMode] = useState(true);
  const [saving, setSaving] = useState(false);

  const handleSave = () => {
    setSaving(true);
    setTimeout(() => {
      setSaving(false);
      alert("Preferences saved successfully!");
    }, 800);
  };

  return (
    <main className="max-w-3xl mx-auto px-margin-mobile md:px-margin-desktop py-12 md:py-24 w-full flex flex-col gap-12 slide-up pb-32">
      <header className="flex flex-col gap-4">
        <h1 className="font-display-xl-mobile md:font-display-xl text-[40px] md:text-[64px] font-bold text-on-surface tracking-tight">
          Settings
        </h1>
        <p className="font-body-md text-[16px] text-on-surface-variant max-w-lg">
          Manage your account preferences and customize your Cineverse experience.
        </p>
      </header>

      <div className="flex flex-col gap-8">
        
        {/* Profile Section */}
        <section className="glass-panel rounded-2xl p-6 md:p-8 flex flex-col gap-6">
          <div className="flex items-center gap-3 border-b border-white/10 pb-4">
            <UserIcon />
            <h2 className="font-headline-lg-mobile md:font-headline-lg text-[20px] md:text-[24px] font-bold text-on-surface">Profile Information</h2>
          </div>
          
          <div className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              <label className="font-label-sm text-[12px] font-bold uppercase tracking-wider text-on-surface-variant" htmlFor="name">Display Name</label>
              <input 
                id="name" 
                type="text" 
                className="w-full bg-surface-container/50 border border-white/10 rounded-lg px-4 py-3 text-on-surface font-body-md focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all" 
                defaultValue={session?.user?.name || ''} 
                placeholder="Your name"
              />
            </div>
            
            <div className="flex flex-col gap-2">
              <label className="font-label-sm text-[12px] font-bold uppercase tracking-wider text-on-surface-variant" htmlFor="email">Email Address</label>
              <input 
                id="email" 
                type="email" 
                className="w-full bg-surface-container/20 border border-white/5 rounded-lg px-4 py-3 text-on-surface-variant font-body-md opacity-70 cursor-not-allowed" 
                defaultValue={session?.user?.email || ''} 
                disabled 
                title="Email cannot be changed directly"
              />
            </div>
          </div>

          <div className="flex justify-end mt-4">
            <button 
              className="bg-primary text-surface font-bold px-6 py-3 rounded-full hover:bg-primary-container transition-colors shadow-[0_10px_20px_rgba(245,158,11,0.2)] active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2" 
              onClick={handleSave} 
              disabled={saving}
            >
              {saving ? (
                <><span className="material-symbols-outlined animate-spin text-[20px]">autorenew</span> Saving...</>
              ) : 'Save Changes'}
            </button>
          </div>
        </section>

        {/* Appearance & Preferences */}
        <section className="glass-panel rounded-2xl p-6 md:p-8 flex flex-col gap-6">
          <div className="flex items-center gap-3 border-b border-white/10 pb-4">
            <PaletteIcon />
            <h2 className="font-headline-lg-mobile md:font-headline-lg text-[20px] md:text-[24px] font-bold text-on-surface">Appearance & UI</h2>
          </div>
          
          <div className="flex flex-col gap-6">
            <div className="flex items-center justify-between">
              <div className="flex flex-col gap-1">
                <div className="font-body-md font-bold text-on-surface text-[16px]">Dark Mode</div>
                <div className="font-label-sm text-on-surface-variant text-[14px]">Enable dark theme throughout the application</div>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input 
                  type="checkbox" 
                  className="sr-only peer"
                  checked={darkMode} 
                  onChange={(e) => setDarkMode(e.target.checked)} 
                />
                <div className="w-11 h-6 bg-surface-variant rounded-full peer peer-checked:bg-primary peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all shadow-inner"></div>
              </label>
            </div>
          </div>
        </section>

        {/* Notifications */}
        <section className="glass-panel rounded-2xl p-6 md:p-8 flex flex-col gap-6">
          <div className="flex items-center gap-3 border-b border-white/10 pb-4">
            <BellIcon />
            <h2 className="font-headline-lg-mobile md:font-headline-lg text-[20px] md:text-[24px] font-bold text-on-surface">Notifications</h2>
          </div>
          
          <div className="flex flex-col gap-6">
            <div className="flex items-center justify-between">
              <div className="flex flex-col gap-1">
                <div className="font-body-md font-bold text-on-surface text-[16px]">Email Updates</div>
                <div className="font-label-sm text-on-surface-variant text-[14px]">Receive emails about new features and recommendations</div>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input 
                  type="checkbox" 
                  className="sr-only peer"
                  checked={notifications} 
                  onChange={(e) => setNotifications(e.target.checked)} 
                />
                <div className="w-11 h-6 bg-surface-variant rounded-full peer peer-checked:bg-primary peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all shadow-inner"></div>
              </label>
            </div>
          </div>
        </section>

        {/* Danger Zone */}
        <section className="glass-panel rounded-2xl p-6 md:p-8 flex flex-col gap-6 border border-error/30 bg-error-container/5 relative overflow-hidden">
          <div className="absolute top-0 left-0 w-1 h-full bg-error"></div>
          <div className="flex items-center gap-3 border-b border-error/20 pb-4">
            <AlertTriangleIcon />
            <h2 className="font-headline-lg-mobile md:font-headline-lg text-[20px] md:text-[24px] font-bold text-error">Danger Zone</h2>
          </div>
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
            <p className="font-body-md text-on-surface-variant max-w-sm">
              Once you delete your account, there is no going back. Please be certain.
            </p>
            <button className="bg-error/10 border border-error/50 text-error font-bold px-6 py-3 rounded-full hover:bg-error hover:text-on-error transition-colors whitespace-nowrap active:scale-95">
              Delete Account
            </button>
          </div>
        </section>

      </div>
    </main>
  );
}
