import tailwindcss from '@tailwindcss/vite'

export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },
  css: ['~/assets/css/main.css'],
  vite: {
    plugins: [tailwindcss()],
  },
  ssr: true,
  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      title: 'Sharable Piggy',
      meta: [
        { name: 'description', content: 'Share household expenses and shopping lists in one shared piggy.' },
        { property: 'og:site_name', content: 'Sharable Piggy' },
        { property: 'og:type', content: 'website' },
        { property: 'og:title', content: 'Sharable Piggy' },
        { property: 'og:description', content: 'A simple app for sharing expenses and shopping lists with family, partners, and roommates.' },
        { property: 'og:url', content: 'https://sharablepiggy.com' },
        { name: 'theme-color', content: '#ff6b35' }
      ],
      link: [{ rel: 'canonical', href: 'https://sharablepiggy.com' }]
    }
  },
  nitro: {
    prerender: {
      crawlLinks: true,
      routes: ['/', '/topics/demo_abc123', '/privacy', '/terms']
    }
  },
  runtimeConfig: {
    public: {
      apiBaseUrl: process.env.NUXT_PUBLIC_API_BASE_URL || 'https://api.sharablepiggy.com',
      siteUrl: process.env.NUXT_PUBLIC_SITE_URL || 'https://sharablepiggy.com',
      iosStoreUrl: process.env.NUXT_PUBLIC_IOS_STORE_URL || 'https://apps.apple.com/app/idXXXXXXXXX',
      androidStoreUrl:
        process.env.NUXT_PUBLIC_ANDROID_STORE_URL ||
        'https://play.google.com/store/apps/details?id=com.example.share_it'
    }
  }
})
