// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/ERC777Token_GTST.sol";
import "../src/ERC721Token.sol";

contract NFTMarket_Test is Test {
    address admin = makeAddr("admin");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");
    ERC777Token_GTST public tokenContract;
    ERC721Token public nftContract;
    NFTMarket public nftMarketContract;
    address public tokenAddr;
    address public nftAddr;
    address public marketAddr;

    function setUp() public {
        vm.startPrank(admin);
        tokenContract = new ERC777Token_GTST();
        tokenAddr = address(tokenContract);
        nftContract = new ERC721Token();
        nftAddr = address(nftContract);
        nftMarketContract = new NFTMarket(tokenAddr);
        marketAddr = address(nftMarketContract);
        vm.stopPrank();
    }

    // Case 1: Test param0(_recipient) of tokensReceived() in NFTMarket contract
    /// forge-config: default.fuzz.runs = 10000
    function testFuzz_tokensReceived_testRecipient(address _recipient) public {
        uint tokenTotalSupply = tokenContract.totalSupply();
        vm.assume(_recipient != address(0) && _recipient != bob);
        vm.startPrank(admin);
        tokenContract.transfer(_recipient, tokenTotalSupply);
        nftContract.mint(_recipient, "No.0");
        nftContract.mint(bob, "No.1");
        vm.stopPrank();

        vm.prank(_recipient);
        tokenContract.approve(marketAddr, 10000 * 10 ** 18);

        vm.startPrank(bob);
        nftContract.approve(marketAddr, 1);
        nftMarketContract.list(nftAddr, 1, 100 * 10 ** 18);
        vm.stopPrank();

        bytes memory _dataOfNFT1 = abi.encode(nftAddr, 1);

        vm.prank(_recipient);
        nftMarketContract.tokensReceived(
            _recipient,
            marketAddr,
            101 * 10 ** 18,
            _dataOfNFT1
        );
        vm.prank(bob);
        uint tokenBalanceOfSeller = nftMarketContract.getBalance();
        assertEq(tokenBalanceOfSeller, 101 * 10 ** 18, "The token balance of Bob in NFTMarket should equals 101 * 10 ** 18");
    }

    // Case 2: Test param1(_calledContract) of tokensReceived() in NFTMarket contract.
    // Because NFTMarket is required to realize tokensReceived() in advance,
    // So, this case is not suitable for fuzz testing.

    // Case 3: test param2(_amount) of tokensReceived() in NFTMarket contract
    /// forge-config: default.fuzz.runs = 10000
    function testFuzz_tokensReceived_testAmount(uint _amount) public {
        uint tokenTotalSupply = tokenContract.totalSupply();
        vm.assume(_amount >= 1 && _amount <= tokenTotalSupply);
        vm.startPrank(admin);
        tokenContract.transfer(alice, tokenTotalSupply);
        nftContract.mint(alice, "No.0");
        nftContract.mint(bob, "No.1");
        vm.stopPrank();

        vm.prank(alice);
        tokenContract.approve(marketAddr, _amount);

        vm.startPrank(bob);
        nftContract.approve(marketAddr, 1);
        nftMarketContract.list(nftAddr, 1, 1);
        vm.stopPrank();

        bytes memory _dataOfNFT1 = abi.encode(nftAddr, 1);

        vm.prank(alice);
        nftMarketContract.tokensReceived(
            alice,
            marketAddr,
            _amount,
            _dataOfNFT1
        );
        vm.prank(bob);
        uint tokenBalanceOfSeller = nftMarketContract.getBalance();
        assertEq(tokenBalanceOfSeller, _amount, "The token balance of Bob in NFTMarket should equals _bidAmount");
    }

    // Case 4: test param3(_data) of tokensReceived() in NFTMarket contract
    // Subcase 1 of Case 4: test param0(_NFTAddr) of getBytesOfNFTInfo() which returns _data
    // Because _NFTAddr is limited to be the same as a ERC721Token Address, which requires the ERC721Token contract deployed in advance,
    // So, this subcase is not suitable for fuzz testing.

    // Subcase 2 of Case 4: test param1(_tokenId) of getBytesOfNFTInfo() which returns _data
    // Because _tokenId is limited to be the ones of NFT minted, which requires tester know those _tokenId(s) in advance,
    // So, this subcase is not suitable for fuzz testing.

    // Case 5: test NFT-seller's address in tokensReceived()
    /// forge-config: default.fuzz.runs = 10000
    function testFuzz_tokensReceived_testSellerAddress(
        address _sellerAddr
    ) public {
        uint tokenTotalSupply = tokenContract.totalSupply();
        vm.assume(_sellerAddr != address(0));
        vm.startPrank(admin);
        tokenContract.transfer(alice, tokenTotalSupply);
        nftContract.mint(alice, "No.0");
        nftContract.mint(_sellerAddr, "No.1");
        vm.stopPrank();

        vm.prank(alice);
        tokenContract.approve(marketAddr, tokenTotalSupply);

        vm.startPrank(_sellerAddr);
        nftContract.approve(marketAddr, 1);
        nftMarketContract.list(nftAddr, 1, 100 * 10 ** 18);
        vm.stopPrank();

        bytes memory _dataOfNFT1 = abi.encode(nftAddr, 1);

        vm.prank(alice);
        nftMarketContract.tokensReceived(
            alice,
            marketAddr,
            101 * 10 ** 18,
            _dataOfNFT1
        );
        vm.prank(_sellerAddr);
        uint tokenBalanceOfSeller = nftMarketContract.getBalance();
        assertEq(tokenBalanceOfSeller, 101 * 10 ** 18, "The token balance of Bob in NFTMarket should equals 101 * 10 ** 18");
    }
}
