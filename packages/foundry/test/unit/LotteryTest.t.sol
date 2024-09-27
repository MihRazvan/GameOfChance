// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Lottery} from "../../contracts/Lottery.sol";
import {DeployScript} from "../../script/Deploy.s.sol";
import {ScaffoldETHDeploy} from "../../script/DeployHelpers.s.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    ScaffoldETHDeploy public config;
    address PLAYER = makeAddr("PLAYER");
    vm.deal(PLAYER, 10 ether);
    
    function setUp() external {
        DeployScript deployer = new DeployScript();
        (lottery, config) = deployer.run();
    }

    function test_RaffleItializesInOpenState() public view {
        assert(lottery.getLotteryState() == Lottery.LotteryState.OPEN);
    }

    function test_RaffleRevertsWhenYouDontFundEnough() public {
        vm.prank(msg.sender);
        vm.deal(msg.sender, 1 ether);
        lottery.fundLottery{value: 0.001 ether}();
        vm.expectRevert(Lottery.NotEnoughEthFunded());
    }
}
