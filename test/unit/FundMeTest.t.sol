//SPDX-License-Identifyer: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();

        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollearIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5000000000000000000);
    }

    function testOwnerisMsgSender() public view {
        console.log();
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmoutFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToFundersArray() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFundert(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);

        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFunderBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFunderBalance = address(fundMe).balance;

        assertEq(endingFunderBalance, 0);
        assertEq(startingFunderBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint256 startingFunderIndex = 1;

        for (uint256 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(uint160(i)), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFunderBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assertEq(startingFunderBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint256 startingFunderIndex = 1;

        for (uint256 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(uint160(i)), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFunderBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assertEq(startingFunderBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }
}
