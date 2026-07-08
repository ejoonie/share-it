<template>
  <main class="min-h-screen">
    <SiteNav />

    <!-- Hero -->
    <section class="max-w-[1400px] mx-auto px-8 grid md:grid-cols-2 gap-20 items-center pt-6 pb-12 md:py-28">
      <div class="text-left md:text-left">
        <h1 class="text-4xl md:text-8xl font-black leading-none tracking-tighter text-[#064E3B] mb-6">
          Shared money management in one piggy.
        </h1>
        <p class="text-xl md:text-2xl leading-relaxed text-[#064E3B] mb-10">
          Sharable Piggy helps families, partners, and roommates manage household expenses and shopping lists together in one shared budgeting app.
        </p>
        <div class="flex flex-row gap-3 items-center justify-center md:justify-start">
          <a :href="iosStoreUrl"><img src="/badge-appstore.svg" alt="Download on the App Store" class="h-13 md:h-17 w-auto" /></a>
          <a :href="androidStoreUrl">
            <picture>
              <source srcset="/badge-playstore.webp" type="image/webp" />
              <img src="/badge-playstore.png" alt="Get it on Google Play" class="h-18 md:h-25 w-auto" width="366" height="142" />
            </picture>
          </a>
        </div>
      </div>

      <!-- Phone mockup: desktop full, mobile compact -->
      <div class="bg-white border border-[#d6eeea] rounded-[32px] md:rounded-[48px] p-4 md:p-6 shadow-[0_32px_100px_rgba(24,95,84,.14)]">
        <div class="rounded-[22px] md:rounded-[36px] bg-gradient-to-b from-[#f2fbf9] to-white p-5 md:p-8 md:min-h-[580px] border border-[#d6eeea]">
          <span class="inline-flex rounded-full px-3 py-2 md:px-4 md:py-2.5 bg-white border border-[#d6eeea] text-xs md:text-sm text-[#064E3B] font-bold">🏠 Home Piggy</span>
          <div class="my-4 md:my-7 p-4 md:p-7 rounded-[20px] md:rounded-[28px] bg-[#10B981] text-[#052E2B]">
            <small class="opacity-80 text-xs md:text-sm">This month's spending</small>
            <strong class="block text-3xl md:text-5xl mt-1 md:mt-2">$482.00</strong>
          </div>
          <div class="flex flex-col gap-2.5 md:gap-3.5">
            <div class="flex justify-between items-center bg-white border border-[#d6eeea] rounded-[14px] md:rounded-[20px] p-3 md:p-4">
              <div><b class="text-sm md:text-base">Groceries</b><br><span class="text-[#064E3B] text-xs">Milk, eggs, vegetables</span></div>
              <b class="text-sm md:text-base">3 items</b>
            </div>
            <div class="flex justify-between items-center bg-white border border-[#d6eeea] rounded-[14px] md:rounded-[20px] p-3 md:p-4">
              <div><b class="text-sm md:text-base">Lunch</b><br><span class="text-[#064E3B] text-xs">Food · Today</span></div>
              <b class="text-sm md:text-base">$24.00</b>
            </div>
            <div class="flex justify-between items-center bg-white border border-[#d6eeea] rounded-[14px] md:rounded-[20px] p-3 md:p-4">
              <div><b class="text-sm md:text-base">Invite link</b><br><span class="text-[#064E3B] text-xs">Share by QR or URL</span></div>
              <b class="text-sm md:text-base">Share</b>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Features -->
    <section id="features" class="max-w-[1400px] mx-auto px-8 py-24">
      <h2 class="text-4xl md:text-6xl font-black tracking-tight text-[#064E3B] mb-4">Everything shared households need, without the clutter.</h2>
      <p class="text-xl text-[#064E3B] leading-relaxed mb-10">Keep each piggy separate and let invited members see the same shared lists.</p>
      <div class="grid md:grid-cols-3 gap-5">
        <article class="bg-white border border-[#d6eeea] rounded-[32px] p-8 shadow-[0_18px_50px_rgba(24,95,84,.08)]">
          <span class="text-5xl">🔗</span>
          <b class="block text-xl mt-4 mb-2">Invite links</b>
          <p class="text-[#064E3B] leading-relaxed">Invite people to the right piggy with QR codes, shared URLs, and app links.</p>
        </article>
        <article class="bg-white border border-[#d6eeea] rounded-[32px] p-8 shadow-[0_18px_50px_rgba(24,95,84,.08)]">
          <span class="text-5xl">🧾</span>
          <b class="block text-xl mt-4 mb-2">Expense tracking</b>
          <p class="text-[#064E3B] leading-relaxed">Review household spending by date, amount, and category.</p>
        </article>
        <article class="bg-white border border-[#d6eeea] rounded-[32px] p-8 shadow-[0_18px_50px_rgba(24,95,84,.08)]">
          <span class="text-5xl">🛒</span>
          <b class="block text-xl mt-4 mb-2">Shopping lists</b>
          <p class="text-[#064E3B] leading-relaxed">Check off shared shopping items so nothing gets missed.</p>
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
