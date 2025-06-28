// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Lottery is VRFConsumerBaseV2Plus, ReentrancyGuardUpgradeable {
    // Chainlink VRF 配置
    // VRFConfig 用于存储 Chainlink VRF 的配置参数
    struct VRFConfig {
        uint256 subscriptionId;
        address coordinator;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
        bool isNativePaymentEnabled;
    }

    // 彩票状态信息
    struct LotteryInfo {
        uint32 round; // 当前轮次
        uint256 startNumber; //当前期的开始区块高度
        uint256 endNumber; //当前期的结束区块高度
        bool isLotteryOpen; // 彩票是否开放
        uint128 totalPrizePool; // 累计奖金池
        uint128 totalPendingRewards; // 总待领取奖金
        uint256 lastRequestId; // 最近的请求 ID
        uint8 latestRandomNumber; // 最近的随机数
        uint8 rewardRate; // 返奖比例
        bool isDistributing; // 是否在派奖中
        uint256 cumulativePrizeAmount; //累计中奖金额
        uint128 cumulativeWinners; //累计中奖人次
        uint64 distributedCount; //已经发奖人次
    }
    // 购票信息
    struct Ticket {
        address player; // 购票者地址
        uint128 amount; //投注金额
        uint8 number; // 购票号码
    }
    //玩家信息
    struct PlayerInfo {
        address player;
        uint128 currentBetAmount; //当前轮投注金额
        uint8 currentBetNumber; //当前轮投注号码
        uint128 pendingPrize; //待领取奖金
    }

    VRFConfig public vrfConfig;
    LotteryInfo public lotteryInfo;

    // 定义枚举类型：彩票状态
    enum LotteryStatus {
        AcceptingBets, // 接受投注中
        DelayRevealing, // 延时开奖中
        WaitPreReveal, //等待预开奖
        PreRevealing, // 预开奖中
        WaitReveal, //预开奖完成，等待开奖（随机数已生成）
        Revealed, // 开奖完成
        unknown //未知状态;
    }

    mapping(uint32 => LotteryInfo) public roundLotteryInfo;
    mapping(uint32 => Ticket[]) public soldTickets; //某轮已售出的Tickets;
    mapping(uint32 => mapping(address => bool)) public roundHasBought; // 防止重复购票
    mapping(uint32 => mapping(uint8 => Ticket[])) public roundTicketsPerNumber; // 每个号码的购票记录
    mapping(address => uint128) public pendingRewards; // 存储每个玩家的待领取奖金

    //投注最小金额
    uint public constant MIN_BET_AMOUNT = 0.01 ether; // 最小投注金额
    uint8 public constant MAX_NUMBER = 50; // 最大购票号码
    uint8 public constant MIN_NUMBER = 1; // 最小购票号码
    uint8 public constant ROUND_DURATION = 10; // 每轮持续的区块数
    uint32 public constant INIT_ROUND_DURATION = 100000000; //初始设置的每轮区间大小，在第一个人下注后，自动调整为下注区块高度+ROUND_DURATION ，以避免因无人投注而结束当前轮，浪费gas
    uint8 public constant DELAY_DURATION = 2; // 延迟开奖，防止矿工攻击，单位为区块数
    uint128 public constant PRE_DISTRIBUTE_PRIZES_REWARD = 0.001 ether; //为调用预开奖者发放奖励
    uint128 public constant DISTRIBUTE_PRIZES_REWARD = 0.001 ether; //为调用预开奖者发放奖励
    uint8 public constant BATCH_COUNT = 2; //批处理的数量, 每批次发奖的人数（避免多人中奖导致发奖时gas超出限制而失效）

    address public contractOwner;
    uint256 public initBlockNumber; // 合约部署时的区块高度,用于查询事件

    event TicketPurchased(
        address indexed player,
        uint32 indexed round,
        uint8 number,
        uint128 amount
    ); //购买记录
    event PrizeDistributed(address indexed player, uint128 amount); //中奖记录事件
    event PrizeClaimed(address indexed player, uint128 amount); //用户提取奖励事件
    event WithdrawAll(address indexed owner, uint128 amount);
    event RandomNumberRequested(uint256 indexed requestId);
    event RandomNumberFulfilled(
        uint256 indexed requestId,
        uint8 randomNumber,
        uint256 originalRandomNumber
    );
    event PreDistributePrizesEvent(uint32 indexed round);
    event DistributePrizesAndEndCurrentRoundEvent(
        uint32 indexed round,
        uint128 prizeAmount
    );
    event RefundTicketsEvent(
        uint32 indexed round,
        address indexed player,
        uint64 totalPlayer,
        uint256 totalAmount
    );
    event PreDistributeReward(address indexed player, uint256 reward);

    //确保合约不会接受直接的ETH转账，只能通过buyTicket函数参与
    receive() external payable {
        revert(unicode"只允许通过投注参与");
    }

    // 确保在当前轮次内
    modifier onlyDuringRound() {
        require(
            getLotteryStatus() == LotteryStatus.AcceptingBets,
            unicode"不在售奖期内"
        );
        _;
    }

    modifier onlyNotInDuringRound() {
        require(
            getLotteryStatus() != LotteryStatus.AcceptingBets,
            unicode"在售奖期内"
        );
        _;
    }

    modifier onlyWaitPreReveal() {
        require(
            getLotteryStatus() == LotteryStatus.WaitPreReveal,
            unicode"不在等待预开奖的状态"
        );
        _;
    }

    modifier onlyPreRevealing() {
        require(
            getLotteryStatus() == LotteryStatus.PreRevealing,
            unicode"不在预开奖的状态"
        );
        _;
    }

    modifier onlyWaitReveal() {
        require(
            getLotteryStatus() == LotteryStatus.WaitReveal,
            unicode"不在等待开奖的状态"
        );
        _;
    }

    modifier onlyReveald() {
        require(
            getLotteryStatus() == LotteryStatus.Revealed,
            unicode"不在开奖结束的状态"
        );
        _;
    }

    modifier onlyCanStartNewRound() {
        require(
            getLotteryStatus() == LotteryStatus.Revealed ||
                lotteryInfo.round == 0,
            unicode"只有开奖结束或刚部署完合约时可以开始新一轮"
        );
        _;
    }

    constructor(
        uint256 subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint8 _rewardRate // 返奖比例，0-100
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        require(_rewardRate > 0 && _rewardRate <= 100, unicode"无效的返奖比例");
        contractOwner = msg.sender;
        initBlockNumber = block.number; // 记录合约部署时的区块高度
        vrfConfig = VRFConfig({
            subscriptionId: subscriptionId,
            coordinator: _vrfCoordinator,
            keyHash: _keyHash,
            callbackGasLimit: 100000, // 默认值，可根据实际情况调整
            requestConfirmations: 3, // 默认值，可根据实际情况调整
            numWords: 1, // 默认值，可根据实际情况调整
            isNativePaymentEnabled: false // 默认使用 LINK 支付
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
            rewardRate: _rewardRate, // 设置返奖比例
            isDistributing: false, // 初始化为 false
            cumulativePrizeAmount: 0, //累计中奖金额
            cumulativeWinners: 0, //累计中奖人次
            distributedCount: 0
        });
    }

    // @param enableNativePayment: Set to `true` to enable payment in native tokens, or
    // `false` to pay in LINK
    function requestRandomNumber(
        bool enableNativePayment
    ) private returns (uint256 requestId) {
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
            emit RandomNumberRequested(requestId);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked(unicode"随机数请求失败：", reason)));
        } catch {
            revert(unicode"VRF 随机数请求失败（未知错误）");
        }
    }

    // Chainlink VRF 回调函数
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        require(
            _requestId == lotteryInfo.lastRequestId,
            "VRF: invalid requestId"
        );
        uint8 random = uint8((_randomWords[0] % MAX_NUMBER) + 1); // 1 到 50
        lotteryInfo.latestRandomNumber = random;
        emit RandomNumberFulfilled(_requestId, random, _randomWords[0]);
    }

    function getLotteryStatus() public view returns (LotteryStatus) {
        LotteryStatus status = LotteryStatus.unknown;
        if (
            block.number >= lotteryInfo.startNumber &&
            block.number <= lotteryInfo.endNumber &&
            lotteryInfo.isLotteryOpen
        ) {
            status = LotteryStatus.AcceptingBets; //接受投注中
        } else if (
            block.number > lotteryInfo.endNumber &&
            block.number <= (lotteryInfo.endNumber + DELAY_DURATION)
        ) {
            status = LotteryStatus.DelayRevealing; //延迟开奖中
        } else if (
            block.number > (lotteryInfo.endNumber + DELAY_DURATION) &&
            lotteryInfo.isLotteryOpen &&
            !lotteryInfo.isDistributing
        ) {
            status = LotteryStatus.WaitPreReveal; //等待预开奖
        } else if (
            block.number > (lotteryInfo.endNumber + DELAY_DURATION) &&
            !lotteryInfo.isLotteryOpen &&
            lotteryInfo.isDistributing &&
            lotteryInfo.latestRandomNumber == 0
        ) {
            status = LotteryStatus.PreRevealing; //预开奖中
        } else if (
            block.number > (lotteryInfo.endNumber + DELAY_DURATION) &&
            !lotteryInfo.isLotteryOpen &&
            lotteryInfo.isDistributing &&
            lotteryInfo.latestRandomNumber > 0
        ) {
            status = LotteryStatus.WaitReveal; //等待开奖
        } else if (
            block.number > (lotteryInfo.endNumber + DELAY_DURATION) &&
            !lotteryInfo.isLotteryOpen &&
            !lotteryInfo.isDistributing
        ) {
            status = LotteryStatus.Revealed; // 开奖结束
        }
        return status;
    }

    //开始新一轮
    function startNewRound()
        external
        onlyOwner
        onlyCanStartNewRound
        nonReentrant
    {
        //确保开始新一轮时，上一轮已经结束并且派奖已完成
        lotteryInfo.isLotteryOpen = true; //记录彩票开放状态
        lotteryInfo.round++; // 增加轮次
        lotteryInfo.latestRandomNumber = 0;
        lotteryInfo.startNumber = block.number; // 记录开始区块高度
        lotteryInfo.endNumber = lotteryInfo.startNumber + INIT_ROUND_DURATION; // 记录结束区块高度
        if (lotteryInfo.distributedCount != 0) {
            lotteryInfo.distributedCount = 0; //重置已派送人数
        }
    }

    //预开奖调用，因为开奖需要通过chainlink vrf获取随机数，所以需要使用两阶段进行开奖，这里只预开奖，不派奖
    function preDistributePrizes() external onlyWaitPreReveal nonReentrant {
        //给调用者奖励 0.001 ETH
        uint128 reward = PRE_DISTRIBUTE_PRIZES_REWARD;
        require(
            address(this).balance >= reward,
            unicode"合约余额不足，无法发放奖励"
        );
        (bool sent, ) = payable(msg.sender).call{value: reward}("");
        require(sent, unicode"奖励转账失败");

        lotteryInfo.isLotteryOpen = false; // 记录彩票为关闭状态
        lotteryInfo.isDistributing = true; // 标记为正在派奖状态
        emit PreDistributePrizesEvent(lotteryInfo.round); // 记录预开奖事件

        requestRandomNumber(vrfConfig.isNativePaymentEnabled); // 请求随机数，在 Chainlink VRF 回调中处理，调用派奖函数
        // 可选：增加事件
        emit PreDistributeReward(msg.sender, reward);
    }

    //派奖并结束当前轮次，在监控到 Chainlink VRF 回调后调
    function distributePrizesAndEndCurrentRound()
        external
        onlyWaitReveal
        nonReentrant
    {
        //给调用者奖励 0.001 ETH
        uint128 reward = DISTRIBUTE_PRIZES_REWARD;
        require(
            address(this).balance >= reward,
            unicode"合约余额不足，无法发放奖励"
        );
        (bool sent, ) = payable(msg.sender).call{value: reward}("");
        require(sent, unicode"奖励转账失败");

        uint8 winNumber = lotteryInfo.latestRandomNumber; // 中奖号码
        uint64 distributedCount = lotteryInfo.distributedCount; // 已经派送人数
        uint64 winnerCount = uint64(
            roundTicketsPerNumber[lotteryInfo.round][winNumber].length
        ); //中奖人数
        uint64 undistributedCount = winnerCount - distributedCount; //未派送人数
        uint128 totalAmountForWinningNumber = getTotalAmountForNumber(
            winNumber
        ); // 中奖号码的投注总额

        // 遍历本轮中奖者记录，按投注金额分配奖金
        uint128 currentRoundTotalPrizeAmount = 0;
        if (totalAmountForWinningNumber > 0) { //大于0，说明有中奖者
            uint128 currentRoundTotalAmount = getCurrentRoundTotalAmount();//当轮的总投注额
            uint128 currentRoundPrizePool = (currentRoundTotalAmount *    //计算出历史池
                lotteryInfo.rewardRate) / 100;
            uint128 historyPrizePool = 0; //本轮之前的累计奖池
            if (lotteryInfo.totalPrizePool > currentRoundPrizePool) {
                historyPrizePool =
                    lotteryInfo.totalPrizePool -
                    currentRoundPrizePool;
            }
            uint128 distributePrize = currentRoundPrizePool +
                ((historyPrizePool * lotteryInfo.rewardRate) / 100);    //计算出本轮应派奖总金额

            if (undistributedCount > 0) {
                //每个中奖者按投注金额与中奖号码的投注总额比例分配奖金

                uint64 count = 0; //记录当次发奖的数量，以控制在BATCH_COUNT 内
                for (uint256 i = distributedCount; i < winnerCount; i++) {
                    if (count >= BATCH_COUNT) {
                        break;
                    }
                    Ticket memory ticket = roundTicketsPerNumber[
                        lotteryInfo.round
                    ][winNumber][i];
                    uint128 prizeAmount = (ticket.amount * distributePrize) /
                        totalAmountForWinningNumber;
                    pendingRewards[ticket.player] += prizeAmount; // 记录每个玩家的待领取奖金
                    currentRoundTotalPrizeAmount += prizeAmount; // 更新待领取奖金
                    count++;
                    distributedCount++;
                    emit PrizeDistributed(ticket.player, prizeAmount);
                }
                lotteryInfo.cumulativeWinners += count; //更新累计中奖人数
                lotteryInfo
                    .cumulativePrizeAmount += currentRoundTotalPrizeAmount; //累计奖金
                lotteryInfo.totalPendingRewards += currentRoundTotalPrizeAmount; //更新待派奖金
                lotteryInfo.distributedCount = distributedCount; //更新已派送的人数
                if (distributedCount == winnerCount) {
                    //已派送的人数如果等于中奖人数，表示本轮的奖金已经派送完毕
                    lotteryInfo.totalPrizePool = lotteryInfo.totalPrizePool - distributePrize;
                    endCurrentRound();
                }
            } else {
                lotteryInfo.totalPrizePool =  lotteryInfo.totalPrizePool - distributePrize;
                endCurrentRound();
            }
        } else {
            endCurrentRound(); // 结束当前轮
        }
        emit DistributePrizesAndEndCurrentRoundEvent(
            lotteryInfo.round,
            currentRoundTotalPrizeAmount
        ); // 记录派奖事件
    }

    //任何时候，任何人都可以调用此函数领取自己的奖金
    function claimPrize() external nonReentrant {
        uint128 prizeAmount = pendingRewards[msg.sender];
        require(prizeAmount > 0, unicode"没有可领取的奖金");
        pendingRewards[msg.sender] = 0; // 清除待领取奖金
        lotteryInfo.totalPendingRewards -= prizeAmount; // 更新总待领取奖金
        (bool sent, ) = payable(msg.sender).call{value: prizeAmount}("");
        require(sent, unicode"奖金转账失败");
        emit PrizeClaimed(msg.sender, prizeAmount);
    }

    //获取当前轮指定号码的投注总额
    function getTotalAmountForNumber(
        uint8 number
    ) public view returns (uint128) {
        require(
            number >= MIN_NUMBER && number <= MAX_NUMBER,
            unicode"无效的号码"
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

    //查询当前轮的总投注人数
    function getCurrentTicketsCount() external view returns (uint256) {
        return soldTickets[lotteryInfo.round].length;
    }

    // 获取当前轮次的投注总额
    function getCurrentRoundTotalAmount() public view returns (uint128) {
        uint128 totalAmount = 0;
        for (uint256 i = 0; i < soldTickets[lotteryInfo.round].length; i++) {
            totalAmount += soldTickets[lotteryInfo.round][i].amount;
        }
        return totalAmount;
    }

    //查询自己在当前轮次的投注记录
    function getMyTicket() external view returns (address, uint128, uint8) {
        return getPlayerTicket(msg.sender);
    }

    //查询某玩家当前轮次的投注记录
    function getPlayerTicket(
        address player
    ) public view returns (address, uint128, uint8) {
        Ticket memory ticket;
        for (uint256 i = 0; i < soldTickets[lotteryInfo.round].length; i++) {
            if (soldTickets[lotteryInfo.round][i].player == player) {
                ticket = soldTickets[lotteryInfo.round][i];
                break; // 找到后退出循环 ,因为每个玩家在当前轮次只能有一张票
            }
        }

        return (ticket.player, ticket.amount, ticket.number);
    }

    function getPlayerInfo(
        address _player
    ) public view returns (PlayerInfo memory) {
        PlayerInfo memory playerInfo;
        (, uint128 amount, uint8 number) = getPlayerTicket(_player); //当前的轮的购票情况
        playerInfo.player = _player;
        playerInfo.currentBetAmount = amount;
        playerInfo.currentBetNumber = number;
        playerInfo.pendingPrize = pendingRewards[_player];
        return playerInfo;
    }

    //关闭当前轮次
    function endCurrentRound() private {
        roundLotteryInfo[lotteryInfo.round] = lotteryInfo; //保存当轮信息
        lotteryInfo.isLotteryOpen = false; // 重置彩票开放状态
        lotteryInfo.isDistributing = false; // 重置派奖状态
    }

    function buyTicket(uint8 number) external payable onlyDuringRound {
        require(
            number >= MIN_NUMBER && number <= MAX_NUMBER,
            unicode"号码必须在 1-50 之间"
        );
        require(
            !roundHasBought[lotteryInfo.round][msg.sender],
            unicode"本轮已购票"
        );
        // 确保投注金额大于等于最小投注金额
        require(
            msg.value >= MIN_BET_AMOUNT,
            unicode"最小投注金额为 0.01 ether"
        );
        require(msg.value <= type(uint128).max, unicode"投注金额过大");
        Ticket memory ticket = Ticket({
            player: msg.sender,
            amount: uint128(msg.value),
            number: number
        });
        if (soldTickets[lotteryInfo.round].length == 0) {
            //当本轮的第1个人购买彩票时，重置结束区块号
            lotteryInfo.endNumber = block.number + ROUND_DURATION;
        }
        soldTickets[lotteryInfo.round].push(ticket);
        roundTicketsPerNumber[lotteryInfo.round][number].push(ticket);
        roundHasBought[lotteryInfo.round][msg.sender] = true;
        //更新奖金池
        lotteryInfo.totalPrizePool =
            lotteryInfo.totalPrizePool +
            ((uint128(msg.value) * lotteryInfo.rewardRate) / 100); //当前的奖金池 = 累计奖金池 + (当前轮次投注总额 * 返奖比例)
        emit TicketPurchased(
            msg.sender,
            lotteryInfo.round,
            number,
            uint128(msg.value)
        ); // 记录购票事件
    }

    function getTickets() external view returns (Ticket[] memory) {
        return soldTickets[lotteryInfo.round];
    }

    /// @notice 提取合约剩余资金，仅限 owner 调用，并在彩票关闭后调用
    function withdrawAll() external onlyOwner onlyReveald nonReentrant {
        uint256 reserved = uint256(lotteryInfo.totalPendingRewards) +
            uint256(lotteryInfo.totalPrizePool);
        uint256 balance = address(this).balance;
        require(balance > reserved, unicode"没有可提取的余额");
        uint256 allowedBalance = balance - reserved; // 减去待领取奖金,只能提取合约剩余资金
        (bool sent, ) = payable(contractOwner).call{value: allowedBalance}("");
        require(sent, unicode"提取失败");
        emit WithdrawAll(contractOwner, uint128(allowedBalance)); // 提取成功
    }

    //因为要测试中奖后的情况，所以添加一个函数，控制中奖号吗，在正式环境中要删除
    function setLatestRandomNumber(uint8 number) external onlyOwner {
        lotteryInfo.latestRandomNumber = number;
    }
}
