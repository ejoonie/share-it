<template>
  <nav class="max-w-[1400px] mx-auto px-8 flex items-center justify-between py-8">
    <NuxtLink class="flex items-center gap-3 font-black no-underline text-[#064E3B] text-2xl" to="/">
      <picture>
        <source srcset="/logo.webp" type="image/webp" />
        <img class="w-12 h-12 rounded-[14px] object-contain" src="/logo.png" alt="Sharable Piggy" width="96" height="96" />
      </picture>
      <span>Sharable Piggy</span>
    </NuxtLink>
    <div class="hidden md:flex gap-8 items-center">
      <NuxtLink class="text-lg no-underline text-[#064E3B] font-bold" to="/#features">Features</NuxtLink>
      <NuxtLink class="text-lg no-underline text-[#064E3B] font-bold" to="/privacy">Privacy Policy</NuxtLink>
      <NuxtLink class="text-lg no-underline text-[#064E3B] font-bold" to="/terms">Terms</NuxtLink>
    </div>
  </nav>
</template>
