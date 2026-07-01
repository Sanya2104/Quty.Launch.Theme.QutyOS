// src/api/apps/launchApp.js
import { isAndroidAvailable, AndroidApiCall } from '@/utilities/androidApi'
import { devConsole } from '@/utilities/devConsole'

export function launchApp() {
  const run = (packageName) => {
    if (!packageName) {
      devConsole.warn('⚠️ Нет имени пакета для запуска')
      return false
    }

    try {
      if (!isAndroidAvailable()) {
        devConsole.info(`🚀 Эмуляция запуска: ${packageName}`)
        return true
      }

      const response = AndroidApiCall('launchApp', { packageName })

      if (response && response.success) {
        devConsole.info(`✅ Запущено приложение: ${packageName}`)
        return true
      } else {
        devConsole.warn(`⚠️ Не удалось запустить: ${packageName}`)
        return false
      }
    } catch (err) {
      devConsole.error('❌ Ошибка запуска приложения:', err)
      return false
    }
  }

  return { run }
}
