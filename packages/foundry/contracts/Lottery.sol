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

contract Lottery {
    uint256 private constant MIN_AMOUNT_TO_FUND = 0.1 ether;

    address[] private s_participants;
    mapping(address => uint256) private s_participansToAmountFunded;
    // just so I can test price converter
    uint256 private etherInUsd;

    error Error_NotEnoughEthFunded();

    function fundLottery() public payable {
        if (msg.value < MIN_AMOUNT_TO_FUND) {
            revert Error_NotEnoughEthFunded();
        }
        s_participants.push(msg.sender);
        s_participansToAmountFunded[msg.sender] += msg.value;
    }

    function pickWinner() private {}

    /** Getters */
    function getParticipans() public view returns (address[] memory) {
        return s_participants;
    }

    function getAmountFundedByParticipant(
        address _participant
    ) public view returns (uint256) {
        return s_participansToAmountFunded[_participant];
    }
}
