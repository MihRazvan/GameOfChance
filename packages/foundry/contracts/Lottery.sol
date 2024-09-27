// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Lottery is VRFConsumerBaseV2Plus {
    using PriceConverter for uint256;

    /** Events */
    event LotteryFunded(address indexed sender, uint256 amountSent);
    event RequestSent(uint256 requestId);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event WinnerPicked(
        address winner,
        uint256 amountWon,
        uint256 numberOfParticipants
    );

    /** Errors */
    error NotEnoughEthFunded();
    error Lottery__TransferFailed();
    error Lottery__NoParticipants();
    error Lottery__NotEndedYet();
    error Lottery__LotteryNotOpen();

    /** Type declarations */
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    /** Constants */
    uint256 private constant LOTTERY_DURATION = 3 minutes;
    uint256 private constant MIN_AMOUNT_TO_FUND = 50 * 1e18;

    /** Lottery Variables */
    address payable[] private s_participants;
    AggregatorV3Interface private s_priceFeed;
    mapping(address => uint256) private s_participantsToAmountFunded;
    uint256 private s_lotteryStartTime;
    address private s_recentWinner;

    // Chainlink VRF Variables
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // Past request IDs.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    /** Lottery States */
    enum LotteryState {
        OPEN,
        CALCULATING
    }
    LotteryState private s_lotteryState;

    constructor(
        address priceFeed,
        address vrfCoordinator,
        uint256 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        s_lotteryStartTime = block.timestamp;
    }

    function getEtherInUsd(uint256 _ethValue) public view returns (uint256) {
        return _ethValue.getConversionRate(s_priceFeed);
    }

    function fundLottery() public payable {
        require(s_lotteryState == LotteryState.OPEN, "Lottery is not open");

        uint256 ethAmountInUsd = msg.value.getConversionRate(s_priceFeed);
        if (ethAmountInUsd < MIN_AMOUNT_TO_FUND) {
            revert NotEnoughEthFunded();
        }
        s_participants.push(payable(msg.sender));
        s_participantsToAmountFunded[msg.sender] += msg.value;

        emit LotteryFunded(msg.sender, msg.value);
    }

    /**
     * Automatically ends the lottery if 3 minutes have passed and picks a winner
     */
    function endLottery() public {
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__LotteryNotOpen();
        }
        if (block.timestamp < s_lotteryStartTime + LOTTERY_DURATION) {
            revert Lottery__NotEndedYet();
        }

        if (s_participants.length == 0) {
            revert Lottery__NoParticipants();
        }

        s_lotteryState = LotteryState.CALCULATING;
        requestRandomWords();
    }

    /**
     * Requests random words from Chainlink VRF to pick a winner.
     */
    function requestRandomWords() internal {
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);

        uint256 winnerIndex = _randomWords[0] % s_participants.length;
        address payable winner = s_participants[winnerIndex];
        s_recentWinner = winner;

        emit WinnerPicked(winner, address(this).balance, s_participants.length);

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }

        // Reset the lottery state
        s_participants = new address payable[](0); // Clear participants
        s_lotteryState = LotteryState.OPEN; // Reopen the lottery
        s_lotteryStartTime = block.timestamp; // Restart the timer
    }

    /** Getter Functions */
    function getParticipants() public view returns (address payable[] memory) {
        return s_participants;
    }

    function getAmountFundedByParticipant(
        address _participant
    ) public view returns (uint256) {
        return s_participantsToAmountFunded[_participant];
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getLotteryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getSubscriptionId() public view returns (uint256) {
        return i_subscriptionId;
    }

    function getGasLane() public view returns (bytes32) {
        return i_gasLane;
    }

    function getCallbackGasLimit() public view returns (uint32) {
        return i_callbackGasLimit;
    }

    function getRequestStatus(
        uint256 _requestId
    ) public view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}
