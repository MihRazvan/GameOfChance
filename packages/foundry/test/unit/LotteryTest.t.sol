// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../contracts/Lottery.sol";
import "../../script/Deploy.s.sol";

contract LotteryTest is Test {
    function setUp() {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DeployScript deployer = new DeployScript();

        vm.stopBroadcast();
    }

    function raffleItializesInOpenState() public view {}
}
