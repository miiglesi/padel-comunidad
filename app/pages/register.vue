<template>
  <div class="bg-white p-6 sm:p-8 rounded-2xl shadow-xl border border-emerald-100">
    <div class="text-center mb-6">
      <span class="text-4xl inline-block mb-2" role="img" aria-label="Pádel">🎾</span>
      <h1 class="text-2xl font-bold text-brand-dark">Alta de Vecino</h1>
      <p class="text-sm text-slate-500 mt-1">Crea tu cuenta con los datos de tu vivienda</p>
    </div>

    <form @submit.prevent="handleRegister" class="space-y-4">
      <div v-if="errorMessage" class="p-3 bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg" role="alert">
        {{ errorMessage }}
      </div>

      <div v-if="successMessage" class="p-3 bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm rounded-lg" role="alert">
        {{ successMessage }}
      </div>

      <div>
        <label for="fullName" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
          Nombre completo
        </label>
        <input
          id="fullName"
          v-model="fullName"
          type="text"
          required
          placeholder="Juan Pérez"
          class="w-full px-3 py-2 border border-slate-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-brand focus:border-brand text-sm"
        />
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div>
          <label for="username" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
            Usuario
          </label>
          <input
            id="username"
            v-model="username"
            type="text"
            required
            placeholder="juanp"
            class="w-full px-3 py-2 border border-slate-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-brand focus:border-brand text-sm"
          />
        </div>
        <div>
          <label for="email" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
            Email
          </label>
          <input
            id="email"
            v-model="email"
            type="email"
            required
            autocomplete="email"
            placeholder="juan@ejemplo.es"
            class="w-full px-3 py-2 border border-slate-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-brand focus:border-brand text-sm"
          />
        </div>
      </div>

      <div class="p-3 bg-emerald-50/50 rounded-xl border border-emerald-100">
        <span class="block text-xs font-bold text-brand-dark uppercase tracking-wider mb-2">
          Datos de la Vivienda
        </span>
        <div class="grid grid-cols-3 gap-2">
          <div>
            <label for="block" class="block text-xs text-slate-600 mb-1">Bloque / Portal</label>
            <input
              id="block"
              v-model="block"
              type="text"
              required
              placeholder="1"
              class="w-full px-2.5 py-1.5 border border-slate-300 rounded-lg text-sm focus:ring-brand focus:border-brand"
            />
          </div>
          <div>
            <label for="floor" class="block text-xs text-slate-600 mb-1">Planta / Piso</label>
            <input
              id="floor"
              v-model="floor"
              type="text"
              required
              placeholder="3"
              class="w-full px-2.5 py-1.5 border border-slate-300 rounded-lg text-sm focus:ring-brand focus:border-brand"
            />
          </div>
          <div>
            <label for="door" class="block text-xs text-slate-600 mb-1">Puerta</label>
            <input
              id="door"
              v-model="door"
              type="text"
              required
              placeholder="B"
              class="w-full px-2.5 py-1.5 border border-slate-300 rounded-lg text-sm focus:ring-brand focus:border-brand"
            />
          </div>
        </div>
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
          minlength="6"
          autocomplete="new-password"
          placeholder="Mínimo 6 caracteres"
          class="w-full px-3 py-2 border border-slate-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-brand focus:border-brand text-sm"
        />
      </div>

      <button
        type="submit"
        :disabled="loading"
        class="w-full py-2.5 px-4 bg-brand hover:bg-brand-dark text-white font-medium rounded-lg shadow transition duration-150 ease-in-out disabled:opacity-50 text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand"
      >
        <span v-if="loading">Registrando...</span>
        <span v-else>Completar Registro</span>
      </button>
    </form>

    <div class="mt-6 text-center text-sm text-slate-600">
      ¿Ya estás registrado?
      <NuxtLink to="/login" class="text-brand font-semibold hover:underline ml-1">
        Inicia sesión
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: 'auth'
})

const supabase = useSupabaseClient()
const fullName = ref('')
const username = ref('')
const email = ref('')
const block = ref('')
const floor = ref('')
const door = ref('')
const password = ref('')

const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

const handleRegister = async () => {
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const { data, error } = await supabase.auth.signUp({
      email: email.value,
      password: password.value,
      options: {
        data: {
          full_name: fullName.value,
          username: username.value.trim().toLowerCase(),
          block: block.value.trim(),
          floor: floor.value.trim(),
          door: door.value.trim().toUpperCase()
        }
      }
    })

    if (error) {
      errorMessage.value = error.message
      return
    }

    if (data.session) {
      await navigateTo('/')
    } else {
      successMessage.value = 'Registro exitoso. Revisa tu correo o inicia sesión.'
      setTimeout(() => {
        navigateTo('/login')
      }, 1500)
    }
  } catch (err: unknown) {
    if (err instanceof Error) {
      errorMessage.value = err.message
    } else {
      errorMessage.value = 'Error durante el registro'
    }
  } finally {
    loading.value = false
  }
}
</script>
