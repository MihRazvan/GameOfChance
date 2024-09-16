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

pragma solidity ^0.8;

contract Lottery {
    uint256 private constant MIN_AMOUNT = 0.1 ether;

    address[] private participants;
    mapping(address => uint256) participansToAmountFunded;

    error Error_NotEnoughEthFunded();

    function fundLottery() public payable {
        if (msg.value < MIN_AMOUNT) {
            revert Error_NotEnoughEthFunded();
        }
        participants.push(msg.sender);
    }
}
