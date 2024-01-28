// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/FundMeDeploy.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_ETH = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumUsdIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        // console.log("msg.sender", msg.sender);
        // console.log("fundMe.i_owner()", fundMe.i_owner());
        assertEq(fundMe.getOwner(), msg.sender);
        // assertEq(fundMe.i_owner(), address(this));
    }

    function testDataFeedVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFailsWithoutEnoughEth() public {
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_ETH}();
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_ETH);
    }

    function testAddFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_ETH}();
        assertEq(fundMe.getFunders(0), USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_ETH}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawWithMultipleFunders() public funded {
        // arrange
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_ETH);
            fundMe.fund{value: SEND_ETH}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        // assert
        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        // arrange
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_ETH);
            fundMe.fund{value: SEND_ETH}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        // assert
        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance ==
                fundMe.getOwner().balance
        );
    }
}
