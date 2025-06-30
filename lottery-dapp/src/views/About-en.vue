<template>
  <a-page-header
    style="color: white;"
    title=""
    :breadcrumb="{ routes }"
    sub-title=""
  />
  <div class="about-lottery">
    <div class="section-title">🎯 Lottery Game Overview</div>

    <section>
      <h2>🎮 Game Rules</h2>
      <ul>
        <li>Each round is started by the admin. Players can purchase tickets during the open period.</li>
        <li>Choose a number between 1 and 5 and pay the required ETH (minimum 0.01 ETH per ticket) to place a bet.</li>
        <li>Once the first player places a bet, a countdown begins. The round ends after approximately 100 blocks.</li>
        <li>After the round ends, a random number is generated via <strong>Chainlink VRF</strong> to determine the winning number.</li>
        <li>85% of the total bet amount is distributed to winners based on their stake. If no winner, the prize rolls over to the next round.</li>
        <li>Winners can view their rewards in the 👤 <strong>My Info</strong> page and manually withdraw their earnings.</li>
      </ul>
    </section>

    <section>
      <h2>🔁 Main Process</h2>
      <ul>
        <li>Admin starts a new round.</li>
        <li>On the home screen, when you see <code>💵 {{ $t('message.bet') }}</code>, it means betting is open.</li>
        <li>After betting, the system waits for the block countdown to finish, then calls the contract to close betting and request a random number from Chainlink VRF.</li>
        <li>Once the random number is returned, the contract finalizes the draw and determines the winner.</li>
      </ul>
    </section>

    <section>
      <h2>🛡️ Security & Fairness</h2>
      <ul>
        <li>Smart contract code is open-source and verified on-chain. Can be audited anytime.</li>
        <li>Admin has no access to the prize pool. 15% of the bet amount is reserved to cover operational gas fees.</li>
        <li>All contract parameters and draws are handled on-chain, with full transparency and no admin interference.</li>
        <li>Only the player can withdraw their reward. Admin cannot access user funds.</li>
        <li><strong>Chainlink VRF</strong> provides verifiable random numbers to ensure fairness.</li>
        <li>Admin permissions are restricted. Your funds are secure.</li>
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