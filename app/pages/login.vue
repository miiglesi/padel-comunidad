<template>
  <div class="bg-white p-6 sm:p-8 rounded-2xl shadow-xl border border-emerald-100">
    <div class="text-center mb-6">
      <span class="text-4xl inline-block mb-2" role="img" aria-label="Pádel">🎾</span>
      <h1 class="text-2xl font-bold text-brand-dark">Pádel Comunidad</h1>
      <p class="text-sm text-slate-500 mt-1">Inicia sesión para reservar la pista</p>
    </div>

    <form @submit.prevent="handleLogin" class="space-y-4">
      <div v-if="errorMessage" class="p-3 bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg" role="alert">
        {{ errorMessage }}
      </div>

      <div>
        <label for="email" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
          Correo electrónico
        </label>
        <input
          id="email"
          v-model="email"
          type="email"
          required
          autocomplete="email"
          placeholder="vecino@comunidad.es"
          class="w-full px-3 py-2 border border-slate-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-brand focus:border-brand text-sm"
        />
      </div>

      <div>
        <label for="password" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
          Contraseña
        </label>
        <input
          id="password"
          v-model="password"
          type="password"
          required
          autocomplete="current-password"
          placeholder="••••••••"
          class="w-full px-3 py-2 border border-slate-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-brand focus:border-brand text-sm"
        />
      </div>

      <button
        type="submit"
        :disabled="loading"
        class="w-full py-2.5 px-4 bg-brand hover:bg-brand-dark text-white font-medium rounded-lg shadow transition duration-150 ease-in-out disabled:opacity-50 text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand"
      >
        <span v-if="loading">Entrando...</span>
        <span v-else>Iniciar sesión</span>
      </button>
    </form>

    <div class="mt-6 text-center text-sm text-slate-600">
      ¿No tienes cuenta?
      <NuxtLink to="/register" class="text-brand font-semibold hover:underline ml-1">
        Regístrate aquí
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: 'auth'
})

const supabase = useSupabaseClient()
const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')

const handleLogin = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const { error } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })

    if (error) {
      errorMessage.value = error.message
      return
    }

    await navigateTo('/')
  } catch (err: unknown) {
    if (err instanceof Error) {
      errorMessage.value = err.message
    } else {
      errorMessage.value = 'Ha ocurrido un error inesperado'
    }
  } finally {
    loading.value = false
  }
}
</script>
