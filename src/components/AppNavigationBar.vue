<!-- src/components/AppNavigationBar.vue-->
<script setup>
  import { useRouter } from 'vue-router'
  import { devConsole } from '@/utilities/devConsole'

  /* маршрутизация */
  const router = useRouter()

  /* иконки */
  import {
    IconSquare as IconHome,
    IconLayoutGrid as IconApps,
    IconChevronDown as IconMore,
    IconVolume as IconVolume,
    IconWifi as IconWifi,
    IconSatellite as IconGps,
    IconBell as IconNotify,
  } from '@tabler/icons-vue'

  /* обработчик вызова меню */
  const handleMenuClick = async (item) => {
    if (item) {
      try {
        await router.push(item)
      } catch (err) {
        if (!err.message.includes('Avoided redundant navigation')) {
          devConsole.error('Сбой подключения маршрутизатора:', err)
        }
      }
    } else {
      devConsole.log('Запрос: ' + item)
    }
  }
</script>

<template>
  <div id="AppNavigationBar" class="w-full h-auto row justify-between px-10 py-15">
    <!---->
    <nav class="nav nav-pills col-auto mx-5 px-5 bg-light-060 filter-blur-normal rounded-normal">
      <li class="nav-item px-15 py-15" @click="handleMenuClick('../')">
        <IconHome :size="26" />
      </li>
      <li class="nav-item px-15 py-15" @click="handleMenuClick('/apps')">
        <IconApps :size="26" />
      </li>
    </nav>

    <!---->
    <nav
      class="nav nav-pills col mx-5 px-5 bg-light-060 filter-blur-normal rounded-normal phone-d-none tablet-d-flex desktop-d-flex"
    >
      <!-- <li class="nav-item px-10 py-10">
        <img
          :src="icon_fuel"
          alt="icon_fuel"
          class="w-var h-var object-fit-contain bg-light-040 rounded-md"
          style="--w: 36px; --h: 36px"
        />
      </li> -->
    </nav>

    <!---->
    <nav class="nav nav-pills col-auto mx-5 px-5 bg-light-060 filter-blur-normal rounded-normal">
      <li class="nav-item px-15 py-15">
        <IconMore :size="26" />
      </li>
      <li class="nav-item px-15 py-15">
        <IconVolume :size="26" />
      </li>
      <li class="nav-item px-15 py-15">
        <IconWifi :size="26" />
      </li>
      <li class="nav-item px-15 py-15">
        <IconGps :size="26" />
      </li>
    </nav>

    <!---->
    <nav class="nav nav-pills col-auto mx-5 bg-light-060 filter-blur-normal rounded-normal">
      <li class="nav-item px-15 py-15">
        <span class="h-var d-flex align-self-center" style="--h: 26px">
          <span class="phone-d-none tablet-d-block desktop-d-block mr-10">Ср, 8 Июля</span>
          <span>22:17</span>
        </span>
      </li>
    </nav>

    <!---->
    <nav class="nav nav-pills col-auto mx-5 bg-light-060 filter-blur-normal rounded-normal">
      <li class="nav-item px-15 py-15">
        <IconNotify :size="26" />
      </li>
    </nav>

    <!---->
  </div>
</template>

<style scoped></style>
