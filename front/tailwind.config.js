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
          400: '#3dbfa8',
          500: '#2da090',
          900: '#0f2b27',
        },
      },
    },
  },
  plugins: [],
}
