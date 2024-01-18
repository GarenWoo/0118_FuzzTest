// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/ERC20Token_GTT.sol";
import "../src/ERC777Token_GTST.sol";
import "../src/Bank.sol";
import "../src/SuperBank.sol";

contract SuperBank_Test is Test {
    address admin = makeAddr("admin");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");
    /* Notice:
    1. GTT is ERC20 Token
    2. GTST is SafeERC20 Token and also ERC777 token
    */
    ERC20Token_GTT public GTT_Contract;
    ERC777Token_GTST public GTST_Contract;
    SuperBank public SuperBank_Contract;
    address public GTT_Addr;
    address public GTST_Addr;
    address public SuperBank_Addr;

    function setUp() public {
        vm.startPrank(admin);
        GTT_Contract = new ERC20Token_GTT();
        GTT_Addr = address(GTT_Contract);
        GTST_Contract = new ERC777Token_GTST();
        GTST_Addr = address(GTST_Contract);
        SuperBank_Contract = new SuperBank();
        SuperBank_Addr = address(SuperBank_Contract);
        vm.stopPrank();
    }

    // Case 1: Test ETH value in depositETH()
    /// forge-config: default.fuzz.runs = 10000
    function testFuzz_depositETH_testValue(uint _value) public {
        uint maxBalance = 10000 ether;
        vm.assume(_value <= maxBalance);
        deal(alice, maxBalance);

        bytes4 selector_depositETH = bytes4(keccak256("depositETH()"));
        bytes memory data = abi.encodeWithSelector(selector_depositETH);

        vm.prank(alice);
        (bool success, ) = SuperBank_Addr.call{value: _value}(data);
        console.log("SuperBank_Addr.balance:", SuperBank_Addr.balance);
        assertTrue(success);
        assertEq(
            SuperBank_Addr.balance,
            _value,
            "ETH Balance of Alice in SuperBank should equal deposited value of ETH"
        );
    }

    // Case 2: Test when recipient in withdrawETH() is not the owner of SuperBank
    /// forge-config: default.fuzz.runs = 10000
    function testFuzz_withdrawETH_testRecipient(address _recipient) public {
        uint maxBalance = 10000 ether;
        vm.assume(_recipient != admin);
        deal(_recipient, maxBalance);
        bytes memory encodedRevertMessage = abi.encodeWithSignature(
            "NotOwner(address,address)",
            _recipient,
            SuperBank_Contract.owner()
        );
        vm.expectRevert(encodedRevertMessage);
        vm.prank(_recipient);
        SuperBank_Contract.withdrawETH();
    }
}
