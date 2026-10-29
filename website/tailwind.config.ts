import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  future: {
    hoverOnlyWhenSupported: true,
  },
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        "primary-fixed-dim": "#ffb95f",
        "tertiary": "#cecbce",
        "surface-variant": "#2e3545",
        "on-error-container": "#ffdad6",
        "secondary-fixed-dim": "#ffb0cd",
        "surface-container-lowest": "#070e1d",
        "on-background": "#dce2f7",
        "on-primary-container": "#613b00",
        "surface-container-highest": "#2e3545",
        "inverse-surface": "#dce2f7",
        "secondary": "#ffb0cd",
        "primary-fixed": "#ffddb8",
        "surface-container-low": "#141b2b",
        "surface-tint": "#ffb95f",
        "on-tertiary-container": "#444346",
        "on-secondary-container": "#ffbad3",
        "on-primary-fixed": "#2a1700",
        "outline-variant": "#534434",
        "tertiary-fixed": "#e5e1e4",
        "on-primary-fixed-variant": "#653e00",
        "tertiary-fixed-dim": "#c8c6c8",
        "outline": "#a08e7a",
        "inverse-primary": "#855300",
        "error-container": "#93000a",
        "on-primary": "#472a00",
        "surface-container": "#191f2f",
        "on-tertiary-fixed-variant": "#474649",
        "surface": "#000000",
        "on-tertiary-fixed": "#1c1b1d",
        "secondary-container": "#aa0266",
        "surface-bright": "#323949",
        "surface-container-high": "#232a3a",
        "primary-container": "#f59e0b",
        "on-secondary-fixed-variant": "#8c0053",
        "inverse-on-surface": "#293040",
        "on-secondary-fixed": "#3e0022",
        "background": "#000000",
        "error": "#ffb4ab",
        "tertiary-container": "#b3b0b3",
        "on-secondary": "#640039",
        "on-surface": "#dce2f7",
        "on-surface-variant": "#d8c3ad",
        "on-tertiary": "#313032",
        "on-error": "#690005",
        "primary": "#ffc174",
        "surface-dim": "#000000",
        "secondary-fixed": "#ffd9e4"
      },
      borderRadius: {
        "DEFAULT": "0.25rem",
        "lg": "0.5rem",
        "xl": "0.75rem",
        "full": "9999px"
      },
      spacing: {
        "unit": "8px",
        "container-max": "1440px",
        "margin-mobile": "20px",
        "gutter": "24px",
        "margin-desktop": "64px"
      },
      fontFamily: {
        "body-md": ["var(--font-inter)", "sans-serif"],
        "headline-lg": ["var(--font-outfit)", "sans-serif"],
        "display-xl": ["var(--font-outfit)", "sans-serif"],
        "display-xl-mobile": ["var(--font-outfit)", "sans-serif"],
        "headline-lg-mobile": ["var(--font-outfit)", "sans-serif"],
        "label-sm": ["var(--font-inter)", "sans-serif"]
      },
      fontSize: {
        "body-md": ["16px", { "lineHeight": "1.6", "letterSpacing": "0em", "fontWeight": "400" }],
        "headline-lg": ["32px", { "lineHeight": "1.2", "letterSpacing": "-0.01em", "fontWeight": "600" }],
        "display-xl": ["64px", { "lineHeight": "1.1", "letterSpacing": "-0.02em", "fontWeight": "700" }],
        "display-xl-mobile": ["40px", { "lineHeight": "1.1", "letterSpacing": "-0.02em", "fontWeight": "700" }],
        "headline-lg-mobile": ["24px", { "lineHeight": "1.2", "fontWeight": "600" }],
        "label-sm": ["12px", { "lineHeight": "1", "letterSpacing": "0.05em", "fontWeight": "600" }]
      }
    },
  },
  plugins: [],
};

export default config;
