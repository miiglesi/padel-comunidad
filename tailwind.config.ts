/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './app/components/**/*.{vue,js,ts}',
    './app/layouts/**/*.vue',
    './app/pages/**/*.vue',
    './app/composables/**/*.{js,ts}',
    './app/plugins/**/*.{js,ts}',
    './app/app.{js,ts,vue}',
    './app.vue'
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          dark: '#1b4332',
          DEFAULT: '#2d6a4f',
          medium: '#40916c',
          light: '#74c69d',
          soft: '#b7e4c7',
          pale: '#d8f3dc'
        }
      }
    }
  },
  plugins: []
}
