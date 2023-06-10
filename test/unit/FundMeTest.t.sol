//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        deal(USER, STARTING_BALANCE);
    }

    function testMinmumDollarsIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsDeployer() public {
        address owner = fundMe.getOwner();
        assertEq(owner, msg.sender);
        // assertEq(fundMe.i_owner(), msg.sender);
        // assertEq(fundMe.i_owner(), address(this));
    }

    // forge test --mt testPriceFeedVersionIsAccurate -vvvvv --fork-url $SEPOLIA_RPC_URL
    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        console.log("version");
        console.log(version);
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
        // fundMe.fund{value: 1e12}();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);

        // assertEq(fundMe.s_addressToAmountFunded(address(this)), SEND_VALUE);
        // assertEq(fundMe.s_funders(0), address(this));
    }

    function testAddFunderToArrayOfFunders() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft();

        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);

        // console.log(endingOwnerBalance, SEND_VALUE + startingOwnerBalance);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );

        assertEq(SEND_VALUE + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // if you want to use numbers to generate addresses, number must be a uint160
        uint160 startingFunderIndex = 1; // 0 address includes sanity checks, so just avoid 0 address and start at index 1

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // prank
            // deal
            // fund
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assertEq(address(fundMe).balance, 0);
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // if you want to use numbers to generate addresses, number must be a uint160
        uint160 startingFunderIndex = 1; // 0 address includes sanity checks, so just avoid 0 address and start at index 1

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // prank
            // deal
            // fund
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assertEq(address(fundMe).balance, 0);
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }
}
