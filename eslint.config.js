// eslint.config.js
import globals from 'globals'
import pluginJs from '@eslint/js'
import pluginVue from 'eslint-plugin-vue'
import eslintConfigPrettier from 'eslint-config-prettier'
import eslintPluginPrettier from 'eslint-plugin-prettier'
import vueParser from 'vue-eslint-parser'

export default [

  // 1. ИГНОРИРУЕМЫЕ ФАЙЛЫ (замена .eslintignore)
  {
    ignores: [
      'dist/**',
      'node_modules/**',
      'public/**',
      '*.config.js', // игнорировать конфиги в корне
      '.vscode/**',
      '**/*.log',
    ],
  },

  // 2. ОСНОВНЫЕ НАСТРОЙКИ для JS и Vue файлов
  {
    // Файлы, к которым применяются эти настройки
    files: ['**/*.{js,mjs,cjs,vue}'],
    // Языковые опции
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.es2021,
      },
      parserOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
      },
    },
  },

  // 3. Базовые правила для JavaScript от ESLint
  pluginJs.configs.recommended,

  // 4. Базовые правила для Vue 3 (essential)
  ...pluginVue.configs['flat/essential'],

  // 5. СПЕЦИАЛЬНЫЕ НАСТРОЙКИ для Vue файлов (переопределяем парсер)
  {
    files: ['**/*.vue'],
    languageOptions: {
      parser: vueParser,
      parserOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
      },
    },
  },

  // 6. НАСТРОЙКИ ДЛЯ PRETTIER (интеграция с ESLint)
  {
    plugins: {
      prettier: eslintPluginPrettier,
    },
    rules: {
      'prettier/prettier': 'warn',
      'no-console': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
      'no-debugger': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    },
  },

  // 7. Отключаем конфликтующие правила ESLint с Prettier (ВСЕГДА последним)
  eslintConfigPrettier,

]