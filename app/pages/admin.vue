<template>
  <div class="space-y-8">
    <!-- Encabezado Admin -->
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
      <div>
        <div class="flex items-center gap-3">
          <NuxtLink to="/" class="text-brand hover:underline text-sm font-semibold flex items-center gap-1">
            &larr; Volver a Reservas
          </NuxtLink>
        </div>
        <h1 class="text-2xl font-bold text-slate-800 mt-2">Panel de Administración</h1>
        <p class="text-sm text-slate-500">Gestión de vecinos, viviendas y bloqueos de la pista</p>
      </div>

      <div class="flex items-center gap-2">
        <span class="inline-flex items-center px-3 py-1.5 rounded-full text-xs font-semibold bg-brand-pale text-brand-dark border border-brand-soft">
          🛡️ Modo Administrador
        </span>
      </div>
    </div>

    <!-- Mensajes -->
    <div v-if="adminError" class="p-4 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl flex items-center justify-between" role="alert">
      <span>{{ adminError }}</span>
      <button @click="adminError = ''" class="text-red-500 hover:text-red-700 font-bold">&times;</button>
    </div>

    <div v-if="adminSuccess" class="p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm rounded-xl flex items-center justify-between" role="alert">
      <span>{{ adminSuccess }}</span>
      <button @click="adminSuccess = ''" class="text-emerald-600 hover:text-emerald-800 font-bold">&times;</button>
    </div>

    <!-- Sección 1: Bloqueos de Pista (Mantenimiento / Eventos) -->
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200 space-y-6">
      <h2 class="text-lg font-bold text-slate-800 flex items-center gap-2">
        <span>🚫</span> Bloquear Pista (Mantenimiento, Obras, etc.)
      </h2>

      <form @submit.prevent="handleCreateBlock" class="grid grid-cols-1 sm:grid-cols-4 gap-4 items-end">
        <div>
          <label for="blockDate" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">Día</label>
          <input
            id="blockDate"
            v-model="blockDate"
            type="date"
            required
            class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-brand focus:border-brand"
          />
        </div>
        <div>
          <label for="blockStartTime" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">Hora Inicio (:00 o :30)</label>
          <input
            id="blockStartTime"
            v-model="blockStartTime"
            type="time"
            step="1800"
            required
            class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-brand focus:border-brand"
          />
        </div>
        <div>
          <label for="blockEndTime" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">Hora Fin (:00 o :30)</label>
          <input
            id="blockEndTime"
            v-model="blockEndTime"
            type="time"
            step="1800"
            required
            class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-brand focus:border-brand"
          />
        </div>
        <div>
          <label for="blockReason" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">Motivo</label>
          <input
            id="blockReason"
            v-model="blockReason"
            type="text"
            required
            placeholder="Pintura, Mantenimiento..."
            class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-brand focus:border-brand"
          />
        </div>

        <div class="sm:col-span-4 flex justify-end">
          <button
            type="submit"
            :disabled="blocking"
            class="px-4 py-2 bg-rose-700 hover:bg-rose-800 text-white font-medium rounded-lg text-sm shadow transition disabled:opacity-50"
          >
            <span v-if="blocking">Aplicando bloqueo...</span>
            <span v-else>Aplicar Bloqueo de Pista</span>
          </button>
        </div>
      </form>

      <!-- Lista de Bloqueos Activos -->
      <div class="border-t border-slate-100 pt-4">
        <h3 class="text-sm font-bold text-slate-700 mb-3">Bloqueos Registrados</h3>
        <div v-if="blocks.length === 0" class="text-xs text-slate-500 py-2">
          No hay bloqueos activos de pista.
        </div>
        <div v-else class="space-y-2">
          <div
            v-for="b in blocks"
            :key="b.id"
            class="flex items-center justify-between p-3 bg-rose-50/60 border border-rose-200 rounded-xl text-xs"
          >
            <div>
              <strong class="text-rose-900">{{ b.reason }}</strong>
              <span class="text-slate-600 ml-2">
                ({{ formatDateTime(b.start_time) }} - {{ formatDateTime(b.end_time) }})
              </span>
            </div>
            <button
              @click="handleRemoveBlock(b.id)"
              class="px-2.5 py-1 bg-white border border-rose-300 text-rose-700 hover:bg-rose-100 rounded font-semibold transition"
            >
              Desbloquear
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Sección 2: Gestión de Vecinos (Aprobar / Revocar / Corregir Vivienda) -->
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
      <div class="flex items-center justify-between mb-4 flex-wrap gap-2">
        <h2 class="text-lg font-bold text-slate-800 flex items-center gap-2">
          <span>👥</span> Vecinos y Permisos
        </h2>
        <button
          type="button"
          @click="loadProfiles"
          class="text-xs text-brand font-semibold hover:underline"
        >
          🔄 Recargar vecinos
        </button>
      </div>

      <div v-if="loadingProfiles" class="text-center py-6 text-sm text-slate-500">
        Cargando listado de perfiles...
      </div>

      <div v-else class="overflow-x-auto">
        <table class="w-full text-left text-sm text-slate-700">
          <thead class="bg-slate-50 text-xs uppercase text-slate-500 border-b">
            <tr>
              <th class="p-3">Vecino / Usuario</th>
              <th class="p-3">Email</th>
              <th class="p-3">Vivienda (B-P-P)</th>
              <th class="p-3">Estado</th>
              <th class="p-3 text-right">Acciones</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr v-for="p in profilesList" :key="p.id" class="hover:bg-slate-50/70">
              <td class="p-3">
                <span class="font-semibold block text-slate-900">{{ p.full_name || 'Sin nombre' }}</span>
                <span class="text-xs text-slate-400">@{{ p.username }}</span>
              </td>
              <td class="p-3 text-xs text-slate-600">{{ p.email }}</td>
              <td class="p-3">
                <div v-if="editingDwellingId === p.id" class="flex items-center gap-1">
                  <input v-model="editBlock" placeholder="Blq" class="w-12 px-1 py-0.5 text-xs border rounded" />
                  <input v-model="editFloor" placeholder="Piso" class="w-12 px-1 py-0.5 text-xs border rounded" />
                  <input v-model="editDoor" placeholder="Pta" class="w-12 px-1 py-0.5 text-xs border rounded" />
                  <button @click="saveDwelling(p.id)" class="px-2 py-0.5 bg-brand text-white text-xs rounded">✓</button>
                  <button @click="editingDwellingId = null" class="px-2 py-0.5 bg-slate-200 text-xs rounded">✕</button>
                </div>
                <div v-else class="flex items-center gap-2">
                  <span class="font-medium">Blq {{ p.block }}, {{ p.floor }}º {{ p.door }}</span>
                  <button
                    @click="startEditDwelling(p)"
                    title="Corregir vivienda"
                    class="text-xs text-brand hover:underline"
                  >
                    ✏️
                  </button>
                </div>
              </td>
              <td class="p-3">
                <span
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold"
                  :class="p.status === 'approved' ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800'"
                >
                  {{ p.status === 'approved' ? 'Aprobado' : 'Revocado' }}
                </span>
              </td>
              <td class="p-3 text-right">
                <button
                  v-if="p.status === 'approved'"
                  @click="setUserStatus(p.id, 'revoked')"
                  class="px-2.5 py-1 text-xs font-semibold bg-white border border-rose-300 text-rose-700 hover:bg-rose-50 rounded shadow-sm"
                >
                  Revocar
                </button>
                <button
                  v-else
                  @click="setUserStatus(p.id, 'approved')"
                  class="px-2.5 py-1 text-xs font-semibold bg-white border border-emerald-300 text-emerald-700 hover:bg-emerald-50 rounded shadow-sm"
                >
                  Reactivar
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Database, UserStatus } from '~/types/database'

type ProfileRow = Database['public']['Tables']['profiles']['Row']
type BlockRow = Database['public']['Tables']['court_blocks']['Row']

const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()

const adminError = ref('')
const adminSuccess = ref('')
const loadingProfiles = ref(false)
const blocking = ref(false)

const profilesList = ref<ProfileRow[]>([])
const blocks = ref<BlockRow[]>([])

// Formulario de bloqueo
const now = new Date()
const pad = (n: number) => String(n).padStart(2, '0')
const blockDate = ref(`${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`)
const blockStartTime = ref('08:00')
const blockEndTime = ref('12:00')
const blockReason = ref('')

// Edición de vivienda
const editingDwellingId = ref<string | null>(null)
const editBlock = ref('')
const editFloor = ref('')
const editDoor = ref('')

const formatDateTime = (isoString: string) => {
  const d = new Date(isoString)
  return `${d.toLocaleDateString([], { day: '2-digit', month: '2-digit' })} ${d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`
}

const checkAdminAccess = async () => {
  if (!user.value) {
    await navigateTo('/login')
    return false
  }

  const { data: isAdmin } = await supabase.rpc('is_admin')
  if (!isAdmin) {
    await navigateTo('/')
    return false
  }
  return true
}

const loadProfiles = async () => {
  loadingProfiles.value = true
  adminError.value = ''

  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      adminError.value = error.message
      return
    }

    profilesList.value = data || []
  } finally {
    loadingProfiles.value = false
  }
}

const loadBlocks = async () => {
  const { data, error } = await supabase
    .from('court_blocks')
    .select('*')
    .order('start_time', { ascending: true })

  if (!error && data) {
    blocks.value = data
  }
}

const handleCreateBlock = async () => {
  adminError.value = ''
  adminSuccess.value = ''
  blocking.value = true

  try {
    const [startH, startM] = blockStartTime.value.split(':').map(Number)
    const [endH, endM] = blockEndTime.value.split(':').map(Number)

    const start = new Date(`${blockDate.value}T00:00:00`)
    start.setHours(startH, startM, 0, 0)

    const end = new Date(`${blockDate.value}T00:00:00`)
    end.setHours(endH, endM, 0, 0)

    const { error } = await supabase.rpc('create_court_block', {
      p_start_time: start.toISOString(),
      p_end_time: end.toISOString(),
      p_reason: blockReason.value
    })

    if (error) {
      adminError.value = error.message
      return
    }

    adminSuccess.value = 'Pista bloqueada correctamente. Se han liberado reservas en conflicto.'
    blockReason.value = ''
    await loadBlocks()
  } catch (err: unknown) {
    if (err instanceof Error) {
      adminError.value = err.message
    }
  } finally {
    blocking.value = false
  }
}

const handleRemoveBlock = async (id: string) => {
  if (!confirm('¿Deseas desbloquear este horario de la pista?')) return

  adminError.value = ''
  adminSuccess.value = ''

  const { error } = await supabase.rpc('remove_court_block', {
    p_block_id: id
  })

  if (error) {
    adminError.value = error.message
    return
  }

  adminSuccess.value = 'Bloqueo eliminado.'
  await loadBlocks()
}

const setUserStatus = async (userId: string, newStatus: UserStatus) => {
  adminError.value = ''
  adminSuccess.value = ''

  const { error } = await supabase.rpc('admin_set_user_status', {
    p_user_id: userId,
    p_status: newStatus
  })

  if (error) {
    adminError.value = error.message
    return
  }

  adminSuccess.value = `Usuario actualizado a estado ${newStatus}.`
  await loadProfiles()
}

const startEditDwelling = (p: ProfileRow) => {
  editingDwellingId.value = p.id
  editBlock.value = p.block
  editFloor.value = p.floor
  editDoor.value = p.door
}

const saveDwelling = async (userId: string) => {
  adminError.value = ''
  adminSuccess.value = ''

  const { error } = await supabase.rpc('admin_update_dwelling', {
    p_user_id: userId,
    p_block: editBlock.value.trim(),
    p_floor: editFloor.value.trim(),
    p_door: editDoor.value.trim().toUpperCase()
  })

  if (error) {
    adminError.value = error.message
    return
  }

  adminSuccess.value = 'Vivienda actualizada correctamente.'
  editingDwellingId.value = null
  await loadProfiles()
}

onMounted(async () => {
  const allowed = await checkAdminAccess()
  if (allowed) {
    await Promise.all([loadProfiles(), loadBlocks()])
  }
})
</script>
