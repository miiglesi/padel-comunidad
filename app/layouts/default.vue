<template>
  <div class="min-h-screen flex flex-col bg-slate-50 text-slate-800">
    <header class="bg-brand-dark text-white shadow-md sticky top-0 z-30">
      <div class="max-w-4xl mx-auto px-4 py-3 flex items-center justify-between">
        <NuxtLink to="/" class="flex items-center gap-2 focus:outline-none focus:ring-2 focus:ring-brand-light rounded p-1">
          <span class="text-2xl" role="img" aria-label="Pelota de pádel">🎾</span>
          <span class="font-bold text-lg tracking-wide text-white">Pádel Comunidad</span>
        </NuxtLink>

        <div v-if="user" class="flex items-center gap-3">
          <span class="text-xs sm:text-sm text-brand-soft truncate max-w-[140px] sm:max-w-none">
            {{ user.email }}
          </span>
          <button
            type="button"
            @click="logout"
            class="px-3 py-1.5 text-xs font-semibold bg-emerald-800 hover:bg-emerald-700 text-white rounded transition focus:outline-none focus:ring-2 focus:ring-brand-light"
          >
            Salir
          </button>
        </div>
      </div>
    </header>

    <main class="flex-1 max-w-4xl w-full mx-auto p-4 sm:p-6">
      <slot />
    </main>

    <footer class="bg-slate-100 border-t border-slate-200 py-4 text-center text-xs text-slate-500">
      <p>Pádel Comunidad &copy; PWA Residencial</p>
    </footer>
  </div>
</template>

<script setup lang="ts">
const supabase = useSupabaseClient()
const user = useSupabaseUser()

const logout = async () => {
  await supabase.auth.signOut()
  await navigateTo('/login')
}
</script>
