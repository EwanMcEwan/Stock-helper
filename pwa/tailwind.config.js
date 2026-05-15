/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        bull: '#22c55e',
        bear: '#ef4444',
      },
    },
  },
  plugins: [],
}
