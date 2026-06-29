<template>
  <nav class="max-w-[1400px] mx-auto px-8 flex items-center justify-between py-8">
    <NuxtLink class="flex items-center gap-3 font-black no-underline text-[#0f2b27] text-2xl" to="/">
      <img class="w-12 h-12 rounded-[14px] object-contain" src="/logo.png" alt="Sharable Piggy" />
      <span>Sharable Piggy</span>
    </NuxtLink>
    <div class="hidden md:flex gap-8 items-center">
      <NuxtLink class="text-lg no-underline text-[#4d7a73] font-bold" to="/#features">Features</NuxtLink>
      <NuxtLink class="text-lg no-underline text-[#4d7a73] font-bold" to="/privacy">Privacy Policy</NuxtLink>
      <NuxtLink class="text-lg no-underline text-[#4d7a73] font-bold" to="/terms">Terms</NuxtLink>
    </div>
  </nav>
</template>
