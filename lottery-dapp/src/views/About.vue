<template>
  <a-page-header
    style="color: white;"
    title=""
    :breadcrumb="{ routes }"
    sub-title=""
  />
  <div class="about-lottery">
    <div class="section-title">🎯 彩票玩法简介</div>

    <section>
      <h2>🎮 玩法说明</h2>
      <ul>
        <li>每轮彩票由管理员开启，用户可在开放期间内购买彩票。</li>
        <li>投注时选择 1 至 5 中的一个号码，并支付相应 POL（每注最低 0.01 POL）。</li>
        <li>首位玩家投注后将启动倒计时，约 500 个区块后自动结束本轮。</li>
        <li>结束后，合约通过 <strong>Chainlink VRF</strong> 获取随机数进行开奖，确保公平。</li>
        <li>中奖奖金为玩家总投注额的 <strong>85%</strong>，按投注比例分配；若无人中奖，奖金滚入下一轮。</li>
        <li>中奖后可前往 👤 <strong>个人信息页面</strong> 查看记录并提取奖金。</li>
      </ul>
    </section>

    <section>
      <h2>🔁 主要流程</h2>
      <ul>
        <li>管理员开启新一轮彩票。</li>
        <li>主界面显示 <code>💵 {{ $t('message.bet') }}</code> 时，表示当前可投注。</li>
        <li>投注后，等待区块倒计时结束，系统调用合约自动关闭投注，并请求 VRF 随机数。</li>
        <li>VRF 返回随机数后，系统执行开奖逻辑。</li>
      </ul>
    </section>

    <section>
      <h2>🛡️ 安全与公平</h2>
      <ul>
        <li>合约源码已开源并部署上链，支持安全审计。</li>
        <li>管理员无法提取奖池资金。</li>
        <li>所有参数与操作均在链上透明执行，管理员无法干预开奖。</li>
        <li>用户的奖金需由本人钱包自行提取，管理员无法代为操作。</li>
        <li>采用 <strong>Chainlink VRF</strong> 实现链上可验证的随机数。</li>
        <li>管理员权限受控，用户资产安全有保障。</li>
      </ul>
    </section>
  </div>

  <div style="margin-bottom: 30px;"></div>
</template>


<script setup>
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
const routes = [
  {
    path: '/',
    breadcrumbName: t('breadcrumb.home'),
  },
  {
    path: '/About',
    breadcrumbName: t('breadcrumb.about'),
  }

];
</script>

<style scoped>
.about-lottery {
  color: white;
  max-width: 700px;
  margin: 0 auto;
}

.section-title {
  font-size: xx-large;
  padding-top: 10px;
  text-align: center;
  margin-bottom: 10px;
}

.about-lottery h2 {
  font-size: 1.4em;
  margin-top: 1.5em;
  color: #ffd700;
}

.about-lottery ul {
  padding-left: 1.2em;
}

.about-lottery li {
  margin-bottom: 0.5em;
  line-height: 1.6;
}

:deep(.ant-breadcrumb-link) {
  color: gray;
}
:deep(.ant-breadcrumb a) {
  color: white;
}
:deep(.ant-breadcrumb-separator) {
  color: white;
}
</style>