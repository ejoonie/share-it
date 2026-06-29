<template>
  <main class="page">
    <SiteNav />
    <section class="invite-wrap">
      <div class="invite-card">
        <div class="pig">🐷</div>
        <h1>Piggy subscription invite</h1>
        <p class="lead">Someone shared a Sharable Piggy with you. Open it in the app to start managing it together.</p>
        <button class="button primary" type="button" @click="openApp">Open in app</button>
        <div class="download-grid">
          <a class="button" :href="androidStoreUrl">Google Play</a>
          <a class="button" :href="iosStoreUrl">App Store</a>
        </div>
        <p class="token">token: {{ token }}</p>
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
