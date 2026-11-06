<template>
  <main class="min-h-screen">
    <SiteNav />
    <section class="max-w-[1120px] mx-auto px-5 py-10 pb-20">
      <article class="max-w-[860px] mx-auto mt-8 bg-white border border-mint-100 rounded-[28px] p-8 shadow-[0_18px_50px_rgba(24,95,84,.08)]">
        <h1 class="text-4xl font-black text-black-900 mb-2">Privacy Policy</h1>
        <p class="text-black-900 text-sm mb-8">Effective date: November 6, 2026</p>
        <h2 class="text-xl font-bold text-black-900 mt-8 mb-2">1. Information we collect</h2>
        <p class="text-black-900 leading-relaxed">To provide the service, we may process login tokens, piggy and entry data, shared subscription status, and basic request information sent by your device.</p>
        <p class="text-black-900 leading-relaxed mt-4">For chat we store message text, the author’s account identifier, the associated transaction and shared piggy, and creation and update times. Membership information determines who can view a conversation. We also store blocking relationships and reports, including the reporter, reported author, reason, processing status, and a copy of the reported message. If you enable push notifications, we process device notification tokens to deliver activity updates.</p>
        <h2 class="text-xl font-bold text-black-900 mt-8 mb-2">2. How we use information</h2>
        <p class="text-black-900 leading-relaxed">We use information only to identify accounts, synchronize shared piggies, manage expenses and shopping lists, and improve service reliability.</p>
        <p class="text-black-900 leading-relaxed mt-4">We use chat information to deliver and synchronize conversations, enforce blocks, filter prohibited content, and review abuse reports. Authorized operators may review reported message copies and take action. Messages are visible to members with access to the shared piggy, subject to blocking rules. Push delivery uses Firebase Cloud Messaging.</p>
        <h2 class="text-xl font-bold text-black-900 mt-8 mb-2">3. Retention and deletion</h2>
        <p class="text-black-900 leading-relaxed">Messages remain stored until deleted by their author or removed with the author’s account or the permanent deletion of the associated transaction. Removing a piggy or transaction from view does not immediately erase its messages. Blocking does not delete messages. Reported message copies remain available for safety review after the original is deleted; we remove these copies within 90 days of a report being resolved. Deleting the reporter’s account removes reports submitted by that account. Deleting a reported author’s account removes its identifier from reports but does not immediately erase reported text, which may contain information entered by the author. Contact us to request removal of personal information in a report.</p>
        <h2 class="text-xl font-bold text-black-900 mt-8 mb-2">4. Contact</h2>
        <p class="text-black-900 leading-relaxed">For privacy questions or data removal requests, email <a href="mailto:support@sharablepiggy.com" class="underline">support@sharablepiggy.com</a>. See <NuxtLink to="/delete-account" class="underline">account deletion instructions</NuxtLink>.</p>
      </article>
    </section>
    <SiteFooter />
  </main>
</template>
