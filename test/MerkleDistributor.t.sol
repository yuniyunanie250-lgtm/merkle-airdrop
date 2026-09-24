// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MerkleDistributor} from "../src/MerkleDistributor.sol";

contract MerkleDistributorTest is Test {
    MerkleDistributor internal drop;
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    uint256 internal constant A_AMOUNT = 10 ether;
    uint256 internal constant B_AMOUNT = 5 ether;

    bytes32 internal constant LEAF_A = keccak256(abi.encodePacked(uint256(0), address(0xA11CE), uint256(10 ether)));
    bytes32 internal constant LEAF_B = keccak256(abi.encodePacked(uint256(1), address(0xB0B), uint256(5 ether)));

    bytes32 internal root;
    bytes32[] internal proofForA;
    bytes32[] internal proofForB;

    function setUp() public {
        root = _hashPair(LEAF_A, LEAF_B);
        drop = new MerkleDistributor(root);
        vm.deal(address(drop), 15 ether);
        proofForA = new bytes32[](1);
        proofForA[0] = LEAF_B;
        proofForB = new bytes32[](1);
        proofForB[0] = LEAF_A;
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a <= b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }

    function test_ClaimPaysTheLeafAmount() public {
        uint256 before = alice.balance;
        drop.claim(0, alice, A_AMOUNT, proofForA);
        assertEq(alice.balance - before, A_AMOUNT);
        assertTrue(drop.isClaimed(0));
    }

    function test_SecondClaimReverts() public {
        drop.claim(0, alice, A_AMOUNT, proofForA);
        vm.expectRevert(MerkleDistributor.AlreadyClaimed.selector);
        drop.claim(0, alice, A_AMOUNT, proofForA);
    }

    function test_WrongAmountFailsTheProof() public {
        vm.expectRevert(MerkleDistributor.InvalidProof.selector);
        drop.claim(0, alice, A_AMOUNT + 1, proofForA);
    }

    function test_ProofIsDirectionAgnostic() public {
        // bob's proof works even though his leaf is the right-hand one
        uint256 before = bob.balance;
        drop.claim(1, bob, B_AMOUNT, proofForB);
        assertEq(bob.balance - before, B_AMOUNT);
    }

    function test_FullTreeIsDrainedOnce() public {
        drop.claim(0, alice, A_AMOUNT, proofForA);
        drop.claim(1, bob, B_AMOUNT, proofForB);
        assertEq(address(drop).balance, 0);
    }
}
