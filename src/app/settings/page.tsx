"use client";

import { useSession, signOut } from "next-auth/react";
import { useState, useEffect } from "react";

import { User, Bell, Palette, AlertTriangle, Loader2 } from "lucide-react";

const UserIcon = () => (
  <User className="w-6 h-6 text-on-surface" />
);

const BellIcon = () => (
  <Bell className="w-6 h-6 text-on-surface" />
);

const PaletteIcon = () => (
  <Palette className="w-6 h-6 text-on-surface" />
);

const AlertTriangleIcon = () => (
  <AlertTriangle className="w-6 h-6 text-error" />
);

type ThemeType = "theme-oled" | "theme-midnight" | "theme-slate";

export default function SettingsPage() {
  const { data: session, update: updateSession } = useSession();

  const [name, setName] = useState("");
  const [guestName, setGuestName] = useState("Guest User");
  const [notifications, setNotifications] = useState(true);
  const [theme, setTheme] = useState<ThemeType>("theme-oled");
  const [saving, setSaving] = useState(false);
  const [clearing, setClearing] = useState(false);

  // Load settings on mount
  useEffect(() => {
    // Theme
    const savedTheme =
      (localStorage.getItem("sanchaya_theme") as ThemeType) || "theme-oled";
    setTheme(savedTheme);

    // Guest Name
    const savedGuestName =
      localStorage.getItem("sanchaya_guest_name") || "Guest User";
    setGuestName(savedGuestName);
    if (!session) {
      setName(savedGuestName);
    } else if (session.user?.name) {
      setName(session.user.name);
    }

    // Notifications
    const savedNotifs = localStorage.getItem("sanchaya_notifications");
    setNotifications(savedNotifs !== "false");
  }, [session]);

  const handleSaveProfile = async () => {
    if (!name.trim()) return;
    setSaving(true);

    try {
      if (session) {
        const res = await fetch("/api/user", {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name }),
        });

        if (!res.ok) throw new Error("Failed to update name");

        // Refresh session
        if (updateSession) {
          await updateSession({ name });
        }
        alert("Profile updated successfully!");
      } else {
        localStorage.setItem("sanchaya_guest_name", name.trim());
        setGuestName(name.trim());
        alert("Guest profile updated successfully!");
        window.location.reload(); // Refresh navbar
      }
    } catch (err) {
      console.error(err);
      alert("Error updating profile settings.");
    } finally {
      setSaving(false);
    }
  };

  const handleThemeChange = (selectedTheme: ThemeType) => {
    setTheme(selectedTheme);
    localStorage.setItem("sanchaya_theme", selectedTheme);

    // Apply immediately to body
    document.body.classList.remove(
      "theme-oled",
      "theme-midnight",
      "theme-slate",
    );
    document.body.classList.add(selectedTheme);
  };

  const handleNotificationsChange = (checked: boolean) => {
    setNotifications(checked);
    localStorage.setItem("sanchaya_notifications", checked ? "true" : "false");
  };

  const handleDeleteOrClear = async () => {
    const message = session
      ? "Are you absolutely sure you want to delete your account? This will permanently delete your profile and all your watchlist items."
      : "Are you sure you want to clear your local watchlist and reset Sanchaya settings?";

    if (!confirm(message)) return;

    setClearing(true);
    try {
      if (session) {
        const res = await fetch("/api/user", { method: "DELETE" });
        if (!res.ok) throw new Error("Failed to delete account");
        alert("Account deleted successfully.");
        signOut();
      } else {
        // Clear all localStorage Sanchaya variables
        localStorage.removeItem("sanchaya_watchlist");
        localStorage.removeItem("sanchaya_guest_name");
        localStorage.removeItem("sanchaya_theme");
        localStorage.removeItem("sanchaya_notifications");
        alert("Local cache and watchlist cleared successfully.");
        window.location.href = "/";
      }
    } catch (err) {
      console.error(err);
      alert("Error performing requested action.");
    } finally {
      setClearing(false);
    }
  };

  return (
    <main className="max-w-3xl mx-auto px-margin-mobile md:px-margin-desktop py-12 md:py-24 w-full flex flex-col gap-12 slide-up pb-32">
      <header className="flex flex-col gap-4">
        <h1 className="font-display-xl-mobile md:font-display-xl text-[40px] md:text-[64px] font-bold text-on-surface tracking-tight">
          Settings
        </h1>
        <p className="font-body-md text-[16px] text-on-surface-variant max-w-lg">
          Manage your account preferences and customize your Sanchaya
          experience.
        </p>
      </header>

      <div className="flex flex-col gap-8">
        {/* Profile Section */}
        <section className="glass-panel rounded-2xl p-6 md:p-8 flex flex-col gap-6">
          <div className="flex items-center gap-3 border-b border-white/10 pb-4">
            <UserIcon />
            <h2 className="font-headline-lg-mobile md:font-headline-lg text-[20px] md:text-[24px] font-bold text-on-surface">
              Profile Information
            </h2>
          </div>

          <div className="flex flex-col gap-4">
            <div className="flex flex-col gap-2">
              <label
                className="font-label-sm text-[12px] font-bold uppercase tracking-wider text-on-surface-variant"
                htmlFor="displayName"
              >
                Display Name
              </label>
              <input
                id="displayName"
                type="text"
                className="w-full bg-surface-container/50 border border-white/10 rounded-lg px-4 py-3 text-on-surface font-body-md focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Your name"
              />
            </div>

            <div className="flex flex-col gap-2">
              <label
                className="font-label-sm text-[12px] font-bold uppercase tracking-wider text-on-surface-variant"
                htmlFor="emailAddress"
              >
                Email Address
              </label>
              <input
                id="emailAddress"
                type="email"
                className="w-full bg-surface-container/20 border border-white/5 rounded-lg px-4 py-3 text-on-surface-variant font-body-md opacity-70 cursor-not-allowed"
                value={session?.user?.email || "N/A (Guest Session)"}
                disabled
                title="Email cannot be changed directly"
              />
            </div>
          </div>

          <div className="flex justify-end mt-4">
            <button
              className="bg-primary text-surface font-bold px-6 py-3 rounded-full hover:bg-primary-container transition-colors shadow-[0_10px_20px_rgba(245,158,11,0.2)] active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
              onClick={handleSaveProfile}
              disabled={saving || !name.trim()}
            >
              {saving ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Saving...
                </>
              ) : (
                "Save Changes"
              )}
            </button>
          </div>
        </section>

        {/* Appearance & Preferences */}
        <section className="glass-panel rounded-2xl p-6 md:p-8 flex flex-col gap-6">
          <div className="flex items-center gap-3 border-b border-white/10 pb-4">
            <PaletteIcon />
            <h2 className="font-headline-lg-mobile md:font-headline-lg text-[20px] md:text-[24px] font-bold text-on-surface">
              Appearance & UI
            </h2>
          </div>

          <div className="flex flex-col gap-4">
            <div className="font-body-md font-bold text-on-surface text-[16px]">
              Select Theme Preset
            </div>
            <div className="font-label-sm text-on-surface-variant text-[14px] mb-2">
              Choose your preferred dark mode aesthetic:
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <button
                onClick={() => handleThemeChange("theme-oled")}
                className={`p-4 rounded-xl border text-left flex flex-col gap-2 transition-all ${
                  theme === "theme-oled"
                    ? "border-primary bg-primary/10 shadow-[0_0_15px_rgba(245,158,11,0.1)]"
                    : "border-white/10 bg-white/5 hover:bg-white/10"
                }`}
              >
                <div className="w-full h-8 rounded bg-black border border-white/10 flex items-center justify-center">
                  <span className="w-3 h-3 rounded-full bg-primary"></span>
                </div>
                <div className="font-bold text-sm text-on-surface">
                  Lights Out (OLED)
                </div>
                <div className="text-[11px] text-on-surface-variant">
                  Pure pitch black pixels. Saves battery on OLED screens.
                </div>
              </button>

              <button
                onClick={() => handleThemeChange("theme-midnight")}
                className={`p-4 rounded-xl border text-left flex flex-col gap-2 transition-all ${
                  theme === "theme-midnight"
                    ? "border-primary bg-primary/10 shadow-[0_0_15px_rgba(245,158,11,0.1)]"
                    : "border-white/10 bg-white/5 hover:bg-white/10"
                }`}
              >
                <div className="w-full h-8 rounded bg-[#090d16] border border-white/10 flex items-center justify-center">
                  <span className="w-3 h-3 rounded-full bg-secondary"></span>
                </div>
                <div className="font-bold text-sm text-on-surface">
                  Midnight Space
                </div>
                <div className="text-[11px] text-on-surface-variant">
                  Deep cosmic space navy with glowing ambient accents.
                </div>
              </button>

              <button
                onClick={() => handleThemeChange("theme-slate")}
                className={`p-4 rounded-xl border text-left flex flex-col gap-2 transition-all ${
                  theme === "theme-slate"
                    ? "border-primary bg-primary/10 shadow-[0_0_15px_rgba(245,158,11,0.1)]"
                    : "border-white/10 bg-white/5 hover:bg-white/10"
                }`}
              >
                <div className="w-full h-8 rounded bg-[#121316] border border-white/10 flex items-center justify-center">
                  <span className="w-3 h-3 rounded-full bg-on-surface-variant"></span>
                </div>
                <div className="font-bold text-sm text-on-surface">
                  Modern Slate
                </div>
                <div className="text-[11px] text-on-surface-variant">
                  Neutral deep dark gray. Cool, minimal and professional.
                </div>
              </button>
            </div>
          </div>
        </section>

        {/* Notifications */}
        <section className="glass-panel rounded-2xl p-6 md:p-8 flex flex-col gap-6">
          <div className="flex items-center gap-3 border-b border-white/10 pb-4">
            <BellIcon />
            <h2 className="font-headline-lg-mobile md:font-headline-lg text-[20px] md:text-[24px] font-bold text-on-surface">
              Notifications
            </h2>
          </div>

          <div className="flex flex-col gap-6">
            <div className="flex items-center justify-between">
              <div className="flex flex-col gap-1">
                <div className="font-body-md font-bold text-on-surface text-[16px]">
                  Email Updates
                </div>
                <div className="font-label-sm text-on-surface-variant text-[14px]">
                  Receive emails about new features and recommendations
                </div>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  className="sr-only peer"
                  checked={notifications}
                  onChange={(e) => handleNotificationsChange(e.target.checked)}
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
            <h2 className="font-headline-lg-mobile md:font-headline-lg text-[20px] md:text-[24px] font-bold text-error">
              Danger Zone
            </h2>
          </div>
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
            <div className="flex flex-col gap-1">
              <p className="font-body-md font-bold text-on-surface text-[16px]">
                {session ? "Delete Account" : "Clear Watchlist & Settings"}
              </p>
              <p className="font-label-sm text-on-surface-variant text-[14px] max-w-md">
                {session
                  ? "Once you delete your account, your profile, credentials, and watchlist will be deleted permanently. This cannot be undone."
                  : "Clear all cached items, theme settings, guest profile details, and empty your watchlist from local storage."}
              </p>
            </div>
            <button
              onClick={handleDeleteOrClear}
              disabled={clearing}
              className="bg-error/10 border border-error/50 text-error font-bold px-6 py-3 rounded-full hover:bg-error hover:text-on-error transition-colors whitespace-nowrap active:scale-95 disabled:opacity-50"
            >
              {clearing
                ? "Processing..."
                : session
                  ? "Delete Account"
                  : "Clear Data"}
            </button>
          </div>
        </section>
      </div>
    </main>
  );
}
