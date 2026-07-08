<template>
  <footer class="border-t border-[#d6eeea]">
    <div class="max-w-[1120px] mx-auto px-5 py-10 flex flex-wrap justify-between gap-5 text-[#374151] text-sm">
      <span>© {{ year }} Sharable Piggy</span>
      <div class="flex gap-4">
        <NuxtLink class="font-bold no-underline text-[#111827] hover:underline" to="/privacy">Privacy</NuxtLink>
        <NuxtLink class="font-bold no-underline text-[#111827] hover:underline" to="/terms">Terms</NuxtLink>
      </div>
    </div>
  </footer>
</template>
<script setup lang="ts">
const year = new Date().getFullYear()
</script>
