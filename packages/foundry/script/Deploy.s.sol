//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/Lottery.sol";
import "../contracts/PriceConverter.sol";
import "./DeployHelpers.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract DeployScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    function run() external {
        vm.startBroadcast();

        Lottery Lottery = new Lottery(
            AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306)
        );

        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }

    function test() public {}
}
