// src/utilities/androidApi.js

import { devConsole } from '@/utilities/devConsole'

// Заглушка списка приложений
export const mockApps = [
  {
    packageName: 'by.quty.launch.settings',
    name: 'Настройки лаунчера',
    iconBase64: '',
    isCustom: true,
  },

  {
    packageName: 'com.android.chrome',
    name: 'Chrome',
    iconBase64: '',
    isCustom: false,
  },

  {
    packageName: 'com.android.messaging',
    name: 'Сообщения',
    iconBase64: '',
    isCustom: false,
  },

  {
    packageName: 'com.android.camera',
    name: 'Камера',
    iconBase64: '',
    isCustom: false,
  },
]

// Заглушка статусов для AppBar
export const mockStatusBar = {
  notify: true, // Уведомления
  checkEngine: true, // включен/выключен
  internetSpeed: '1.2 MB/s', // Тестовая скорость
  cpuTemp: '57 °C', // Температура CPU
  volume: '33', // Громкость
  gsmSignal: 4, // Уровень сигнала GSM (0-4)
  gsmNetworkType: '4G', // тип сети (2G, 3G, 4G, 5G, H+)
  wifiSignalLevel: 4, // уровень сигнала Wi-Fi (0-4)
  wifi: true, // включен/выключен
  bluetooth: true, // включен/выключен
  usbConnected: true, // есть/нету подключений
  gps: true, // включен/выключен
}

// Проверка доступности окружения Android API
export const isAndroidAvailable = () => {
  return typeof window.Android !== 'undefined' && typeof window.Android.call === 'function'
}

// Универсальная функция вызова Android API
export const AndroidApiCall = (method, params = null) => {
  if (!isAndroidAvailable()) {
    devConsole.warn(`⚠️ Android API не доступен, вызов метода: ${method}`)
    return null
  }

  try {
    const paramsStr = params ? JSON.stringify(params) : null
    const result = window.Android.call(method, paramsStr)

    // Если результат — строка, парсим JSON
    if (typeof result === 'string') {
      try {
        return JSON.parse(result)
      } catch {
        // Если не удалось распарсить, возвращаем как есть
        return result
      }
    }

    return result
  } catch (error) {
    devConsole.error(`❌ Ошибка вызова Android.${method}:`, error)
    return null
  }
}
