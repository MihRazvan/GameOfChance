// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";
import {Lottery} from "../../contracts/Lottery.sol";
import {DeployScript} from "../../script/Deploy.s.sol";
import {ScaffoldETHDeploy} from "../../script/DeployHelpers.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    ScaffoldETHDeploy public config;
    VRFCoordinatorV2_5Mock public vrfCoordinatorV2_5Mock;
    address PLAYER = makeAddr("PLAYER");
    address OWNER = makeAddr("OWNER");

    uint256 constant MINIMUM_ETH = 1 ether;

    // Set up the contract and config
    function setUp() external {
        DeployScript deployer = new DeployScript();
        (lottery, config) = deployer.run();
        vm.deal(OWNER, 10 ether); // Give OWNER some Ether in setUp
        vm.deal(PLAYER, 10 ether); // Give PLAYER some Ether in setUp
    }

    /**************************************
     * Test that the lottery initializes in OPEN state
     **************************************/
    function test_RaffleInitializesInOpenState() public {
        assertEq(
            uint(lottery.getLotteryState()),
            uint(Lottery.LotteryState.OPEN)
        );
    }

    /**************************************
     * Test that the contract reverts if not enough ETH is sent
     **************************************/
    function test_RaffleRevertsWhenYouDontFundEnough() public {
        vm.prank(PLAYER); // Prank PLAYER
        vm.expectRevert(Lottery.NotEnoughEthFunded.selector);
        lottery.fundLottery{value: 0.001 ether}();
        assertEq(lottery.getParticipants().length, 0); // Ensure no participants were added
    }

    /**************************************
     * Test that a participant is correctly added to the lottery
     **************************************/
    function test_ParticipantIsAddedToArray() public {
        vm.prank(PLAYER); // Prank PLAYER
        lottery.fundLottery{value: MINIMUM_ETH}();
        assertEq(lottery.getParticipants().length, 1);
        assertEq(lottery.getParticipants()[0], PLAYER);
    }

    /**************************************
     * Test that the lottery balance increases after a participant funds it
     **************************************/
    function test_LotteryBalanceIncreasesAfterFunding() public {
        vm.prank(PLAYER); // Prank PLAYER
        uint256 initialBalance = address(lottery).balance;
        lottery.fundLottery{value: MINIMUM_ETH}();
        uint256 finalBalance = address(lottery).balance;
        assertEq(finalBalance, initialBalance + MINIMUM_ETH);
    }

    /**************************************
     * Test that the lottery can only end after 3 minutes
     **************************************/
    function test_LotteryCannotEndBeforeThreeMinutes() public {
        vm.prank(PLAYER); // Prank PLAYER
        lottery.fundLottery{value: MINIMUM_ETH}();
        vm.warp(block.timestamp + 2 minutes); // Fast-forward time to 2 minutes
        vm.expectRevert(Lottery.Lottery__NotEndedYet.selector); // Expect revert since 3 minutes haven't passed
        vm.prank(OWNER); // Prank OWNER before ending the lottery
        lottery.endLottery();
    }

    /**************************************
     * Test that the lottery ends after 3 minutes
     **************************************/
    function test_LotteryEndsAfterThreeMinutes() public {
        vm.prank(PLAYER); // Prank PLAYER
        lottery.fundLottery{value: MINIMUM_ETH}();
        vm.warp(block.timestamp + 3 minutes); // Fast-forward time to exactly 3 minutes
        vm.prank(OWNER); // Prank OWNER
        lottery.endLottery();
        assertEq(
            uint(lottery.getLotteryState()),
            uint(Lottery.LotteryState.CALCULATING)
        ); // State should be CALCULATING
    }

    /**************************************
     * Test fulfilling random words, picking a winner, resetting, and sending money
     **************************************/
    function test_FulfillRandomWordsPicksWinnerResetsAndSendsMoney() public {
        address expectedWinner = PLAYER; // Adjust based on the simulation

        // Arrange
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 1; // Start with address(1)

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrances;
            i++
        ) {
            address player = address(uint160(i));
            hoax(player, 1 ether); // Fund player with 1 ETH
            vm.prank(player); // Prank each player entering the lottery
            lottery.fundLottery{value: MINIMUM_ETH}(); // Each player enters the lottery
        }

        uint256 startingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        vm.prank(OWNER); // Prank OWNER
        lottery.endLottery(); // Emits requestId

        Vm.Log[] memory entries = vm.getRecordedLogs(); // Correct way to record logs
        bytes32 requestId = entries[1].topics[1]; // Retrieve requestId from logs

        vrfCoordinatorV2_5Mock.fulfillRandomWords(
            uint256(requestId),
            address(lottery)
        );

        // Assert
        address recentWinner = lottery.getRecentWinner();
        Lottery.LotteryState lotteryState = lottery.getLotteryState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 prize = MINIMUM_ETH * (additionalEntrances + 1); // Calculate the prize

        assertEq(recentWinner, expectedWinner);
        assertEq(uint256(lotteryState), 0); // Check that state is reset to OPEN
        assertEq(winnerBalance, startingBalance + prize); // Verify winner's balance
    }
}
