<template>
  <main class="min-h-screen">
    <SiteNav />

    <!-- Hero -->
    <section class="max-w-[1120px] mx-auto px-5 grid md:grid-cols-2 gap-14 items-center py-20">
      <div class="text-center md:text-left">
        <h1 class="text-5xl md:text-7xl font-black leading-none tracking-tighter text-[#0f2b27] mb-5">
          Shared money management in one piggy.
        </h1>
        <p class="text-lg md:text-xl leading-relaxed text-[#4d7a73] mb-8">
          Sharable Piggy helps families, partners, and roommates manage household expenses and shopping lists together in one shared budgeting app.
        </p>
        <div class="flex gap-3 flex-wrap items-center justify-center md:justify-start">
          <a :href="iosStoreUrl"><img src="/badge-appstore.svg" alt="Download on the App Store" class="h-17 w-auto" /></a>
          <a :href="androidStoreUrl"><img src="/badge-playstore.png" alt="Get it on Google Play" class="h-24 w-auto" /></a>
        </div>
      </div>

      <!-- Phone mockup -->
      <div class="bg-white border border-[#d6eeea] rounded-[42px] p-5 shadow-[0_24px_80px_rgba(24,95,84,.14)]">
        <div class="rounded-[30px] bg-gradient-to-b from-[#f2fbf9] to-white p-7 min-h-[510px] border border-[#d6eeea]">
          <span class="inline-flex rounded-full px-3 py-2 bg-white border border-[#d6eeea] text-xs text-[#4d7a73] font-bold">🏠 Home Piggy</span>
          <div class="my-6 p-6 rounded-[26px] bg-[#3dbfa8] text-white">
            <small class="opacity-80">This month's spending</small>
            <strong class="block text-4xl mt-2">$482.00</strong>
          </div>
          <div class="flex flex-col gap-3">
            <div class="flex justify-between items-center bg-white border border-[#d6eeea] rounded-[18px] p-3.5">
              <div><b>Groceries</b><br><span class="text-[#4d7a73] text-xs">Milk, eggs, vegetables</span></div>
              <b>3 items</b>
            </div>
            <div class="flex justify-between items-center bg-white border border-[#d6eeea] rounded-[18px] p-3.5">
              <div><b>Lunch</b><br><span class="text-[#4d7a73] text-xs">Food · Today</span></div>
              <b>$24.00</b>
            </div>
            <div class="flex justify-between items-center bg-white border border-[#d6eeea] rounded-[18px] p-3.5">
              <div><b>Invite link</b><br><span class="text-[#4d7a73] text-xs">Share by QR or URL</span></div>
              <b>Share</b>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Features -->
    <section id="features" class="max-w-[1120px] mx-auto px-5 py-18">
      <h2 class="text-3xl md:text-5xl font-black tracking-tight text-[#0f2b27] mb-3">Everything shared households need, without the clutter.</h2>
      <p class="text-[#4d7a73] leading-relaxed mb-8">Keep each piggy separate and let invited members see the same shared lists.</p>
      <div class="grid md:grid-cols-3 gap-4">
        <article class="bg-white border border-[#d6eeea] rounded-[28px] p-6 shadow-[0_18px_50px_rgba(24,95,84,.08)]">
          <span class="text-4xl">🔗</span>
          <b class="block text-lg mt-3 mb-2">Invite links</b>
          <p class="text-[#4d7a73] text-sm leading-relaxed">Invite people to the right piggy with QR codes, shared URLs, and app links.</p>
        </article>
        <article class="bg-white border border-[#d6eeea] rounded-[28px] p-6 shadow-[0_18px_50px_rgba(24,95,84,.08)]">
          <span class="text-4xl">🧾</span>
          <b class="block text-lg mt-3 mb-2">Expense tracking</b>
          <p class="text-[#4d7a73] text-sm leading-relaxed">Review household spending by date, amount, and category.</p>
        </article>
        <article class="bg-white border border-[#d6eeea] rounded-[28px] p-6 shadow-[0_18px_50px_rgba(24,95,84,.08)]">
          <span class="text-4xl">🛒</span>
          <b class="block text-lg mt-3 mb-2">Shopping lists</b>
          <p class="text-[#4d7a73] text-sm leading-relaxed">Check off shared shopping items so nothing gets missed.</p>
        </article>
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
