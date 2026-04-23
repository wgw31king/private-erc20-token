// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {IERC20Errors} from "../lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MyTokenTest is Test {
    MyToken internal token;

    address internal constant OWNER = address(0xBEEF);
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        vm.prank(OWNER);
        token = new MyToken("Open Template", "OTT", OWNER);
    }

    function test_constructor_reverts_zeroOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
        new MyToken("Bad", "BAD", address(0));
    }

    function test_metadata() public view {
        assertEq(token.name(), "Open Template");
        assertEq(token.symbol(), "OTT");
        assertEq(token.decimals(), 18);
        assertEq(token.owner(), OWNER);
    }

    function test_mint_onlyOwner_increasesSupplyAndBalance() public {
        uint256 amount = 1_000 ether;

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), ALICE, amount);
        vm.expectEmit(true, true, true, true);
        emit Mint(ALICE, amount);
        vm.prank(OWNER);
        token.mint(ALICE, amount);

        assertEq(token.balanceOf(ALICE), amount);
        assertEq(token.totalSupply(), amount);
    }

    function test_mint_revert_notOwner() public {
        vm.prank(ALICE);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE));
        token.mint(ALICE, 1);
    }

    function test_mint_revert_zeroAddress() public {
        vm.prank(OWNER);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.mint(address(0), 1);
    }

    function test_mint_accumulates() public {
        vm.startPrank(OWNER);
        token.mint(ALICE, 100);
        token.mint(ALICE, 50);
        vm.stopPrank();
        assertEq(token.balanceOf(ALICE), 150);
        assertEq(token.totalSupply(), 150);
    }

    function test_burn_emitsBurnAndTransfer() public {
        uint256 minted = 500 ether;
        vm.prank(OWNER);
        token.mint(ALICE, minted);

        uint256 burnAmt = 200 ether;
        vm.prank(ALICE);
        vm.expectEmit(true, true, true, true);
        emit Transfer(ALICE, address(0), burnAmt);
        vm.expectEmit(true, true, true, true);
        emit Burn(ALICE, burnAmt);
        token.burn(burnAmt);

        assertEq(token.balanceOf(ALICE), minted - burnAmt);
        assertEq(token.totalSupply(), minted - burnAmt);
    }

    function test_burn_revert_insufficientBalance() public {
        vm.prank(OWNER);
        token.mint(ALICE, 10);
        vm.prank(ALICE);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, ALICE, 10, 11)
        );
        token.burn(11);
    }

    function test_transfer_and_approve() public {
        vm.prank(OWNER);
        token.mint(ALICE, 100);

        vm.prank(ALICE);
        assertTrue(token.transfer(BOB, 40));
        assertEq(token.balanceOf(BOB), 40);

        vm.prank(ALICE);
        token.approve(BOB, 30);
        assertEq(token.allowance(ALICE, BOB), 30);

        vm.prank(BOB);
        assertTrue(token.transferFrom(ALICE, BOB, 30));
        assertEq(token.balanceOf(BOB), 70);
    }

    function test_ownable2Step_transfer_accept() public {
        address newOwner = address(0xCAFE);

        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferStarted(OWNER, newOwner);
        token.transferOwnership(newOwner);

        assertEq(token.pendingOwner(), newOwner);
        assertEq(token.owner(), OWNER);

        vm.prank(newOwner);
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(OWNER, newOwner);
        token.acceptOwnership();

        assertEq(token.owner(), newOwner);
        assertEq(token.pendingOwner(), address(0));
    }

    function test_ownable2Step_wrongAccept_reverts() public {
        address newOwner = address(0xCAFE);
        vm.prank(OWNER);
        token.transferOwnership(newOwner);

        vm.prank(BOB);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, BOB));
        token.acceptOwnership();
    }

    function testFuzz_mint_totalSupplyInvariant(uint128 rawAmount) public {
        uint256 amount = uint256(rawAmount);
        vm.prank(OWNER);
        token.mint(ALICE, amount);
        assertEq(token.totalSupply(), token.balanceOf(ALICE));
    }

    function testFuzz_transfer_conservesSupply(address to, uint128 rawAmt) public {
        vm.assume(to != address(0));
        vm.assume(to != ALICE);
        uint256 amt = uint256(rawAmt);
        vm.prank(OWNER);
        token.mint(ALICE, amt);

        vm.prank(ALICE);
        token.transfer(to, amt);

        assertEq(token.totalSupply(), amt);
        assertEq(token.balanceOf(ALICE) + token.balanceOf(to), amt);
    }
}
