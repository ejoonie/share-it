import tailwindcss from '@tailwindcss/vite'

export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },
  modules: ['@nuxtjs/sitemap'],
  css: ['~/assets/css/main.css'],
  site: {
    url: 'https://sharablepiggy.com',
    name: 'Sharable Piggy',
  },
  sitemap: {
    urls: ['/', '/privacy', '/terms'],
    exclude: ['/topics/**'],
  },
  vite: {
    plugins: [tailwindcss()],
  },
  ssr: true,
  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      title: 'Sharable Piggy – Shared expense & shopping list app',
      titleTemplate: '%s | Sharable Piggy',
      meta: [
        { name: 'description', content: 'Sharable Piggy helps families, partners, and roommates manage household expenses and shopping lists together in one shared budgeting app.' },
        { name: 'keywords', content: 'shared expenses, household budget, shopping list, family finance, roommate app, expense tracker' },
        { name: 'robots', content: 'index, follow' },
        { name: 'theme-color', content: '#3dbfa8' },
        // Open Graph
        { property: 'og:site_name', content: 'Sharable Piggy' },
        { property: 'og:type', content: 'website' },
        { property: 'og:title', content: 'Sharable Piggy – Shared expense & shopping list app' },
        { property: 'og:description', content: 'Sharable Piggy helps families, partners, and roommates manage household expenses and shopping lists together in one shared budgeting app.' },
        { property: 'og:url', content: 'https://sharablepiggy.com' },
        { property: 'og:image', content: 'https://sharablepiggy.com/og-image.png' },
        { property: 'og:image:width', content: '1024' },
        { property: 'og:image:height', content: '1024' },
        { property: 'og:locale', content: 'en_US' },
        // Twitter Card
        { name: 'twitter:card', content: 'summary' },
        { name: 'twitter:title', content: 'Sharable Piggy – Shared expense & shopping list app' },
        { name: 'twitter:description', content: 'Manage household expenses and shopping lists together in one shared budgeting app.' },
        { name: 'twitter:image', content: 'https://sharablepiggy.com/og-image.png' },
      ],
      link: [
        { rel: 'canonical', href: 'https://sharablepiggy.com' },
        { rel: 'icon', type: 'image/png', href: '/favicon.png' },
        { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' },
      ],
      script: [
        {
          type: 'application/ld+json',
          innerHTML: JSON.stringify({
            '@context': 'https://schema.org',
            '@type': 'MobileApplication',
            name: 'Sharable Piggy',
            url: 'https://sharablepiggy.com',
            description: 'Sharable Piggy helps families, partners, and roommates manage household expenses and shopping lists together.',
            applicationCategory: 'FinanceApplication',
            operatingSystem: 'iOS, Android',
            offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
          }),
        },
      ],
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
