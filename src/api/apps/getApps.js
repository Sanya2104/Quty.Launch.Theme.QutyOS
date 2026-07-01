// src/api/apps/getApps.js
import { ref } from 'vue'
import { isAndroidAvailable, mockApps, AndroidApiCall } from '@/utilities/androidApi'
import { devConsole } from '@/utilities/devConsole'

export function getApps() {
  const apps = ref([])
  const loading = ref(true)
  const error = ref(null)

  const loadApps = async () => {
    if (!loading.value && apps.value.length > 0) return

    loading.value = true
    error.value = null

    try {
      if (!isAndroidAvailable()) {
        devConsole.log('🛠️ Режим разработки: используются тестовые данные')
        apps.value = mockApps
        return
      }

      const response = AndroidApiCall('getApps', null)

      if (!response || !response.success) {
        throw new Error(response?.error || 'Ошибка загрузки приложений')
      }

      apps.value = response.data
      devConsole.info(`✅ Загружено приложений: ${apps.value.length}`)
    } catch (err) {
      devConsole.error('❌ Ошибка загрузки приложений:', err)
      error.value = err.message || 'Не удалось загрузить список приложений'

      if (import.meta.env.DEV && !isAndroidAvailable()) {
        apps.value = mockApps
        error.value = null
      }
    } finally {
      loading.value = false
    }
  }

  return {
    apps,
    loading,
    error,
    loadApps,
  }
}
