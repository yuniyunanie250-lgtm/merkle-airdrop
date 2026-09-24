// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title Merkle airdrop distributor.
/// @notice Stores one merkle root and pays out a fixed amount per leaf, once.
///         Leaves are `keccak256(abi.encodePacked(index, account, amount))`,
///         which is what the OpenZeppelin and Uniswap generators emit.
contract MerkleDistributor {
    error AlreadyClaimed();
    error InvalidProof();
    error TransferFailed();

    bytes32 public immutable merkleRoot;
    mapping(uint256 => bool) public claimed;

    event Claimed(uint256 index, address account, uint256 amount);

    constructor(bytes32 merkleRoot_) {
        merkleRoot = merkleRoot_;
    }

    receive() external payable {}

    function isClaimed(uint256 index) public view returns (bool) {
        return claimed[index];
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata proof) external {
        if (claimed[index]) revert AlreadyClaimed();
        if (!_verify(proof, merkleRoot, keccak256(abi.encodePacked(index, account, amount)))) {
            revert InvalidProof();
        }
        claimed[index] = true;
        (bool ok,) = account.call{value: amount}("");
        if (!ok) revert TransferFailed();
        emit Claimed(index, account, amount);
    }

    /// @dev Pairwise hashing, sorting the pair first so proofs do not depend on
    ///      the order a tree was built in.
    function _verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computed = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 p = proof[i];
            computed =
                computed <= p ? keccak256(abi.encodePacked(computed, p)) : keccak256(abi.encodePacked(p, computed));
        }
        return computed == root;
    }
}
