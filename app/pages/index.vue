<template>
  <div class="space-y-8">
    <!-- Encabezado y bienvenida -->
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <h1 class="text-2xl font-bold text-slate-800">Reserva de Pista</h1>
          <NuxtLink
            v-if="profile?.role === 'admin'"
            to="/admin"
            class="px-2.5 py-1 text-xs font-semibold bg-brand-dark hover:bg-brand text-white rounded-md shadow-sm transition"
          >
            Panel de Administración ⚙️
          </NuxtLink>
        </div>
        <p class="text-sm text-slate-500 mt-1">
          Vivienda asignada: <strong class="text-slate-700">Bloque {{ profile?.block || '-' }}, {{ profile?.floor || '-' }}º {{ profile?.door || '-' }}</strong>
        </p>
      </div>

      <div class="flex items-center gap-2">
        <span
          v-if="profile?.status === 'approved'"
          class="inline-flex items-center px-3 py-1.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800 border border-emerald-200"
        >
          ● Acceso Habilitado
        </span>
        <span
          v-else
          class="inline-flex items-center px-3 py-1.5 rounded-full text-xs font-semibold bg-rose-100 text-rose-800 border border-rose-200"
        >
          ● Acceso Revocado
        </span>
      </div>
    </div>

    <!-- Alertas informativas / errores -->
    <div v-if="actionError" class="p-4 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl flex items-center justify-between" role="alert">
      <span>{{ actionError }}</span>
      <button @click="actionError = ''" class="text-red-500 hover:text-red-700 text-base font-bold ml-3">&times;</button>
    </div>

    <div v-if="actionSuccess" class="p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm rounded-xl flex items-center justify-between" role="alert">
      <span>{{ actionSuccess }}</span>
      <button @click="actionSuccess = ''" class="text-emerald-600 hover:text-emerald-800 text-base font-bold ml-3">&times;</button>
    </div>

    <!-- Reglas y resumen -->
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <div class="bg-emerald-50/70 p-4 rounded-xl border border-emerald-100">
        <span class="text-xs uppercase font-bold text-brand block mb-1">Ventana 24 Horas</span>
        <p class="text-sm text-slate-700 font-medium">Solo disponible hoy y mañana en 24h</p>
      </div>
      <div class="bg-emerald-50/70 p-4 rounded-xl border border-emerald-100">
        <span class="text-xs uppercase font-bold text-brand block mb-1">Límite Diario</span>
        <p class="text-sm text-slate-700 font-medium">120 min acumulados por vivienda</p>
      </div>
      <div class="bg-emerald-50/70 p-4 rounded-xl border border-emerald-100">
        <span class="text-xs uppercase font-bold text-brand block mb-1">Duración Reserva</span>
        <p class="text-sm text-slate-700 font-medium">De 30 a 120 minutos</p>
      </div>
    </div>

    <!-- Crear Reserva Nueva -->
    <div v-if="profile?.status === 'approved'" class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
      <h2 class="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2">
        <span>🎾</span> Nueva Reserva Directa
      </h2>

      <form @submit.prevent="handleCreateReservation" class="space-y-4">
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <label for="resDate" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">Día</label>
            <input
              id="resDate"
              v-model="resDate"
              type="date"
              required
              class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-brand focus:border-brand"
            />
          </div>
          <div>
            <label for="resTime" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">Hora Inicio (en :00 o :30)</label>
            <input
              id="resTime"
              v-model="resTime"
              type="time"
              step="1800"
              required
              class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-brand focus:border-brand"
            />
          </div>
          <div>
            <label for="duration" class="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">Duración</label>
            <select
              id="duration"
              v-model.number="resDuration"
              class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-brand focus:border-brand"
            >
              <option :value="30">30 minutos</option>
              <option :value="60">60 minutos (1 hora)</option>
              <option :value="90">90 minutos (1 hora y media)</option>
              <option :value="120">120 minutos (2 horas)</option>
            </select>
          </div>
        </div>

        <div class="flex justify-end">
          <button
            type="submit"
            :disabled="reserving"
            class="px-5 py-2.5 bg-brand hover:bg-brand-dark text-white font-medium rounded-lg text-sm shadow transition disabled:opacity-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand"
          >
            <span v-if="reserving">Validando y reservando...</span>
            <span v-else>Confirmar Reserva</span>
          </button>
        </div>
      </form>
    </div>

    <!-- Lista de Franjas y Reservas Próximas 24 Horas -->
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-bold text-slate-800">Ocupación de la Pista (Próximas 24 Horas)</h2>
        <button
          type="button"
          @click="loadSchedule"
          class="text-xs text-brand font-semibold hover:underline flex items-center gap-1"
        >
          🔄 Actualizar
        </button>
      </div>

      <div v-if="loadingSchedule" class="text-center py-8 text-sm text-slate-500">
        Cargando estado de la pista...
      </div>

      <div v-else-if="scheduleItems.length === 0" class="text-center py-8 text-sm text-slate-500">
        No hay reservas ni bloqueos en las próximas 24 horas. ¡La pista está disponible!
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="item in scheduleItems"
          :key="item.id"
          class="p-4 rounded-xl border flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3"
          :class="{
            'bg-rose-50 border-rose-200': item.type === 'block',
            'bg-emerald-50/50 border-emerald-200': item.type === 'reservation' && item.userId === user?.id,
            'bg-slate-50 border-slate-200': item.type === 'reservation' && item.userId !== user?.id
          }"
        >
          <div>
            <div class="flex items-center gap-2">
              <span
                class="px-2 py-0.5 rounded text-xs font-bold"
                :class="{
                  'bg-rose-600 text-white': item.type === 'block',
                  'bg-brand text-white': item.type === 'reservation' && item.userId === user?.id,
                  'bg-slate-600 text-white': item.type === 'reservation' && item.userId !== user?.id
                }"
              >
                {{ item.type === 'block' ? 'BLOQUEO ADMIN' : (item.userId === user?.id ? 'TU RESERVA' : 'RESERVADA') }}
              </span>
              <span class="text-sm font-semibold text-slate-800">
                {{ formatDateTime(item.startTime) }} - {{ formatDateTime(item.endTime) }}
              </span>
            </div>

            <p class="text-xs text-slate-600 mt-1">
              <span v-if="item.type === 'block'">
                Motivo: <em>{{ item.reason }}</em>
              </span>
              <span v-else>
                Vivienda: Bloque {{ item.block }}, {{ item.floor }}º {{ item.door }}
              </span>
            </p>
          </div>

          <!-- Botón de cancelación -->
          <button
            v-if="item.type === 'reservation' && (item.userId === user?.id || profile?.role === 'admin')"
            @click="handleCancel(item.id)"
            :disabled="cancellingId === item.id"
            class="px-3 py-1.5 text-xs font-semibold bg-white border border-rose-300 text-rose-700 hover:bg-rose-50 rounded-lg shadow-sm transition disabled:opacity-50"
          >
            <span v-if="cancellingId === item.id">Cancelando...</span>
            <span v-else>Cancelar</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Database, Profile } from '~/types/database'

interface ScheduleDisplayItem {
  id: string
  type: 'reservation' | 'block'
  startTime: string
  endTime: string
  userId?: string
  block?: string
  floor?: string
  door?: string
  reason?: string
}

const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()

const profile = ref<Profile | null>(null)
const scheduleItems = ref<ScheduleDisplayItem[]>([])
const loadingSchedule = ref(false)
const reserving = ref(false)
const cancellingId = ref<string | null>(null)

const actionError = ref('')
const actionSuccess = ref('')

const now = new Date()
const pad = (n: number) => String(n).padStart(2, '0')
const resDate = ref(`${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`)
const resTime = ref('18:00')
const resDuration = ref(60)

const formatDateTime = (isoString: string) => {
  const d = new Date(isoString)
  return `${d.toLocaleDateString([], { day: '2-digit', month: '2-digit' })} ${d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`
}

const loadProfile = async () => {
  if (!user.value) return
  const { data } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.value.id)
    .single()

  if (data) {
    profile.value = data as unknown as Profile
  }
}

const loadSchedule = async () => {
  loadingSchedule.value = true
  actionError.value = ''

  try {
    const { data, error } = await supabase.rpc('get_court_schedule')
    if (error) {
      actionError.value = error.message
      return
    }

    const items: ScheduleDisplayItem[] = []

    if (data?.reservations) {
      for (const r of data.reservations) {
        items.push({
          id: r.id,
          type: 'reservation',
          startTime: r.start_time,
          endTime: r.end_time,
          userId: r.user_id,
          block: r.block,
          floor: r.floor,
          door: r.door
        })
      }
    }

    if (data?.blocks) {
      for (const b of data.blocks) {
        items.push({
          id: b.id,
          type: 'block',
          startTime: b.start_time,
          endTime: b.end_time,
          reason: b.reason
        })
      }
    }

    items.sort((a, b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime())
    scheduleItems.value = items
  } catch (err: unknown) {
    if (err instanceof Error) {
      actionError.value = err.message
    }
  } finally {
    loadingSchedule.value = false
  }
}

const handleCreateReservation = async () => {
  actionError.value = ''
  actionSuccess.value = ''
  reserving.value = true

  try {
    const [hours, minutes] = resTime.value.split(':').map(Number)
    const startDate = new Date(`${resDate.value}T00:00:00`)
    startDate.setHours(hours, minutes, 0, 0)

    const endDate = new Date(startDate.getTime() + resDuration.value * 60 * 1000)

    const { error } = await supabase.rpc('create_reservation', {
      p_start_time: startDate.toISOString(),
      p_end_time: endDate.toISOString()
    })

    if (error) {
      actionError.value = error.message
      return
    }

    actionSuccess.value = '¡Reserva confirmada con éxito!'
    await loadSchedule()
  } catch (err: unknown) {
    if (err instanceof Error) {
      actionError.value = err.message
    }
  } finally {
    reserving.value = false
  }
}

const handleCancel = async (id: string) => {
  if (!confirm('¿Deseas cancelar esta reserva?')) return

  cancellingId.value = id
  actionError.value = ''
  actionSuccess.value = ''

  try {
    const { error } = await supabase.rpc('cancel_reservation', {
      p_reservation_id: id
    })

    if (error) {
      actionError.value = error.message
      return
    }

    actionSuccess.value = 'Reserva cancelada correctamente.'
    await loadSchedule()
  } catch (err: unknown) {
    if (err instanceof Error) {
      actionError.value = err.message
    }
  } finally {
    cancellingId.value = null
  }
}

onMounted(async () => {
  await Promise.all([loadProfile(), loadSchedule()])
})
</script>
