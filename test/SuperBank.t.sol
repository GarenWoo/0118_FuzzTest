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
        bytes4 selector_depositETH = bytes4(keccak256("depositETH()"));
        bytes memory data = abi.encodeWithSelector(selector_depositETH);
        vm.prank(_recipient);
        (bool success, ) = SuperBank_Addr.call{value: 1}(data);
        bytes memory encodedRevertMessage = abi.encodeWithSignature(
            "NotOwner(address,address)",
            _recipient,
            SuperBank_Contract.owner()
        );
        vm.expectRevert(encodedRevertMessage);
        vm.prank(_recipient);
        SuperBank_Contract.withdrawETH();
        assertTrue(
            SuperBank_Addr.balance > 0,
            "Because the recipient is not the owner of SuperBank, the ETH balance of Bigbank isn't 0 after calling withdrawETH()"
        );
    }

    // Case 3: Test amount of ERC20 token in depositToken()
    /// forge-config: default.fuzz.runs = 10000
    function testFuzz_depositToken_testAmount(uint _amount) public {
        vm.startPrank(admin);
        uint GTT_totalSupply = GTT_Contract.totalSupply();
        uint GTST_totalSupply = GTST_Contract.totalSupply();
        vm.assume(_amount <= GTT_totalSupply && _amount <= GTST_totalSupply);
        GTT_Contract.transfer(alice, GTT_totalSupply); // The token balance of Alice equals the total supply of GTT(ERC20 token)
        GTST_Contract.transfer(bob, GTST_totalSupply); // The token balance of Bob equals the total supply of GTST(SafeERC20&ERC777 token)
        vm.startPrank(alice);
        GTT_Contract.approve(SuperBank_Addr, GTT_totalSupply);
        SuperBank_Contract.depositToken(GTT_Addr, _amount);
        assertEq(
            SuperBank_Contract.getTokenBalance(GTT_Addr, alice),
            _amount,
            "The GTT balance of Alice should equal deposited token amount"
        );
        vm.startPrank(bob);
        GTST_Contract.approve(SuperBank_Addr, GTST_totalSupply);
        SuperBank_Contract.depositToken(GTST_Addr, _amount);
        vm.stopPrank();
        assertEq(
            SuperBank_Contract.getTokenBalance(GTST_Addr, bob),
            _amount,
            "The GTST balance of Bob should equal deposited token amount"
        );
    }

    // Case 4: Test amount of ERC20 token in withdrawToken()
    /// forge-config: default.fuzz.runs = 10000
    function testFuzz_withdrawToken_testRecipient(address _recipient) public {
        vm.assume(_recipient != admin);
        vm.startPrank(admin);
        uint GTT_totalSupply = GTT_Contract.totalSupply();
        uint GTST_totalSupply = GTST_Contract.totalSupply();
        GTT_Contract.transfer(alice, GTT_totalSupply); // The token balance of Alice equals the total supply of GTT(ERC20 token)
        GTST_Contract.transfer(bob, GTST_totalSupply); // The token balance of Bob equals the total supply of GTST(SafeERC20&ERC777 token)
        
        vm.startPrank(alice);
        GTT_Contract.approve(SuperBank_Addr, GTT_totalSupply);
        SuperBank_Contract.depositToken(GTT_Addr, 1);

        vm.startPrank(bob);
        GTST_Contract.approve(SuperBank_Addr, GTST_totalSupply);
        SuperBank_Contract.depositToken(GTST_Addr, 1);
        vm.stopPrank();

        bytes memory encodedRevertMessage = abi.encodeWithSignature(
            "NotOwner(address,address)",
            _recipient,
            SuperBank_Contract.owner()
        );

        vm.expectRevert(encodedRevertMessage);
        vm.prank(_recipient);
        SuperBank_Contract.withdrawToken(GTT_Addr);

        vm.expectRevert(encodedRevertMessage);
        vm.prank(_recipient);
        SuperBank_Contract.withdrawToken(GTST_Addr);
    }
}
