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
    address OWNER = makeAddr("OWNER");

    // Set up the contract and config
    function setUp() external {
        DeployScript deployer = new DeployScript();
        (lottery, config) = deployer.run();
        vm.prank(OWNER); // Make the test contract the owner
    }

    // Modifier to simulate a player's actions
    modifier prankPlayer() {
        vm.prank(PLAYER);
        vm.deal(PLAYER, 10 ether);
        _;
    }

    /**************************************
     * Test that the lottery initializes in OPEN state
     **************************************/
    function test_RaffleInitializesInOpenState() public prankPlayer {
        assertEq(
            uint(lottery.getLotteryState()),
            uint(Lottery.LotteryState.OPEN)
        );
    }

    /**************************************
     * Test that the contract reverts if not enough ETH is sent
     **************************************/
    function test_RaffleRevertsWhenYouDontFundEnough() public prankPlayer {
        vm.expectRevert(Lottery.NotEnoughEthFunded.selector);
        lottery.fundLottery{value: 0.001 ether}();
        // Additional check to ensure no participants were added
        assertEq(lottery.getParticipants().length, 0);
    }

    /**************************************
     * Test that a participant is correctly added to the lottery
     **************************************/
    function test_ParticipantIsAddedToArray() public prankPlayer {
        lottery.fundLottery{value: 1 ether}();
        assertEq(lottery.getParticipants().length, 1);
        assertEq(lottery.getParticipants()[0], PLAYER);
    }

    /**************************************
     * Test that the lottery balance increases after a participant funds it
     **************************************/
    function test_LotteryBalanceIncreasesAfterFunding() public prankPlayer {
        uint256 initialBalance = address(lottery).balance;
        lottery.fundLottery{value: 1 ether}();
        uint256 finalBalance = address(lottery).balance;
        assertEq(finalBalance, initialBalance + 1 ether);
    }

    /**************************************
     * Test that the random words request reverts if not owner
     **************************************/
    function test_RequestRandomWordsRevertsIfNotOwner() public prankPlayer {
        vm.expectRevert();
        lottery.requestRandomWords();
    }

    /**************************************
     * Test that the random words request works when owner calls it
     **************************************/
    function test_OwnerCanRequestRandomWords() public {
        // Simulate owner funding the lottery first
        vm.prank(OWNER);
        lottery.fundLottery{value: 1 ether}();
        // Simulate owner requesting random words
        vm.prank(OWNER);
        uint256 requestId = lottery.requestRandomWords();
        assert(requestId != 0);
    }

    /**************************************
     * Test that the contract picks a winner after fulfilling randomness
     **************************************/
    function test_FulfillsRandomWordsAndPicksWinner() public prankPlayer {
        // Fund the lottery
        lottery.fundLottery{value: 1 ether}();

        // Mock the VRF request and fulfillment process
        vm.prank(OWNER);
        uint256 requestId = lottery.requestRandomWords();
        assert(requestId != 0);

        // Fulfill the randomness and ensure a winner is picked
        uint256[] memory randomWords;
        randomWords[0] = 777; // Mocked random word for testing
        vm.prank(OWNER);
        lottery.fulfillRandomWords(requestId, randomWords);

        // Check the recent winner
        address recentWinner = lottery.getRecentWinner();
        assertEq(recentWinner, PLAYER);

        // Check that the lottery balance is transferred to the winner
        assertEq(address(lottery).balance, 0);
    }
}
