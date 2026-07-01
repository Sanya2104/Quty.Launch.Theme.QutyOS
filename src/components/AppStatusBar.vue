<!-- src/components/AppStatusBar.vue -->
<script setup>
  import { ref, markRaw, onMounted, onUnmounted, watch, computed } from 'vue'
  import { useRoute, useRouter } from 'vue-router'
  import { getStatus } from '@/api/getStatusBar'
  import { isAndroidAvailable } from '@/utilities/androidApi'

  // иконки
  import {
    IconBell as IconNotify,
    IconEngine as IconCheckEngine,
    IconArrowsMoveVertical as IconSpeedEthernet,
    IconCpu as IconTempCPU,
    IconVolume3 as IconVolumeOff,
    IconVolume4 as IconVolumeLow,
    IconVolume2 as IconVolumeHigh,
    IconVolume as IconVolumeFull,
    IconAntennaBarsOff as IconGsmSignalZero,
    IconAntennaBars2 as IconGsmSignalLow,
    IconAntennaBars3 as IconGsmSignalMedium,
    IconAntennaBars4 as IconGsmSignalHight,
    IconAntennaBars5 as IconGsmSignalFull,
    IconWifiOff as IconWifiZero,
    IconWifi0 as IconWifiLow,
    IconWifi1 as IconWifiMedium,
    IconWifi2 as IconWifiHigh,
    IconWifi as IconWifiFull,
    IconBluetooth as IconBluetooth,
    IconUsb as IconUsb,
    IconSatellite as IconGps,
    IconUserCircle as IconProfile,
  } from '@tabler/icons-vue'

  // Получаем статусы
  const { status, loadStatus, startPolling, stopPolling } = getStatus()

  // текущее время
  const currentTime = ref('')

  // функция обновления времени
  const updateTime = () => {
    const now = new Date()
    const hours = now.getHours().toString().padStart(2, '0')
    const minutes = now.getMinutes().toString().padStart(2, '0')
    currentTime.value = `${hours}:${minutes}`
  }

  // Функция получения иконки громкости в зависимости от процента
  const getVolumeIcon = (volumePercent) => {
    if (!volumePercent && volumePercent !== 0) return markRaw(IconVolumeOff)
    const percent = parseInt(volumePercent)
    if (percent === 0) return markRaw(IconVolumeOff)
    if (percent <= 25) return markRaw(IconVolumeLow)
    if (percent <= 75) return markRaw(IconVolumeHigh)
    return markRaw(IconVolumeFull)
  }

  // Функция получения иконки GSM сигнала в зависимости от уровня (0-4)
  const getGsmSignalIcon = (level) => {
    if (level === null || level === undefined) return markRaw(IconGsmSignalZero)
    switch (level) {
      case 0:
        return markRaw(IconGsmSignalZero)
      case 1:
        return markRaw(IconGsmSignalLow)
      case 2:
        return markRaw(IconGsmSignalMedium)
      case 3:
        return markRaw(IconGsmSignalHight)
      case 4:
        return markRaw(IconGsmSignalFull)
      default:
        return markRaw(IconGsmSignalZero)
    }
  }

  // Функция получения иконки Wi-Fi в зависимости от уровня сигнала (0-4)
  const getWifiIcon = (level) => {
    if (level === null || level === undefined) return markRaw(IconWifiZero)
    switch (level) {
      case 0:
        return markRaw(IconWifiZero)
      case 1:
        return markRaw(IconWifiLow)
      case 2:
        return markRaw(IconWifiMedium)
      case 3:
        return markRaw(IconWifiHigh)
      case 4:
        return markRaw(IconWifiFull)
      default:
        return markRaw(IconWifiZero)
    }
  }

  // Базовые элементы статус бара (будут обновляться динамически)
  const statusBarItemsBase = [
    // Время
    {
      icon: false,
      to: false,
      data: currentTime,
      position: 'left',
      color: 'light-080',
      style: 'numberStyle font-size-32',
      active: true,
    },

    // Уведомления
    {
      icon: markRaw(IconNotify),
      to: false,
      data: false,
      position: 'left',
      color: 'light-080',
      style: '',
      active: true,
      dataKey: 'notify', // будет брать из status
    },

    // Ошибка двигателя
    {
      icon: markRaw(IconCheckEngine),
      to: '/auto/diagnostics',
      data: false,
      position: 'left',
      color: 'red-080',
      style: '',
      active: true,
      dataKey: 'checkEngine', // будет брать из status
    },

    // Скорость соединения
    {
      icon: markRaw(IconSpeedEthernet),
      to: false,
      dataKey: 'internetSpeed',
      position: 'right',
      color: 'light-080',
      style: 'numberStyle',
      active: true,
    },

    // Температура CPU
    {
      icon: markRaw(IconTempCPU),
      to: false,
      dataKey: 'cpuTemp',
      position: 'right',
      color: 'light-080',
      style: 'numberStyle',
      active: true,
    },

    // Громкость (динамическая иконка)
    {
      icon: markRaw(IconVolumeFull),
      to: false,
      dataKey: 'volume',
      position: 'right',
      color: 'light-080',
      style: 'numberStyle',
      active: true,
      getIcon: (value) => getVolumeIcon(value),
    },

    // GSM
    {
      icon: markRaw(IconGsmSignalFull),
      to: false,
      dataKey: 'gsmSignal',
      networkTypeKey: 'gsmNetworkType',
      position: 'right',
      color: 'light-080',
      style: 'numberStyle',
      active: true,
      isToggle: true,
      getIcon: (value) => getGsmSignalIcon(value),
    },

    // Wi-Fi
    {
      icon: markRaw(IconWifiFull),
      to: false,
      dataKey: 'wifi',
      signalLevelKey: 'wifiSignalLevel',
      position: 'right',
      color: 'light-080',
      style: '',
      active: true,
      isToggle: true,
      getIcon: (level) => getWifiIcon(level),
    },

    // Bluetooth
    {
      icon: markRaw(IconBluetooth),
      to: false,
      dataKey: 'bluetooth',
      position: 'right',
      color: 'light-080',
      style: '',
      active: true,
      isToggle: true,
    },

    // USB подключения
    {
      icon: markRaw(IconUsb),
      to: false,
      dataKey: 'usbConnected',
      position: 'right',
      color: 'light-080',
      style: '',
      active: true,
      isToggle: true,
    },

    // GPS
    {
      icon: markRaw(IconGps),
      to: false,
      dataKey: 'gps',
      position: 'right',
      color: 'light-080',
      style: '',
      active: true,
      isToggle: true,
    },

    // Профиль
    {
      icon: markRaw(IconProfile),
      to: '/auto/profile',
      data: false,
      position: 'right',
      color: 'light-080',
      style: '',
      active: true,
    },
  ]

  // Реактивный массив элементов
  const statusBarItems = ref([])

  // Функция обновления элементов на основе статусов
  const updateStatusBarItems = () => {
    statusBarItems.value = statusBarItemsBase.map((item) => {
      // Для Уведомлений - показываем только если есть уведомления
      if (item.dataKey === 'notify') {
        const hasNotifications = status.value.notify === true

        return {
          ...item,
          icon: item.icon,
          data: false,
          active: hasNotifications,
        }
      }
      // Для Wi-Fi (специальная обработка)
      if (item.dataKey === 'wifi') {
        const isActive = status.value.wifi === true
        const signalLevel = status.value.wifiSignalLevel ?? 0
        const icon = item.getIcon ? item.getIcon(signalLevel) : item.icon

        return {
          ...item,
          icon: icon,
          data: false,
          active: isActive,
        }
      }

      // Для остальных элементов с dataKey и без isToggle
      if (item.dataKey && !item.isToggle) {
        const value = status.value[item.dataKey]
        const icon = item.getIcon ? item.getIcon(value) : item.icon

        if (item.dataKey === 'checkEngine') {
          return {
            ...item,
            icon: icon,
            data: false,
            active: value === true,
          }
        }

        return {
          ...item,
          icon: icon,
          data: value,
          active: !!value,
        }
      }

      // Для toggle-элементов (Bluetooth, GSM, GPS, USB)
      if (item.isToggle && item.dataKey) {
        const isActive = status.value[item.dataKey]
        const icon = item.getIcon ? item.getIcon(isActive) : item.icon

        // Для GSM добавляем тип сети
        let additionalData = false
        if (item.dataKey === 'gsmSignal' && isActive) {
          additionalData = status.value.gsmNetworkType || ''
        }

        return {
          ...item,
          icon: icon,
          data: additionalData,
          active: !!isActive,
        }
      }

      // Для статичных элементов
      return { ...item }
    })
  }

  // Следим за изменением статусов
  watch(
    status,
    () => {
      updateStatusBarItems()
    },
    { deep: true }
  )

  // маршрутизация
  const route = useRoute()
  const router = useRouter()

  // обработчик клика
  const handleItemClick = (item) => {
    if (item.to) {
      router.push(item.to)
    }
  }

  // добавить вычисляемое свойство для определения главной страницы
  const isHomePage = computed(() => {
    return route.path === '/' || route.path === '/home'
  })

  // жизненный цикл
  let timerInterval

  onMounted(() => {
    updateTime()
    timerInterval = setInterval(updateTime, 60000)

    // Загружаем статусы
    loadStatus()

    // Запускаем polling только на реальном устройстве
    if (isAndroidAvailable()) {
      startPolling(1000) // обновляем каждую секунду
    }

    // Инициализируем элементы
    updateStatusBarItems()
  })

  onUnmounted(() => {
    if (timerInterval) {
      clearInterval(timerInterval)
    }

    // Останавливаем polling
    if (isAndroidAvailable()) {
      stopPolling()
    }
  })
</script>

<template>
  <div
    id="AppBar"
    class="w-full h-auto row justify-between px-15 py-15"
    :class="{ 'bg-coolgray-080 filter-blur-normal': !isHomePage }"
  >
    <nav
      v-for="position in ['left', 'right']"
      :key="position"
      class="nav nav-pills"
      :class="position === 'left' ? 'col' : 'col-auto'"
    >
      <li
        v-for="(item, idx) in statusBarItems.filter((i) => i.position === position && i.active)"
        :key="`${position}-${idx}`"
        @click="handleItemClick(item)"
        class="nav-item px-15 py-5 d-flex align-items-center"
        :class="`color-${item.color}`"
      >
        <component v-if="item.icon" :is="item.icon" :size="32" :stroke="1.5" />
        <span v-if="item.data" :class="[item.style, 'ml-5']">{{ item.data }}</span>
      </li>
    </nav>
  </div>
</template>

<style scoped></style>
