// src/api/getStatusBar.js
import { ref } from 'vue'
import { isAndroidAvailable, AndroidApiCall, mockStatusBar } from '@/utilities/androidApi'
import { devConsole } from '@/utilities/devConsole'

export function getStatus() {
  const status = ref({
    notify: null,
    checkEngine: null,
    internetSpeed: null,
    cpuTemp: null,
    volume: null,
    gsmSignal: null,
    gsmNetworkType: null,
    wifiSignalLevel: null,
    bluetooth: null,
    wifi: null,
    gps: null,
    usbConnected: null,
  })

  const loading = ref(true)
  const error = ref(null)

  const loadStatus = async () => {
    loading.value = true
    error.value = null

    try {
      if (!isAndroidAvailable()) {
        devConsole.log('🛠️ Режим разработки: используются тестовые данные')
        status.value = mockStatusBar
        return
      }

      const response = AndroidApiCall('getStatusBar', null)

      if (!response || !response.success) {
        throw new Error(response?.error || 'Ошибка загрузки статусов')
      }

      status.value = response.data
      devConsole.log('✅ Статусы загружены:', JSON.stringify(status.value, null, 2))
    } catch (err) {
      devConsole.error('❌ Ошибка загрузки статусов:', err)
      error.value = err.message || 'Не удалось загрузить статусы'

      if (import.meta.env.DEV && !isAndroidAvailable()) {
        status.value = mockStatusBar
        error.value = null
      }
    } finally {
      loading.value = false
    }
  }

  const updateStatus = async (key, value) => {
    status.value[key] = value
  }

  let intervalId = null

  const startPolling = (interval = 1000) => {
    // Запускаем polling только если это реальное Android устройство
    if (!isAndroidAvailable()) {
      devConsole.log('🛠️ Режим разработки: polling отключён')
      return
    }

    if (intervalId) clearInterval(intervalId)
    intervalId = setInterval(() => {
      loadStatus()
    }, interval)
    devConsole.log(`✅ Polling запущен с интервалом ${interval}ms`)
  }

  const stopPolling = () => {
    if (intervalId) {
      clearInterval(intervalId)
      intervalId = null
      devConsole.log('⏹️ Polling остановлен')
    }
  }

  return {
    status,
    loading,
    error,
    loadStatus,
    updateStatus,
    startPolling,
    stopPolling,
  }
}
