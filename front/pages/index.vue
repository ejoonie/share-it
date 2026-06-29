<template>
  <main class="page">
    <SiteNav />
    <section class="container hero">
      <div>
        <span class="eyebrow">🐷 sharablepiggy.com</span>
        <h1>함께 쓰는 돈 관리, 피기 하나로 끝.</h1>
        <p class="lead">Sharable Piggy는 가족, 커플, 룸메이트가 생활비 지출과 장보기 목록을 같이 보고 관리할 수 있는 공유 가계부 앱입니다.</p>
        <div class="actions">
          <a class="button primary" :href="androidStoreUrl">Google Play</a>
          <a class="button" :href="iosStoreUrl">App Store</a>
        </div>
        <p class="store-note">공유 링크는 <b>/topics/:token</b> 경로에서 앱 링크와 딥링크로 자동 연결됩니다.</p>
      </div>
      <div class="phone-card" aria-label="앱 화면 미리보기">
        <div class="phone-screen">
          <span class="pill">🏠 우리집 피기</span>
          <div class="balance"><small>이번 달 지출</small><strong>₩482,000</strong></div>
          <div class="list">
            <div class="item"><div><b>장보기</b><br><span>우유, 달걀, 채소</span></div><b>3개</b></div>
            <div class="item"><div><b>점심</b><br><span>식비 · 오늘</span></div><b>₩24,000</b></div>
            <div class="item"><div><b>초대 링크</b><br><span>QR 또는 URL 공유</span></div><b>공유</b></div>
          </div>
        </div>
      </div>
    </section>
    <section id="features" class="container section">
      <h2>공유 생활을 위해 필요한 기능만 담았어요.</h2>
      <p>피기별로 데이터를 분리하고 초대받은 사람과 같은 목록을 확인할 수 있습니다.</p>
      <div class="grid">
        <article class="feature"><span class="feature-icon">🔗</span><b>초대 링크</b><p>QR, 공유 URL, 앱 링크로 원하는 피기에 바로 초대합니다.</p></article>
        <article class="feature"><span class="feature-icon">🧾</span><b>지출 기록</b><p>날짜, 금액, 카테고리를 기준으로 생활비 흐름을 확인합니다.</p></article>
        <article class="feature"><span class="feature-icon">🛒</span><b>장보기 목록</b><p>함께 살 물건을 체크하며 누락 없이 준비합니다.</p></article>
      </div>
    </section>
    <SiteFooter />
  </main>
</template>

<script setup lang="ts">
const config = useRuntimeConfig()
const iosStoreUrl = config.public.iosStoreUrl
const androidStoreUrl = config.public.androidStoreUrl
</script>
