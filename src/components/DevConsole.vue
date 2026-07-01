<!-- src/components/DevConsole.vue -->

<script setup>
  import { ref, onMounted, onUnmounted } from 'vue'
  import { devConsole } from '@/utilities/devConsole'

  /* иконки */
  import {
    IconTerminal as IconOpen,
    IconTerminal2 as IconConsole,
    IconTrash as IconClear,
    IconCopy as IconCopy,
    IconCheck as IconCheck,
    IconX as IconClose,
    IconList as IconList,
    IconAlertCircle as IconInfo,
    IconAlertTriangle as IconWarn,
    IconAlertOctagon as IconError,
  } from '@tabler/icons-vue'

  const isPanelVisible = ref(false)
  const logs = ref([])
  const updateInterval = ref(null)
  const copySuccess = ref(false)
  const clearSuccess = ref(false)

  // Фильтры
  const filters = ['all', 'log', 'info', 'warn', 'error']
  const activeFilter = ref('all')

  // Статистика
  const stats = ref({ log: 0, info: 0, warn: 0, error: 0, total: 0 })

  const togglePanel = () => {
    isPanelVisible.value = !isPanelVisible.value
  }

  const updateLogs = () => {
    logs.value = devConsole.getLogs(activeFilter.value)
    stats.value = devConsole.getStats() // обновление статистики
  }

  const setFilter = (filter) => {
    activeFilter.value = filter
    updateLogs()
  }

  const copyAllLogs = async () => {
    const logText = logs.value
      .map((log) => {
        let message = log.message
        if (typeof message === 'object') {
          message = JSON.stringify(message, null, 2)
        }
        const countSuffix = log.count > 1 ? ` (x${log.count})` : ''
        return `[${log.timestamp}] ${log.type.toUpperCase()}: ${message}${countSuffix} (${log.file || 'unknown'})`
      })
      .join('\n\n')

    try {
      await navigator.clipboard.writeText(logText)
      copySuccess.value = true
      setTimeout(() => {
        copySuccess.value = false
      }, 2000)
    } catch (err) {
      devConsole.error('Ошибка копирования:', err)
    }
  }

  // Функция очистки логов с анимацией
  const clearAllLogs = () => {
    devConsole.clearLogs()
    clearSuccess.value = true
    setTimeout(() => {
      clearSuccess.value = false
    }, 2000)
    updateLogs()
  }

  // Получение иконки для фильтра
  const getFilterIcon = (filter) => {
    switch (filter) {
      case 'log':
        return IconList
      case 'info':
        return IconInfo
      case 'warn':
        return IconWarn
      case 'error':
        return IconError
      default:
        return null
    }
  }

  // Получение цвета для фильтра
  const getFilterClass = (filter) => {
    switch (filter) {
      case 'log':
        return 'bg-green-040 color-dark-080'
      case 'info':
        return 'bg-cyan-040 color-dark-080'
      case 'warn':
        return 'bg-yellow-040 color-dark-080'
      case 'error':
        return 'bg-red-040 color-dark-080'
      case 'all':
        return 'bg-light-060 color-dark-080'
      default:
        return 'bg-light-010 color-light-080'
    }
  }

  onMounted(() => {
    updateLogs()
    updateInterval.value = setInterval(updateLogs, 1000)
  })

  onUnmounted(() => {
    if (updateInterval.value) {
      clearInterval(updateInterval.value)
    }
  })
</script>

<template>
  <!-- Кнопка открытия -->
  <div
    v-show="!isPanelVisible"
    class="filter-blur-normal px-10 py-15 position-fixed top-percent-50 right-10 z-index-1000 transition-03 rounded-sm"
    :class="[`bg-light-040`]"
    style="transform: translateY(-50%)"
    @click="togglePanel"
  >
    <IconOpen :size="20" :class="[`color-dark-070`]" />
  </div>

  <!-- Панель -->
  <div
    id="Console"
    class="filter-blur-normal position-fixed top-10 right-10 bottom-10 z-index-1000 transition-03 rounded-normal d-grid ml-10"
    :class="[`bg-light-080`]"
    :style="{
      gridTemplateRows: 'auto auto 1fr',
      minWidth: isPanelVisible ? '35%' : '0',
      width: isPanelVisible ? 'auto' : '0',
      opacity: isPanelVisible ? '1' : '0',
      visibility: isPanelVisible ? 'visible' : 'hidden',
    }"
  >
    <!-- Заголовок -->
    <div class="w-full d-flex flex-wrap-wrap p-15">
      <nav class="nav nav-pills col">
        <li class="nav-item px-15">
          <div class="nav-link d-flex align-items-center">
            <IconConsole :size="26" :class="[`color-dark-070`]" />
            <span class="ml-15 font-size-18" :class="[`color-dark-100`]"> Консоль </span>
            <span v-if="stats.total > 0" class="ml-15 font-size-14" :class="[`color-dark-060`]">
              [ {{ stats.total }} ]
            </span>
          </div>
        </li>
      </nav>
      <nav class="ml-15 nav nav-pills col-auto">
        <!-- Кнопка очистки -->
        <li class="nav-item px-15" @click="clearAllLogs">
          <div class="nav-link d-flex align-items-center">
            <IconCheck v-if="clearSuccess" :size="26" :class="[`color-green-070`]" />
            <IconClear v-else :size="26" :class="[`color-dark-070`]" />
          </div>
        </li>

        <!-- Кнопка копирования -->
        <li class="nav-item px-15" @click="copyAllLogs">
          <div class="nav-link d-flex align-items-center">
            <IconCheck v-if="copySuccess" :size="26" :class="[`color-green-070`]" />
            <IconCopy v-else :size="26" :class="[`color-dark-070`]" />
          </div>
        </li>

        <!-- Кнопка закрытия -->
        <li class="nav-item px-15" @click="togglePanel">
          <div class="nav-link">
            <IconClose :size="26" :class="[`color-dark-070`]" />
          </div>
        </li>
      </nav>
    </div>

    <!-- Фильтры -->
    <div class="px-15 py-10 d-flex flex-wrap-wrap gap-10">
      <button
        v-for="filter in filters"
        :key="filter"
        class="px-15 py-5 rounded-sm font-size-14 transition-03 d-flex align-items-center"
        :class="[activeFilter === filter ? getFilterClass(filter) : 'bg-light-010 color-dark-080']"
        @click="setFilter(filter)"
      >
        <component
          v-if="filter !== 'all' && getFilterIcon(filter)"
          :is="getFilterIcon(filter)"
          :size="16"
          class="mr-5"
        />
        {{ filter.charAt(0).toUpperCase() + filter.slice(1) }}
        <span v-if="filter !== 'all'" class="ml-5 font-size-14">
          [ {{ stats[filter] || 0 }} ]
        </span>
      </button>
    </div>

    <!-- Логи -->
    <div class="overflow-scroll p-15">
      <div
        v-for="log in logs"
        :key="log.groupKey + log.timestamp"
        class="mb-10 font-size-16 p-10 filter-blur-normal rounded-sm"
        :class="[`bg-light-020`]"
        :style="{
          'border-left': `5px solid ${log.color}`,
        }"
      >
        <div class="pb-10 d-flex flex-wrap-wrap align-items-center gap-10">
          <span class="font-size-14 font-weight-bolder" :class="[`color-dark-070`]">
            {{ log.type.toUpperCase() }}
          </span>

          <span class="font-size-14" :class="[`color-dark-060`]">
            {{ log.timestamp }}
          </span>
          <span v-if="log.file !== 'unknown'" class="font-size-14" :class="[`color-dark-060`]">
            {{ log.file }}:{{ log.line }}
          </span>

          <!-- Счётчик повторений -->
          <span
            v-if="log.count > 1"
            class="font-size-14 font-weight-bolder ml-10 rounded-sm"
            :class="[`bg-${log.type}-100 color-dark-100`]"
          >
            [ ×{{ log.count }} ]
          </span>
        </div>

        <div class="font-size-16 mt-10" :class="[`color-dark-080`]">
          <pre v-if="typeof log.message === 'object'">{{
            JSON.stringify(log.message, null, 2)
          }}</pre>
          <span v-else>{{ log.message }}</span>
        </div>
      </div>

      <!-- Пустое состояние -->
      <div v-if="!logs.length" class="text-align-center py-50" :class="[`color-dark-080`]">
        <IconConsole :size="48" class="opacity-30" />
        <p class="font-size-16 mt-15">Нет сообщений</p>
        <p v-if="activeFilter !== 'all'" class="font-size-14 mt-15">Попробуйте изменить фильтр</p>
      </div>
    </div>
  </div>
</template>

<style scoped></style>
