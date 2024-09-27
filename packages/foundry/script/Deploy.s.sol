// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/Lottery.sol";
import "./DeployHelpers.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract DeployScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    function run() external returns (Lottery, ScaffoldETHDeploy) {
        ScaffoldETHDeploy deployer = new ScaffoldETHDeploy();
        ScaffoldETHDeploy.Config memory config = deployer.getConfig();

        vm.startBroadcast(config.account);

        Lottery lottery = new Lottery(
            config.priceFeed,
            config.vrfCoordinator,
            config.subscriptionId,
            config.gasLane,
            config.callbackGasLimit
        );

        // Add the Lottery deployment to the deployments array
        deployments.push(Deployment({name: "Lottery", addr: address(lottery)}));

        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts ABI definitions.
         * These definitions are used to derive the types needed in custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();

        return (lottery, deployer);
    }
}
