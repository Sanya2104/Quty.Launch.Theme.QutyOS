// src/router.js

import { createRouter, createWebHashHistory } from 'vue-router'

// импорты скринов
import HomeMain from '@/screens/Home/HomeMain.vue'
import HomeGeneral from '@/screens/Home/HomeGeneral.vue'
import ErrorMain from '@/screens/Error/ErrorMain.vue'
import AppsMain from '@/screens/Apps/AppsMain.vue'

// маршруты
const router = createRouter({
  history: createWebHashHistory(import.meta.env.BASE_URL),

  routes: [
    // корневая переадресация
    {
      path: '/',
      redirect: '/home',
    },

    // домашний экран
    {
      path: '/home',
      name: 'home',
      component: HomeMain,
      children: [
        // домашний экран / главная
        {
          path: '',
          name: 'homeGeneral',
          meta: {
            title: 'Главная',
            link: '/home',
          },
          component: HomeGeneral,
        },
      ],
    },

    // приложения
    {
      path: '/apps',
      name: 'apps',
      meta: {
        title: 'Приложения',
        link: '/apps',
      },
      component: AppsMain,
    },

    // экран ошибки маршрута
    {
      path: '/:pathMatch(.*)*',
      name: 'error',
      meta: {
        title: 'Ошибка',
        link: '',
      },
      component: ErrorMain,
    },
  ],
})

export default router
