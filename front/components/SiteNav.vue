<template>
  <nav class="max-w-[1120px] mx-auto px-5 flex items-center justify-between py-5">
    <NuxtLink class="flex items-center gap-2.5 font-black no-underline text-[#0f2b27]" to="/">
      <img class="w-9 h-9 rounded-[13px] object-contain" src="/logo.png" alt="Sharable Piggy" />
      <span>Sharable Piggy</span>
    </NuxtLink>
    <div class="hidden md:flex gap-5 items-center">
      <NuxtLink class="text-sm no-underline text-[#4d7a73] font-bold" to="/#features">Features</NuxtLink>
      <NuxtLink class="text-sm no-underline text-[#4d7a73] font-bold" to="/privacy">Privacy Policy</NuxtLink>
      <NuxtLink class="text-sm no-underline text-[#4d7a73] font-bold" to="/terms">Terms</NuxtLink>
    </div>
  </nav>
</template>
