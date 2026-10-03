<template>
  <div class="flex flex-col items-center justify-center min-h-[60vh] text-center p-6">
    <div class="animate-spin text-4xl mb-4">🎾</div>
    <h1 class="text-xl font-bold text-brand-dark mb-2">Confirmando tu sesión...</h1>
    <p class="text-sm text-slate-500">Por favor, espera unos segundos.</p>
  </div>
</template>

<script setup lang="ts">
const user = useSupabaseUser()

watch(
  user,
  () => {
    if (user.value) {
      navigateTo('/')
    }
  },
  { immediate: true }
)
</script>
