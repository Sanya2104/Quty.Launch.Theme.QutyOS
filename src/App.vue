<!-- src/App.vue -->
<script setup>
  import { RouterView } from 'vue-router'
  // import AppStatusBar from '@/components/AppStatusBar.vue'
  import AppNavigationBar from '@/components/AppNavigationBar.vue'
  // import AppNavigation from '@/components/AppNavigation.vue'

  /* импорт компонента */
  import DevConsole from '@/components/DevConsole.vue'

  /* стили оформления */
  import '@/assets/styles/main.css'
</script>

<template>
  <div id="App">
    <div
      id="AppBackground"
      class="bg-position-c bg-size-cover bg-attachment-fixed bg-repeat-no-repeat w-screen h-screen position-relative overflow-hidden"
    >
      <div
        id="AppContainer"
        class="filter-blur-normal position-absolute top-0 right-0 bottom-0 left-0 d-flex flex-direction-column"
      >
        <AppNavigationBar />
        <main id="AppMain" class="position-relative flex-1 overflow-hidden mx-15 mb-15">
          <router-view v-slot="{ Component }">
            <component :is="Component" />
          </router-view>
        </main>
        <!-- <AppNavigation /> -->
        <DevConsole />
      </div>
    </div>
  </div>
</template>

<style scoped>
  #AppBackground {
    background-image: url('@/assets/images/wallpaper2.jpg');
  }
</style>
