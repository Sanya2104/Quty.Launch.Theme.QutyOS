<!-- src/components/AppNavigation.vue-->
<script setup>
  import { ref } from 'vue'
  import { useRouter } from 'vue-router'
  import { devConsole } from '@/utilities/devConsole'

  /* маршрутизация */
  const router = useRouter()

  /* иконки */
  import {
    IconArrowNarrowLeft as IconBack,
    IconSmartHome as IconHome,
    IconLayoutGrid as IconApps,
  } from '@tabler/icons-vue'

  /* статусбар */
  const AppNavigation = ref([
    // Назад
    {
      icon: IconBack,
      to: '',
      position: 'left',
      active: true,
    },

    // Главная
    {
      icon: IconHome,
      to: '../',
      position: 'left',
      active: true,
    },

    // Приложения
    {
      icon: IconApps,
      to: '/apps',
      position: 'right',
      active: true,
    },
  ])

  /* обработчик вызова меню */
  const handleMenuClick = async (item) => {
    if (item.to) {
      try {
        await router.push(item.to)
      } catch (err) {
        if (!err.message.includes('Avoided redundant navigation')) {
          devConsole.error('Сбой подключения маршрутизатора:', err)
        }
      }
    } else if (item.package) {
      devConsole.log('Запрос: ' + item.package)
    }
  }
</script>

<template>
  <div
    id="AppNavigation"
    class="bg-coolgray-080 filter-blur-normal w-full h-auto row justify-between px-15 py-15"
  >
    <!-- Левая часть меню -->
    <nav class="nav nav-pills col">
      <li
        v-for="(item, index) in AppNavigation.filter((i) => i.position === 'left' && i.active)"
        :key="'left-' + index"
        class="nav-item px-15 color-light-080"
        @click="handleMenuClick(item)"
      >
        <component :is="item.icon" :size="32" />
      </li>
    </nav>

    <!-- Правая часть меню -->
    <nav class="nav nav-pills col-auto">
      <li
        v-for="(item, index) in AppNavigation.filter((i) => i.position === 'right' && i.active)"
        :key="'right-' + index"
        class="nav-item px-15 color-light-080"
        @click="handleMenuClick(item)"
      >
        <component :is="item.icon" :size="32" />
      </li>
    </nav>
  </div>
</template>

<style scoped></style>
