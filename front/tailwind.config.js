/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './components/**/*.{vue,js,ts}',
    './pages/**/*.{vue,js,ts}',
    './app.vue',
  ],
  theme: {
    extend: {
      colors: {
        mint: {
          50:  '#f2fbf9',
          100: '#d6eeea',
          500: '#10B981',
          600: '#059669',
          900: '#064E3B',
          950: '#052E2B',
        },
      },
    },
  },
  plugins: [],
}
