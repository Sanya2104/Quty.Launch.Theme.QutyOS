// src/utilities/devConsole.js

export const devConsole = {
  // Просто массив для хранения логов
  _logs: [],
  _maxLogs: 250, // Максимум записей

  log(...args) {
    this._printAndSave('log', '🟢', 'rgba(76, 175, 80, 0.6)', ...args)
  },

  warn(...args) {
    this._printAndSave('warn', '🟡', 'rgba(255, 152, 0, 0.6)', ...args)
  },

  error(...args) {
    this._printAndSave('error', '🔴', 'rgba(244, 67, 54, 0.6)', ...args)
  },

  info(...args) {
    this._printAndSave('info', '🔵', 'rgba(33, 150, 243, 0.6)', ...args)
  },

  _printAndSave(type, emoji, color, ...args) {
    // Автоматически определяем место вызова
    let location = 'Unknown'
    let file = 'unknown'
    let line = '0'

    try {
      // Получаем стек вызовов
      const stack = new Error().stack
      if (stack) {
        const lines = stack.split('\n')
        // Ищем строку, которая относится к нашему коду (не к devConsole.js)
        for (let i = 2; i < lines.length; i++) {
          const lineText = lines[i].trim()
          if (
            !lineText.includes('devConsole.js') &&
            !lineText.includes('node_modules') &&
            lineText.includes('.')
          ) {
            // Извлекаем имя файла и номер строки
            const match = lineText.match(/([^/]+\.(vue|js|ts))[^:]*:(\d+):(\d+)/)
            if (match) {
              file = match[1]
              line = match[3]
              location = `${file}:${line}`
            } else {
              // Просто берем часть пути
              const simpleMatch = lineText.match(/([^/(]+)\.(vue|js|ts)/)
              if (simpleMatch) {
                file = simpleMatch[0]
                location = file
              }
            }
            break
          }
        }
      }
      // eslint-disable-next-line no-unused-vars
    } catch (e) {
      // В случае ошибки - просто используем Unknown
    }

    // 1. Сохраняем в память
    const timestamp = new Date().toLocaleTimeString()
    const message = args.join(' ')

    // Создаём ключ для группировки (тип + сообщение + файл)
    const groupKey = `${type}:${message}:${file}`

    const logEntry = {
      type,
      emoji,
      timestamp,
      location, // полное местоположение: file.vue:84
      file, // только имя файла: file.vue
      line, // только номер строки: 84
      color, // цвет для бордера
      message,
      groupKey,
      count: 1, // Для группировки
      isGrouped: false, // Флаг, что это сгруппированное сообщение
    }

    // Проверяем, есть ли уже такое сообщение
    const existingIndex = this._logs.findIndex((log) => log.groupKey === groupKey && !log.isGrouped)

    if (existingIndex !== -1) {
      // Обновляем существующее сообщение
      const existing = this._logs[existingIndex]
      existing.count += 1
      existing.timestamp = timestamp
      existing.location = location
      existing.line = line

      // Перемещаем в конец списка (как в браузере)
      this._logs.splice(existingIndex, 1)
      this._logs.push(existing)

      // Логируем в консоль браузера только первое вхождение
      if (existing.count === 2) {
        this._printToConsole(type, emoji, color, location, args, true)
      }
      return
    }

    // Новое сообщение
    this._logs.push(logEntry)

    // Удаляем старые логи если слишком много
    if (this._logs.length > this._maxLogs) {
      this._logs.shift()
    }

    // Выводим в консоль браузера
    this._printToConsole(type, emoji, color, location, args, false)
  },

  _printToConsole(type, emoji, color, location, args, isRepeated) {
    const prefix = `%c[DEV:${type.toUpperCase()}] ${emoji}`
    const styles = [
      `background: ${color}`,
      'color: white',
      'padding: 2px 4px',
      'border-radius: 3px',
      'font-weight: bold',
    ].join(';')

    // Добавляем индикатор повторения
    const repeatMsg = isRepeated ? ' (повтор)' : ''

    switch (type) {
      case 'warn':
        console.warn(prefix, styles, location + repeatMsg, ...args)
        break
      case 'error':
        console.error(prefix, styles, location + repeatMsg, ...args)
        break
      case 'info':
        console.info(prefix, styles, location + repeatMsg, ...args)
        break
      default:
        console.log(prefix, styles, location + repeatMsg, ...args)
    }
  },

  // Получение логов с группировкой
  getLogs(filter = null) {
    let filtered = [...this._logs]

    // Фильтрация по типу
    if (filter && filter !== 'all') {
      filtered = filtered.filter((log) => log.type === filter)
    }

    return filtered.reverse() // Новые сверху
  },

  // Получение статистики по типам
  getStats() {
    const stats = { log: 0, info: 0, warn: 0, error: 0, total: 0 }
    for (const log of this._logs) {
      if (stats[log.type] !== undefined) {
        stats[log.type] += log.count || 1
        stats.total += log.count || 1
      }
    }
    return stats
  },

  clearLogs() {
    this._logs = []
  },
}
