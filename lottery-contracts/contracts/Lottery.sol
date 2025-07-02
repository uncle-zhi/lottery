// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Lottery is VRFConsumerBaseV2Plus, ReentrancyGuardUpgradeable {
    // Chainlink VRF 配置 (Chainlink VRF configuration)
    // VRFConfig 用于存储 Chainlink VRF 的配置参数 (VRFConfig is used to store Chainlink VRF configuration parameters)
    struct VRFConfig {
        uint256 subscriptionId;
        address coordinator;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
        bool isNativePaymentEnabled;
    }

    // 彩票状态信息 (Lottery status information)
    struct LotteryInfo {
        uint32 round; // 当前轮次 (Current round)
        uint256 startNumber; //当前期的开始区块高度 (Start block number of current round)
        uint256 endNumber; //当前期的结束区块高度 (End block number of current round)
        bool isLotteryOpen; // 彩票是否开放 (Is the lottery open)
        uint128 totalPrizePool; // 累计奖金池 (Total prize pool)
        uint128 totalPendingRewards; // 总待领取奖金 (Total pending rewards)
        uint256 lastRequestId; // 最近的请求 ID (Last request ID)
        uint8 latestRandomNumber; // 最近的随机数 (Latest random number)
        uint8 rewardRate; // 返奖比例 (Reward rate)
        bool isDistributing; // 是否在派奖中 (Is distributing prizes)
        uint256 cumulativePrizeAmount; //累计中奖金额 (Cumulative prize amount)
        uint128 cumulativeWinners; //累计中奖人次 (Cumulative winners)
        uint64 distributedCount; //已经发奖人次 (Already distributed winners)
        uint128 cumulativePlayers; //累计投注人次 (Cumulative players)
        uint256 cumulativeBetAmount; //累计投注金额 (Cumulative bet amount)
    }
    // 购票信息 (Ticket information)
    struct Ticket {
        address player; // 购票者地址 (Ticket buyer address)
        uint128 amount; //投注金额 (Bet amount)
        uint8 number; // 购票号码 (Ticket number)
    }
    //玩家信息 (Player information)
    struct PlayerInfo {
        address player;
        uint128 currentBetAmount; //当前轮投注金额 (Current round bet amount)
        uint8 currentBetNumber; //当前轮投注号码 (Current round bet number)
        uint128 pendingPrize; //待领取奖金 (Pending prize)
    }

    VRFConfig public vrfConfig;
    LotteryInfo public lotteryInfo;

    // 定义枚举类型：彩票状态 (Define enum type: Lottery status)
    enum LotteryStatus {
        AcceptingBets, // 接受投注中 (Accepting bets)
        DelayRevealing, // 延时开奖中 (Delay revealing)
        WaitPreReveal, //等待预开奖 (Waiting for pre-reveal)
        PreRevealing, // 预开奖中 (Pre-revealing)
        WaitReveal, //预开奖完成，等待开奖（随机数已生成） (Pre-reveal finished, waiting for reveal (random number generated))
        Revealed, // 开奖完成 (Revealed)
        unknown //未知状态; (Unknown status)
    }

    mapping(uint32 => LotteryInfo) public roundLotteryInfo;
    mapping(uint32 => Ticket[]) public soldTickets; //某轮已售出的Tickets; (Tickets sold in a round)
    mapping(uint32 => mapping(address => bool)) public roundHasBought; // 防止重复购票 (Prevent duplicate ticket purchase)
    mapping(uint32 => mapping(uint8 => Ticket[])) public roundTicketsPerNumber; // 每个号码的购票记录 (Ticket records per number)
    mapping(address => uint128) public pendingRewards; // 存储每个玩家的待领取奖金 (Pending rewards for each player)

    uint public constant MIN_BET_AMOUNT = 0.01 ether; // 最小投注金额 (Minimum bet amount)
    uint8 public constant MAX_NUMBER = 5; // 最大购票号码 (Maximum ticket number)
    uint8 public constant MIN_NUMBER = 1; // 最小购票号码 (Minimum ticket number)
    uint8 public constant ROUND_DURATION = 10; // 每轮持续的区块数 (Blocks per round)
    uint32 public constant INIT_ROUND_DURATION = 100000000; //初始设置的每轮区间大小，在第一个人下注后，自动调整为下注区块高度+ROUND_DURATION ，以避免因无人投注而结束当前轮，浪费gas (Initial round duration, auto-adjust after first bet to avoid ending round with no bets)
    uint8 public constant DELAY_DURATION = 2; // 延迟开奖，防止矿工攻击，单位为区块数 (Delay reveal to prevent miner attack, in blocks)
    uint128 public constant PRE_DISTRIBUTE_PRIZES_REWARD = 0.001 ether; //为调用预开奖者发放奖励 (Reward for pre-reveal caller)
    uint128 public constant DISTRIBUTE_PRIZES_REWARD = 0.001 ether; //为调用预开奖者发放奖励 (Reward for distribute prizes caller)
    uint8 public constant BATCH_COUNT = 50; //批处理的数量, 每批次发奖的人数（避免多人中奖导致发奖时gas超出限制而失效） (Batch size for prize distribution to avoid gas limit issues)

    address public contractOwner;
    uint256 public initBlockNumber; // 合约部署时的区块高度,用于查询事件 (Block number at contract deployment, for event queries)

    event TicketPurchased(
        address indexed player,
        uint32 indexed round,
        uint8 number,
        uint128 amount
    ); //购买记录 (Ticket purchase record)
    event PrizeDistributed(address indexed player,uint32 indexed round,uint8 winNumber,uint128 betAmount,uint128 prizeAmount); //中奖记录事件 (Prize distribution event)uint128 amount); //中奖记录事件 (Prize distribution event)
    event PrizeClaimed(address indexed player, uint128 amount); //用户提取奖励事件 (Prize claim event)
    event WithdrawAll(address indexed owner, uint128 amount);
    event RandomNumberRequested(uint256 indexed requestId);
    event RandomNumberFulfilled(
        uint32 indexed round,
        uint8 randomNumber
    );
    event PreDistributePrizesEvent(uint32 indexed round);
    event DistributePrizesAndEndCurrentRoundEvent(
        uint32 indexed round,
        uint128 prizeAmount
    );

    event PreDistributeReward(address indexed player, uint256 reward);

    //确保合约不会接受直接的ETH转账，只能通过buyTicket函数参与 (Ensure contract does not accept direct ETH transfers, only via buyTicket)
    receive() external payable {
        revert(unicode"只允许通过投注参与 (Only participation via betting is allowed)");
    }

    // 确保在当前轮次内 (Ensure within current round)
    modifier onlyDuringRound() {
        require(
            getLotteryStatus() == LotteryStatus.AcceptingBets,
            unicode"不在售奖期内 (Not in ticket selling period)"
        );
        _;
    }

    modifier onlyNotInDuringRound() {
        require(
            getLotteryStatus() != LotteryStatus.AcceptingBets,
            unicode"在售奖期内 (In ticket selling period)"
        );
        _;
    }

    modifier onlyWaitPreReveal() {
        require(
            getLotteryStatus() == LotteryStatus.WaitPreReveal,
            unicode"不在等待预开奖的状态 (Not in waiting for pre-reveal status)"
        );
        _;
    }

    modifier onlyPreRevealing() {
        require(
            getLotteryStatus() == LotteryStatus.PreRevealing,
            unicode"不在预开奖的状态 (Not in pre-revealing status)"
        );
        _;
    }

    modifier onlyWaitReveal() {
        require(
            getLotteryStatus() == LotteryStatus.WaitReveal,
            unicode"不在等待开奖的状态 (Not in waiting for reveal status)"
        );
        _;
    }

    modifier onlyReveald() {
        require(
            getLotteryStatus() == LotteryStatus.Revealed,
            unicode"不在开奖结束的状态 (Not in revealed status)"
        );
        _;
    }

    modifier onlyCanStartNewRound() {
        require(
            getLotteryStatus() == LotteryStatus.Revealed ||
                lotteryInfo.round == 0,
            unicode"只有开奖结束或刚部署完合约时可以开始新一轮 (Can only start new round after reveal or after deployment)"
        );
        _;
    }

    constructor(
        uint256 subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint8 _rewardRate // 返奖比例，0-100 (Reward rate, 0-100)
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        require(_rewardRate > 0 && _rewardRate <= 100, unicode"无效的返奖比例 (Invalid reward rate)");
        contractOwner = msg.sender;
        initBlockNumber = block.number; // 记录合约部署时的区块高度 (Record block number at contract deployment)
        vrfConfig = VRFConfig({
            subscriptionId: subscriptionId,
            coordinator: _vrfCoordinator,
            keyHash: _keyHash,
            callbackGasLimit: 100000, // 默认值，可根据实际情况调整 (Default value, can be adjusted)
            requestConfirmations: 3, // 默认值，可根据实际情况调整 (Default value, can be adjusted)
            numWords: 1, // 默认值，可根据实际情况调整 (Default value, can be adjusted)
            isNativePaymentEnabled: false // 默认使用 LINK 支付 (Default use LINK payment)
        });
        lotteryInfo = LotteryInfo({
            round: 0,
            startNumber: 0,
            endNumber: 0,
            isLotteryOpen: false,
            totalPrizePool: 0,
            totalPendingRewards: 0,
            lastRequestId: 0,
            latestRandomNumber: 0,
            rewardRate: _rewardRate, // 设置返奖比例 (Set reward rate)
            isDistributing: false, // 初始化为 false (Initialize as false)
            cumulativePrizeAmount: 0, //累计中奖金额 (Cumulative prize amount)
            cumulativeWinners: 0, //累计中奖人次 (Cumulative winners)
            distributedCount: 0,   
            cumulativePlayers: 0, //累计投注人次 (Cumulative players)
            cumulativeBetAmount: 0 //累计投注金额 (Cumulative bet amount)
        });
    }

    // @param enableNativePayment: Set to `true` to enable payment in native tokens, or
    // `false` to pay in LINK
    function requestRandomNumber(
        bool enableNativePayment
    ) private  {
        try
            s_vrfCoordinator.requestRandomWords(
                VRFV2PlusClient.RandomWordsRequest({
                    keyHash: vrfConfig.keyHash,
                    subId: vrfConfig.subscriptionId,
                    requestConfirmations: vrfConfig.requestConfirmations,
                    callbackGasLimit: vrfConfig.callbackGasLimit,
                    numWords: vrfConfig.numWords,
                    extraArgs: VRFV2PlusClient._argsToBytes(
                        VRFV2PlusClient.ExtraArgsV1({
                            nativePayment: enableNativePayment
                        })
                    )
                })
            )
        returns (uint256 _requestId) {
            lotteryInfo.lastRequestId = _requestId;
            emit RandomNumberRequested(_requestId);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked(unicode"随机数请求失败：(Random number request failed:)", reason)));
        } catch {
            revert(unicode"VRF 随机数请求失败（未知错误） (VRF random number request failed (unknown error))");
        }
    }

    // Chainlink VRF 回调函数 (Chainlink VRF callback function)
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        require(
            _requestId == lotteryInfo.lastRequestId,
            "VRF: invalid requestId"
        );
        uint8 random = uint8((_randomWords[0] % MAX_NUMBER) + 1); // 1 到 5 (1 to 5)
        lotteryInfo.latestRandomNumber = random;
        emit RandomNumberFulfilled(lotteryInfo.round, random);
    }

    function getLotteryStatus() public view returns (LotteryStatus) {
        LotteryStatus status = LotteryStatus.unknown;
        if (
            block.number >= lotteryInfo.startNumber &&
            block.number <= lotteryInfo.endNumber &&
            lotteryInfo.isLotteryOpen
        ) {
            status = LotteryStatus.AcceptingBets; //接受投注中 (Accepting bets)
        } else if (
            block.number > lotteryInfo.endNumber &&
            block.number <= (lotteryInfo.endNumber + DELAY_DURATION)
        ) {
            status = LotteryStatus.DelayRevealing; //延迟开奖中 (Delay revealing)
        } else if (
            block.number > (lotteryInfo.endNumber + DELAY_DURATION) &&
            lotteryInfo.isLotteryOpen &&
            !lotteryInfo.isDistributing
        ) {
            status = LotteryStatus.WaitPreReveal; //等待预开奖 (Waiting for pre-reveal)
        } else if (
            block.number > (lotteryInfo.endNumber + DELAY_DURATION) &&
            !lotteryInfo.isLotteryOpen &&
            lotteryInfo.isDistributing &&
            lotteryInfo.latestRandomNumber == 0
        ) {
            status = LotteryStatus.PreRevealing; //预开奖中 (Pre-revealing)
        } else if (
            block.number > (lotteryInfo.endNumber + DELAY_DURATION) &&
            !lotteryInfo.isLotteryOpen &&
            lotteryInfo.isDistributing &&
            lotteryInfo.latestRandomNumber > 0
        ) {
            status = LotteryStatus.WaitReveal; //等待开奖 (Waiting for reveal)
        } else if (
            block.number > (lotteryInfo.endNumber + DELAY_DURATION) &&
            !lotteryInfo.isLotteryOpen &&
            !lotteryInfo.isDistributing
        ) {
            status = LotteryStatus.Revealed; // 开奖结束 (Revealed)
        }
        return status;
    }

    //开始新一轮 (Start a new round)
    function startNewRound()
        external
        onlyOwner
        onlyCanStartNewRound
        nonReentrant
    {
        //确保开始新一轮时，上一轮已经结束并且派奖已完成 (Ensure previous round ended and prizes distributed before starting new round)
        lotteryInfo.isLotteryOpen = true; //记录彩票开放状态 (Record lottery open status)
        lotteryInfo.round++; // 增加轮次 (Increase round)
        lotteryInfo.latestRandomNumber = 0;
        lotteryInfo.startNumber = block.number; // 记录开始区块高度 (Record start block number)
        lotteryInfo.endNumber = lotteryInfo.startNumber + INIT_ROUND_DURATION; // 记录结束区块高度 (Record end block number)
        if (lotteryInfo.distributedCount != 0) {
            lotteryInfo.distributedCount = 0; //重置已派送人数 (Reset distributed count)
        }
    }

    //预开奖调用，因为开奖需要通过chainlink vrf获取随机数，所以需要使用两阶段进行开奖，这里只预开奖，不派奖 (Pre-reveal, as random number needs to be fetched via Chainlink VRF, so two-stage reveal, this is only pre-reveal, not prize distribution)
    function preDistributePrizes() external onlyWaitPreReveal nonReentrant {
        //给调用者奖励 0.001 ETH (Reward the caller 0.001 ETH)
        uint128 reward = PRE_DISTRIBUTE_PRIZES_REWARD;
        require(
            address(this).balance >= reward,
            unicode"合约余额不足，无法发放奖励 (Insufficient contract balance to reward)"
        );
        (bool sent, ) = payable(msg.sender).call{value: reward}("");
        require(sent, unicode"奖励转账失败 (Reward transfer failed)");

        lotteryInfo.isLotteryOpen = false; // 记录彩票为关闭状态 (Set lottery as closed)
        lotteryInfo.isDistributing = true; // 标记为正在派奖状态 (Mark as distributing)
        emit PreDistributePrizesEvent(lotteryInfo.round); // 记录预开奖事件 (Log pre-reveal event)

        requestRandomNumber(vrfConfig.isNativePaymentEnabled); // 请求随机数，在 Chainlink VRF 回调中处理，调用派奖函数 (Request random number, prize distribution handled in callback)
        // 可选：增加事件 (Optional: add event)
        emit PreDistributeReward(msg.sender, reward);
    }

    //派奖并结束当前轮次，在监控到 Chainlink VRF 回调后调 (Distribute prizes and end current round, called after Chainlink VRF callback)
    function distributePrizesAndEndCurrentRound()
        external
        onlyWaitReveal
        nonReentrant
    {
        //给调用者奖励 0.001 ETH (Reward the caller 0.001 ETH)
        uint128 reward = DISTRIBUTE_PRIZES_REWARD;
        require(
            address(this).balance >= reward,
            unicode"合约余额不足，无法发放奖励 (Insufficient contract balance to reward)"
        );
        (bool sent, ) = payable(msg.sender).call{value: reward}("");
        require(sent, unicode"奖励转账失败 (Reward transfer failed)");

        uint8 winNumber = lotteryInfo.latestRandomNumber; // 中奖号码 (Winning number)
        uint64 distributedCount = lotteryInfo.distributedCount; // 已经派送人数 (Already distributed winners)
        uint64 winnerCount = uint64(
            roundTicketsPerNumber[lotteryInfo.round][winNumber].length
        ); //中奖人数 (Number of winners)
        uint64 undistributedCount = winnerCount - distributedCount; //未派送人数 (Undistributed winners)
        uint128 totalAmountForWinningNumber = getTotalAmountForNumber(
            winNumber
        ); // 中奖号码的投注总额 (Total bet amount for winning number)

        // 遍历本轮中奖者记录，按投注金额分配奖金 (Iterate winners and distribute prizes by bet amount)
        uint128 currentRoundTotalPrizeAmount = 0;
        if (totalAmountForWinningNumber > 0) { //大于0，说明有中奖者 (If >0, there are winners)
            uint128 currentRoundTotalAmount = getCurrentRoundTotalAmount();//当轮的总投注额 (Total bet amount this round)
            uint128 currentRoundPrizePool = (currentRoundTotalAmount *    //计算出历史池 (Calculate current prize pool)
                lotteryInfo.rewardRate) / 100;
            uint128 historyPrizePool = 0; //本轮之前的累计奖池 (Prize pool before this round)
            if (lotteryInfo.totalPrizePool > currentRoundPrizePool) {
                historyPrizePool =
                    lotteryInfo.totalPrizePool -
                    currentRoundPrizePool;
            }
            uint128 distributePrize = currentRoundPrizePool +
                ((historyPrizePool * lotteryInfo.rewardRate) / 100);    //计算出本轮应派奖总金额 (Total prize to distribute this round)

            if (undistributedCount > 0) {
                //每个中奖者按投注金额与中奖号码的投注总额比例分配奖金 (Each winner gets prize proportional to their bet)
                uint64 count = 0; //记录当次发奖的数量，以控制在BATCH_COUNT 内 (Count for this batch, limit by BATCH_COUNT)
                for (uint256 i = distributedCount; i < winnerCount; i++) {
                    if (count >= BATCH_COUNT) {
                        break;
                    }
                    Ticket memory ticket = roundTicketsPerNumber[
                        lotteryInfo.round
                    ][winNumber][i];
                    uint128 prizeAmount = (ticket.amount * distributePrize) /
                        totalAmountForWinningNumber;
                    pendingRewards[ticket.player] += prizeAmount; // 记录每个玩家的待领取奖金 (Record pending prize for each player)
                    currentRoundTotalPrizeAmount += prizeAmount; // 更新待领取奖金 (Update total pending prize)
                    count++;
                    distributedCount++;
                    emit PrizeDistributed(ticket.player,lotteryInfo.round,winNumber,ticket.amount, prizeAmount);
                }
                lotteryInfo.cumulativeWinners += count; //更新累计中奖人数 (Update cumulative winners)
                lotteryInfo
                    .cumulativePrizeAmount += currentRoundTotalPrizeAmount; //累计奖金 (Update cumulative prize amount)
                lotteryInfo.totalPendingRewards += currentRoundTotalPrizeAmount; //更新待派奖金 (Update total pending rewards)
                lotteryInfo.distributedCount = distributedCount; //更新已派送的人数 (Update distributed count)
                if (distributedCount == winnerCount) {
                    //已派送的人数如果等于中奖人数，表示本轮的奖金已经派送完毕 (If all prizes distributed, end round)
                    lotteryInfo.totalPrizePool = lotteryInfo.totalPrizePool - distributePrize;
                    endCurrentRound();
                }
            } else {
                lotteryInfo.totalPrizePool =  lotteryInfo.totalPrizePool - distributePrize;
                endCurrentRound();
            }
        } else {
            endCurrentRound(); // 结束当前轮 (End current round)
        }
        emit DistributePrizesAndEndCurrentRoundEvent(
            lotteryInfo.round,
            currentRoundTotalPrizeAmount
        ); // 记录派奖事件 (Log prize distribution event)
    }

    //任何时候，任何人都可以调用此函数领取自己的奖金 (Anyone can claim their prize at any time)
    function claimPrize() external nonReentrant {
        uint128 prizeAmount = pendingRewards[msg.sender];
        require(prizeAmount > 0, unicode"没有可领取的奖金 (No prize to claim)");
        pendingRewards[msg.sender] = 0; // 清除待领取奖金 (Clear pending prize)
        lotteryInfo.totalPendingRewards -= prizeAmount; // 更新总待领取奖金 (Update total pending rewards)
        (bool sent, ) = payable(msg.sender).call{value: prizeAmount}("");
        require(sent, unicode"奖金转账失败 (Prize transfer failed)");
        emit PrizeClaimed(msg.sender, prizeAmount);
    }

    //获取当前轮指定号码的投注总额 (Get total bet amount for a number in current round)
    function getTotalAmountForNumber(
        uint8 number
    ) public view returns (uint128) {
        require(
            number >= MIN_NUMBER && number <= MAX_NUMBER,
            unicode"无效的号码 (Invalid number)"
        );
        uint128 totalAmount = 0;
        Ticket[] memory tickets = roundTicketsPerNumber[lotteryInfo.round][
            number
        ];
        for (uint128 i = 0; i < tickets.length; i++) {
            totalAmount += tickets[i].amount;
        }
        return totalAmount;
    }

    //查询当前轮的总投注人数 (Get total ticket count for current round)
    function getCurrentTicketsCount() external view returns (uint256) {
        return soldTickets[lotteryInfo.round].length;
    }

    // 获取当前轮次的投注总额 (Get total bet amount for current round)
    function getCurrentRoundTotalAmount() public view returns (uint128) {
        uint128 totalAmount = 0;
        for (uint256 i = 0; i < soldTickets[lotteryInfo.round].length; i++) {
            totalAmount += soldTickets[lotteryInfo.round][i].amount;
        }
        return totalAmount;
    }

    //查询自己在当前轮次的投注记录 (Get your ticket for current round)
    function getMyTicket() external view returns (address, uint128, uint8) {
        return getPlayerTicket(msg.sender);
    }

    //查询某玩家当前轮次的投注记录 (Get a player's ticket for current round)
    function getPlayerTicket(
        address player
    ) public view returns (address, uint128, uint8) {
        Ticket memory ticket;
        for (uint256 i = 0; i < soldTickets[lotteryInfo.round].length; i++) {
            if (soldTickets[lotteryInfo.round][i].player == player) {
                ticket = soldTickets[lotteryInfo.round][i];
                break; // 找到后退出循环 ,因为每个玩家在当前轮次只能有一张票 (Break after found, only one ticket per player per round)
            }
        }

        return (ticket.player, ticket.amount, ticket.number);
    }

    function getPlayerInfo(
        address _player
    ) public view returns (PlayerInfo memory) {
        PlayerInfo memory playerInfo;
        (, uint128 amount, uint8 number) = getPlayerTicket(_player); //当前的轮的购票情况 (Current round ticket info)
        playerInfo.player = _player;
        playerInfo.currentBetAmount = amount;
        playerInfo.currentBetNumber = number;
        playerInfo.pendingPrize = pendingRewards[_player];
        return playerInfo;
    }

    //关闭当前轮次 (Close current round)
    function endCurrentRound() private {
        lotteryInfo.cumulativePlayers += uint128(soldTickets[lotteryInfo.round].length); //更新累计投注人数 (Update cumulative players)
        lotteryInfo.cumulativeBetAmount += getCurrentRoundTotalAmount(); //更新累计投注总额 (Update cumulative bet amount)

        roundLotteryInfo[lotteryInfo.round] = lotteryInfo; //保存当轮信息 (Save round info)
        lotteryInfo.isLotteryOpen = false; // 重置彩票开放状态 (Reset lottery open status)
        lotteryInfo.isDistributing = false; // 重置派奖状态 (Reset distributing status)
    }

    function buyTicket(uint8 number) external payable onlyDuringRound {
        require(
            number >= MIN_NUMBER && number <= MAX_NUMBER,
            unicode"号码必须在 1-5 之间 (Number must be between 1 and 5)"
        );
        require(
            !roundHasBought[lotteryInfo.round][msg.sender],
            unicode"本轮已购票 (Already bought ticket this round)"
        );
        // 确保投注金额大于等于最小投注金额 (Ensure bet amount >= minimum)
        require(
            msg.value >= MIN_BET_AMOUNT,
            unicode"最小投注金额为 0.01 ether (Minimum bet is 0.01 ether)"
        );
        require(msg.value <= type(uint128).max, unicode"投注金额过大 (Bet amount too large)");
        Ticket memory ticket = Ticket({
            player: msg.sender,
            amount: uint128(msg.value),
            number: number
        });
        if (soldTickets[lotteryInfo.round].length == 0) {
            //当本轮的第1个人购买彩票时，重置结束区块号 (If first ticket this round, reset end block)
            lotteryInfo.endNumber = block.number + ROUND_DURATION;
        }
        soldTickets[lotteryInfo.round].push(ticket);
        roundTicketsPerNumber[lotteryInfo.round][number].push(ticket);
        roundHasBought[lotteryInfo.round][msg.sender] = true;
        //更新奖金池 (Update prize pool)
        lotteryInfo.totalPrizePool =
            lotteryInfo.totalPrizePool +
            ((uint128(msg.value) * lotteryInfo.rewardRate) / 100); //当前的奖金池 = 累计奖金池 + (当前轮次投注总额 * 返奖比例) (Current prize pool = total + (current round bet * reward rate))
        emit TicketPurchased(
            msg.sender,
            lotteryInfo.round,
            number,
            uint128(msg.value)
        ); // 记录购票事件 (Log ticket purchase)
    }

    function getTickets() external view returns (Ticket[] memory) {
        return soldTickets[lotteryInfo.round];
    }

    /// @notice 提取合约剩余资金，仅限 owner 调用，并在彩票关闭后调用 (Withdraw contract remaining funds, only owner, only after lottery closed)
    function withdrawAll() external onlyOwner onlyReveald nonReentrant {
        uint256 reserved = uint256(lotteryInfo.totalPendingRewards) +
            uint256(lotteryInfo.totalPrizePool);
        uint256 balance = address(this).balance;
        require(balance > reserved, unicode"没有可提取的余额 (No withdrawable balance)");
        uint256 allowedBalance = balance - reserved; // 减去待领取奖金,只能提取合约剩余资金 (Subtract pending prizes, only withdraw remaining)
        (bool sent, ) = payable(contractOwner).call{value: allowedBalance}("");
        require(sent, unicode"提取失败 (Withdraw failed)");
        emit WithdrawAll(contractOwner, uint128(allowedBalance)); // 提取成功 (Withdraw success)
    }

    //模拟预开奖（用于测试） (Simulate pre-dis (for testing))
    function simulatePreDis(uint8 number) external onlyOwner {
        lotteryInfo.latestRandomNumber = number;
        lotteryInfo.isDistributing = true;
        lotteryInfo.isLotteryOpen = false;
    }
}