// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {MockV3Aggregator} from "@chainlink/contracts/v0.8/tests/MockV3Aggregator.sol";

contract ScaffoldETHDeploy is Script {
    error InvalidChain();
    error NoConfigFound();

    struct Deployment {
        string name;
        address addr;
    }

    struct Config {
        address priceFeed;
        address vrfCoordinator;
        uint256 subscriptionId;
        bytes32 gasLane;
        uint32 callbackGasLimit;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2640e8;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    string root;
    string path;
    Deployment[] public deployments;

    Config config;

    function getConfig() public returns (Config memory) {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            config.vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
            config.priceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
            return config;
        } else if (block.chainid == LOCAL_CHAIN_ID) {
            return deployMockAndGetLocalConfig();
        } else {
            revert NoConfigFound();
        }
    }

    function deployMockAndGetLocalConfig() public returns (Config memory) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        // Add the mock price feed deployment to the deployments array
        deployments.push(
            Deployment({name: "MockV3Aggregator", addr: address(mockPriceFeed)})
        );

        config.priceFeed = address(mockPriceFeed);
        return config;
    }

    /**
     * This function generates the file containing the contracts ABI definitions.
     * These definitions are used to derive the types needed in custom scaffold-eth hooks, for example.
     * This function should be called last.
     */
    function exportDeployments() internal {
        uint256 len = deployments.length;

        // Use 'deployments' as the object key
        for (uint256 i = 0; i < len; i++) {
            // Serialize each deployment under the 'deployments' object
            vm.serializeAddress(
                "deployments",
                deployments[i].name,
                deployments[i].addr
            );
        }

        // Construct the file path
        root = vm.projectRoot();
        path = string.concat(root, "/deployments/");
        string memory chainIdStr = vm.toString(block.chainid);
        path = string.concat(path, chainIdStr, ".json");

        // Write the JSON to the file using the object key directly
        vm.writeJson("deployments", path);
    }
}
