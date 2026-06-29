export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },
  css: ['~/assets/css/main.css'],
  ssr: true,
  app: {
    head: {
      htmlAttrs: { lang: 'ko' },
      title: 'Sharable Piggy',
      meta: [
        { name: 'description', content: '함께 쓰는 생활비와 장보기 목록을 피기 하나로 공유하세요.' },
        { property: 'og:site_name', content: 'Sharable Piggy' },
        { property: 'og:type', content: 'website' },
        { property: 'og:title', content: 'Sharable Piggy' },
        { property: 'og:description', content: '가족, 커플, 룸메이트와 지출과 장보기를 쉽게 공유하는 앱입니다.' },
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
