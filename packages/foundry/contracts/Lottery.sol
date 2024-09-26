/** Contract elements should be laid out in the following order:
Pragma statements
Import statements
Events
Errors
Interfaces
Libraries
Contracts

Inside each contract, library or interface, use the following order:
Type declarations
State variables
Events
Errors
Modifiers
Functions */

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
    error Raffle__TransferFailed();

    /** Type declarations */
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    /** Constants */

    /** Lottery Variables */
    address payable[] private s_participants;
    AggregatorV3Interface private s_priceFeed;
    mapping(address => uint256) private s_participantsToAmountFunded;
    uint256 private constant MIN_AMOUNT_TO_FUND = 50 * 1e18;
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

    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        require(s_lotteryState == LotteryState.OPEN, "Lottery not open");
        require(s_participants.length > 0, "No participants in the lottery");

        s_lotteryState = LotteryState.CALCULATING;

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
        requestId = s_vrfCoordinator.requestRandomWords(request);
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId);
        return requestId;
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
            revert Raffle__TransferFailed();
        }

        // Reset the lottery state
        s_participants = new address payable[](0); // Clear participants
        s_lotteryState = LotteryState.OPEN; // Reopen the lottery
    }

    /** Getter Functions */

    // Get the list of participants in the lottery
    function getParticipants() public view returns (address payable[] memory) {
        return s_participants;
    }

    // Get the amount funded by a specific participant
    function getAmountFundedByParticipant(
        address _participant
    ) public view returns (uint256) {
        return s_participantsToAmountFunded[_participant];
    }

    // Get the current lottery state (OPEN or CALCULATING)
    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    // Get the most recent lottery winner
    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    // Get the total ETH balance of the lottery
    function getLotteryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Get the Chainlink VRF subscription ID
    function getSubscriptionId() public view returns (uint256) {
        return i_subscriptionId;
    }

    // Get the Chainlink VRF gas lane (keyHash)
    function getGasLane() public view returns (bytes32) {
        return i_gasLane;
    }

    // Get the Chainlink VRF callback gas limit
    function getCallbackGasLimit() public view returns (uint32) {
        return i_callbackGasLimit;
    }

    // Get the status of a VRF request by request ID
    function getRequestStatus(
        uint256 _requestId
    ) public view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}
