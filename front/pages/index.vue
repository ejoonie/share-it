<template>
  <main class="page">
    <SiteNav />
    <section class="container hero">
      <div>
        <span class="eyebrow">🐷 sharablepiggy.com</span>
        <h1>Shared money management in one piggy.</h1>
        <p class="lead">Sharable Piggy helps families, partners, and roommates manage household expenses and shopping lists together in one shared budgeting app.</p>
        <div class="actions">
          <a class="button primary" :href="androidStoreUrl">Google Play</a>
          <a class="button" :href="iosStoreUrl">App Store</a>
        </div>
        <p class="store-note">Shared links open through app links and deep links at the <b>/topics/:token</b> route.</p>
      </div>
      <div class="phone-card" aria-label="App screen preview">
        <div class="phone-screen">
          <span class="pill">🏠 Home Piggy</span>
          <div class="balance"><small>This month's spending</small><strong>$482.00</strong></div>
          <div class="list">
            <div class="item"><div><b>Groceries</b><br><span>Milk, eggs, vegetables</span></div><b>3 items</b></div>
            <div class="item"><div><b>Lunch</b><br><span>Food · Today</span></div><b>$24.00</b></div>
            <div class="item"><div><b>Invite link</b><br><span>Share by QR or URL</span></div><b>Share</b></div>
          </div>
        </div>
      </div>
    </section>
    <section id="features" class="container section">
      <h2>Everything shared households need, without the clutter.</h2>
      <p>Keep each piggy separate and let invited members see the same shared lists.</p>
      <div class="grid">
        <article class="feature"><span class="feature-icon">🔗</span><b>Invite links</b><p>Invite people to the right piggy with QR codes, shared URLs, and app links.</p></article>
        <article class="feature"><span class="feature-icon">🧾</span><b>Expense tracking</b><p>Review household spending by date, amount, and category.</p></article>
        <article class="feature"><span class="feature-icon">🛒</span><b>Shopping lists</b><p>Check off shared shopping items so nothing gets missed.</p></article>
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
