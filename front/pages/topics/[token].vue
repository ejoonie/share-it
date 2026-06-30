<template>
  <main class="min-h-screen">
    <SiteNav />
    <section class="grid place-items-center min-h-[calc(100vh-86px)] px-4 py-10">
      <div class="w-full max-w-[460px] text-center bg-white border border-[#d6eeea] rounded-[28px] p-8 shadow-[0_18px_50px_rgba(24,95,84,.08)]">
        <div class="text-7xl mb-4">🐷</div>
        <h1 class="text-2xl font-black text-[#0f2b27] mb-3">Piggy subscription invite</h1>
        <p class="text-[#4d7a73] leading-relaxed mb-6">Someone shared a Sharable Piggy with you. Open it in the app to start managing it together.</p>
        <button
          class="w-full bg-[#3dbfa8] hover:bg-[#2da090] text-white font-bold rounded-full py-3.5 px-6 mb-4 transition-colors cursor-pointer border-0"
          type="button"
          @click="openApp"
        >
          Open in app
        </button>
        <div class="flex gap-3 justify-center">
          <a :href="androidStoreUrl"><img src="/badge-playstore.png" alt="Get it on Google Play" class="h-10 w-auto" /></a>
          <a :href="iosStoreUrl"><img src="/badge-appstore.svg" alt="Download on the App Store" class="h-10 w-auto" /></a>
        </div>
        <p class="mt-4 px-3 py-3 rounded-xl bg-[#f2fbf9] text-[#4d7a73] text-xs break-all">token: {{ token }}</p>
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
const route = useRoute()
const config = useRuntimeConfig()
const token = computed(() => String(route.params.token || ''))
const iosStoreUrl = config.public.iosStoreUrl
const androidStoreUrl = config.public.androidStoreUrl
const storeUrl = computed(() => {
  if (import.meta.server) return androidStoreUrl
  return /iPhone|iPad|iPod/.test(navigator.userAgent) ? iosStoreUrl : androidStoreUrl
})
const deepLink = computed(() => `sharablepiggy://topics/${encodeURIComponent(token.value)}`)

useHead(() => ({
  title: 'Sharable Piggy invite',
  meta: [
    { name: 'description', content: 'Open your shared Sharable Piggy invite in the app.' },
    { property: 'og:title', content: 'Sharable Piggy invite' },
    { property: 'og:description', content: 'Open the piggy invite in the app and manage it together.' }
  ]
}))

function openApp() {
  window.location.href = deepLink.value
  window.setTimeout(() => {
    window.location.href = storeUrl.value
  }, 1600)
}
</script>
