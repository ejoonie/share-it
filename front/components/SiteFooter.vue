<template>
  <footer class="footer">
    <div class="container footer-inner">
      <div>© {{ year }} Sharable Piggy</div>
      <div><NuxtLink to="/privacy">Privacy</NuxtLink><NuxtLink to="/terms">Terms</NuxtLink></div>
    </div>
  </footer>
</template>
<script setup lang="ts">
const year = new Date().getFullYear()
</script>
