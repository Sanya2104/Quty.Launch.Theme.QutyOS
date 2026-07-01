<script setup></script>

<template>
  <div class="h-full overflow-y-auto">
    <h1>Главный экран</h1>

    <!-- Тестовый контент для проверки скролла -->
    <div v-for="i in 15" :key="i" class="test-item">Строка {{ i }}</div>
  </div>
</template>

<style scoped>
  .home-main {
    height: 100%;
    overflow-y: auto;
  }
</style>
