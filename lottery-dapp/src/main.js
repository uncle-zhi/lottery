import { createApp } from 'vue';
import App from './App.vue';
import router from './router';
import './assets/global.css';
import i18n from './i18n'
console.log('i18n messages', i18n.global.messages)
createApp(App).use(router).use(i18n).mount('#app');