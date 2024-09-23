// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/Lottery.sol";
import "./DeployHelpers.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract DeployScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    address public priceFeed;

    function run() external {
        // Since we inherit from ScaffoldETHDeploy, we can call getConfig() directly
        priceFeed = getConfig();
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Lottery lottery = new Lottery(AggregatorV3Interface(priceFeed));

        // Add the Lottery deployment to the deployments array
        deployments.push(Deployment({name: "Lottery", addr: address(lottery)}));

        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts ABI definitions.
         * These definitions are used to derive the types needed in custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }
}
