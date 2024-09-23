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

contract Lottery {
    using PriceConverter for uint256;

    /** Events */
    event LotteryFunded(address indexed, uint256);

    /** Errors */
    error NotEnoughEthFunded();

    /** Type declarations */

    /** Variables */
    address[] private s_participants;
    mapping(address => uint256) private s_participantsToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    /** Constants */
    uint256 private constant MIN_AMOUNT_TO_FUND = 50 * 1e18;

    /** Modifiers */

    constructor(AggregatorV3Interface priceFeed) {
        s_priceFeed = priceFeed;
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
