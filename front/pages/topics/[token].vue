<template>
  <main class="page">
    <SiteNav />
    <section class="invite-wrap">
      <div class="invite-card">
        <div class="pig">🐷</div>
        <h1>피기 구독 초대</h1>
        <p class="lead">누군가 Sharable Piggy 피기를 공유했어요. 앱에서 열어 함께 관리해 보세요.</p>
        <button class="button primary" type="button" @click="openApp">앱에서 열기</button>
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
  title: 'Sharable Piggy 초대',
  meta: [
    { name: 'description', content: '공유받은 Sharable Piggy 피기를 앱에서 열어 구독하세요.' },
    { property: 'og:title', content: 'Sharable Piggy 초대' },
    { property: 'og:description', content: '앱에서 피기 초대를 열고 함께 관리하세요.' }
  ]
}))

function openApp() {
  window.location.href = deepLink.value
  window.setTimeout(() => {
    window.location.href = storeUrl.value
  }, 1600)
}
</script>
