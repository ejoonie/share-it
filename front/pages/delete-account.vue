<template>
  <main class="min-h-screen">
    <SiteNav />
    <section class="max-w-[1120px] mx-auto px-5 py-10 pb-20">
      <article class="max-w-[860px] mx-auto mt-8 bg-white border border-mint-100 rounded-[28px] p-8 shadow-[0_18px_50px_rgba(24,95,84,.08)]">
        <h1 class="text-4xl font-black text-black-900 mb-2">How to Delete Your Account</h1>
        <p class="text-black-900 text-sm mb-8">Last updated: July 15, 2026</p>

        <p class="text-black-900 leading-relaxed mb-8">
          You can permanently delete your Sharable Piggy account and all associated data at any time by following the steps below.
          This action is irreversible — all your piggies, entries, and account information will be removed from our servers.
        </p>

        <h2 class="text-xl font-bold text-black-900 mt-8 mb-4">Steps to delete your account</h2>
        <ol class="list-none space-y-4 mb-8">
          <li class="flex gap-4 items-start">
            <span class="flex-shrink-0 w-8 h-8 rounded-full bg-mint-500 text-white text-sm font-bold flex items-center justify-center">1</span>
            <div>
              <p class="text-black-900 font-semibold">Open the app and go to Settings</p>
              <p class="text-black-900 text-sm text-gray-500 mt-1">Tap the <strong>Settings</strong> tab at the bottom of the screen.</p>
            </div>
          </li>
          <li class="flex gap-4 items-start">
            <span class="flex-shrink-0 w-8 h-8 rounded-full bg-mint-500 text-white text-sm font-bold flex items-center justify-center">2</span>
            <div>
              <p class="text-black-900 font-semibold">Tap "My Account"</p>
              <p class="text-black-900 text-sm text-gray-500 mt-1">Under the Account section, tap <strong>My Account</strong> to open the account management screen.</p>
            </div>
          </li>
          <li class="flex gap-4 items-start">
            <span class="flex-shrink-0 w-8 h-8 rounded-full bg-mint-500 text-white text-sm font-bold flex items-center justify-center">3</span>
            <div>
              <p class="text-black-900 font-semibold">Tap "Delete Account"</p>
              <p class="text-black-900 text-sm text-gray-500 mt-1">At the bottom of the screen, tap the red <strong>Delete Account</strong> link.</p>
            </div>
          </li>
          <li class="flex gap-4 items-start">
            <span class="flex-shrink-0 w-8 h-8 rounded-full bg-mint-500 text-white text-sm font-bold flex items-center justify-center">4</span>
            <div>
              <p class="text-black-900 font-semibold">Confirm deletion</p>
              <p class="text-black-900 text-sm text-gray-500 mt-1">A confirmation dialog will appear. Tap <strong>Delete</strong> to permanently delete your account.</p>
            </div>
          </li>
        </ol>

        <h2 class="text-xl font-bold text-black-900 mt-8 mb-2">What gets deleted</h2>
        <ul class="list-disc list-inside space-y-1 text-black-900 leading-relaxed mb-8">
          <li>Your account and login credentials</li>
          <li>All piggies (shared budgets) you created</li>
          <li>All entries within those piggies</li>
          <li>Your piggy memberships and follow relationships</li>
        </ul>

        <h2 class="text-xl font-bold text-black-900 mt-8 mb-2">Contact us</h2>
        <p class="text-black-900 leading-relaxed">
          If you are unable to access the app or need assistance deleting your account, please contact us at
          <a href="mailto:support@sharablepiggy.com" class="text-mint-600 underline">support@sharablepiggy.com</a>.
          We will process your request within 7 business days.
        </p>
      </article>
    </section>
    <SiteFooter />
  </main>
</template>
