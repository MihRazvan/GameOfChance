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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Lottery is VRFConsumerBaseV2Plus {
    using PriceConverter for uint256;

    /** Events */
    event LotteryFunded(address indexed sender, uint256 amountSent);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    /** Errors */
    error NotEnoughEthFunded();

    /** Type declarations */
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    /** Variables */
    address[] private s_participants;

    AggregatorV3Interface private s_priceFeed;

    mapping(address => uint256) private s_participantsToAmountFunded;
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // Your subscription ID.
    uint256 public s_subscriptionId;

    // Past request IDs.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2-5/supported-networks
    bytes32 public keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    uint32 public callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    // For this example, retrieve 1 random values in one request.
    // Cannot exceed VRFCoordinatorV2_5.MAX_NUM_WORDS.
    uint32 public numWords = 1;

    /** Constants */
    uint256 private constant MIN_AMOUNT_TO_FUND = 50 * 1e18;

    /** Modifiers */

    constructor(
        AggregatorV3Interface priceFeed,
        address vrfCoordinator,
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_priceFeed = priceFeed;
        s_subscriptionId = subscriptionId;
    }

    function getEtherInUsd(uint256 _ethValue) public view returns (uint256) {
        return _ethValue.getConversionRate(s_priceFeed);
    }

    function fundLottery() public payable {
        uint256 ethAmountInUsd = msg.value.getConversionRate(s_priceFeed);
        if (ethAmountInUsd < MIN_AMOUNT_TO_FUND) {
            revert NotEnoughEthFunded();
        }
        s_participants.push(msg.sender);
        s_participantsToAmountFunded[msg.sender] += msg.value;

        emit LotteryFunded(msg.sender, msg.value);
    }

    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
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
        emit RequestSent(requestId, numWords);
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
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function pickWinner() private {}

    /** Getters */
    function getParticipants() public view returns (address[] memory) {
        return s_participants;
    }

    function getAmountFundedByParticipant(
        address _participant
    ) public view returns (uint256) {
        return s_participantsToAmountFunded[_participant];
    }
}
