// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/ERC777Token_GTST.sol";
import "../src/ERC721Token.sol";

contract ERC777Token_GTST_Test is Test {
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

    // Case 1: Test param0(_to) of transferWithCallbackForNFT() in NFTMarket contract.
    // Because NFTMarket is required to realize transferWithCallbackForNFT() in advance,
    // So, this case is not suitable for fuzz testing.

    // Case 2: test param1(_bidAmount) of transferWithCallbackForNFT() in NFTMarket contract
    /// forge-config: default.fuzz.runs = 10000
    function testFuzz_transferWithCallbackForNFT_testBidAmount(
        uint _bidAmount
    ) public {
        uint tokenTotalSupply = tokenContract.totalSupply();
        vm.assume(_bidAmount >= 1 && _bidAmount <= tokenTotalSupply);
        vm.startPrank(admin);
        tokenContract.transfer(alice, tokenTotalSupply);
        nftContract.mint(alice, "No.0");
        nftContract.mint(bob, "No.1");
        vm.stopPrank();

        vm.prank(alice);
        tokenContract.approve(marketAddr, _bidAmount);

        vm.startPrank(bob);
        nftContract.approve(marketAddr, 1);
        nftMarketContract.list(nftAddr, 1, 1);
        vm.stopPrank();

        bytes memory _dataOfNFT1 = abi.encode(nftAddr, 1);

        vm.prank(alice);
        tokenContract.transferWithCallbackForNFT(
            marketAddr,
            _bidAmount,
            _dataOfNFT1
        );
        vm.prank(bob);
        uint tokenBalanceOfSeller = nftMarketContract.getBalance();
        assertEq(tokenBalanceOfSeller, _bidAmount, "The token balance of Bob in NFTMarket should equals _bidAmount");
    }

    // Case 3: test param2(_data) of transferWithCallbackForNFT() in NFTMarket contract
    // Subcase 1 of Case 3: test param0(_NFTAddr) of getBytesOfNFTInfo() which returns _data
    // Because _NFTAddr is limited to be the same as a ERC721Token Address, which requires the ERC721Token contract deployed in advance,
    // So, this subcase is not suitable for fuzz testing.

    // Subcase 2 of Case 3: test param1(_tokenId) of getBytesOfNFTInfo() which returns _data
    // Because _tokenId is limited to be the ones of NFT minted, which requires tester know those _tokenId(s) in advance,
    // So, this subcase is not suitable for fuzz testing.

    // Case 4: test NFT-seller's address in transferWithCallbackForNFT()
    /// forge-config: default.fuzz.runs = 10000
    function testFuzz_transferWithCallbackForNFT_testSellerAddress(
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
        tokenContract.transferWithCallbackForNFT(
            marketAddr,
            101 * 10 ** 18,
            _dataOfNFT1
        );
        vm.prank(_sellerAddr);
        uint tokenBalanceOfSeller = nftMarketContract.getBalance();
        assertEq(tokenBalanceOfSeller, 101 * 10 ** 18, "The token balance of Bob in NFTMarket should equals 101 * 10 ** 18");
    }
}
