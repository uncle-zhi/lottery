import { createI18n } from 'vue-i18n'
import zh from './locales/zh.json'
import en from './locales/en.json'

const i18n = createI18n({
  legacy: false, // 启用 Composition API 模式
  locale: 'zh', // 默认语言
  fallbackLocale: 'en', // 语言缺失时使用的备用语言
  messages: {
    zh,
    en
  }
})

export default i18n
