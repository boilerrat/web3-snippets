// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/***
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 *     |W|e|b|3| |S|n|i|p|p|e|t|
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 */


/**
 * @title MerkleProofValidator
 * @notice Gas-efficient contract for verifying Merkle proofs
 * @dev Used for large-scale airdrops and whitelists with minimal storage costs
 */
contract MerkleProofValidator {
    /// @notice Mapping to track claimed addresses for each merkle root
    mapping(bytes32 => mapping(address => bool)) private claimed;
    
    /// @notice The Merkle root of the verification tree
    bytes32 public immutable merkleRoot;
    
    /// @dev Custom errors for gas optimization
    error InvalidProof();
    error AlreadyClaimed();
    
    /**
     * @notice Constructor sets the Merkle root for verification
     * @param _merkleRoot The root of the Merkle tree
     */
    constructor(bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
    }
    
    /**
     * @notice Verify if an address is part of the Merkle tree
     * @param proof Array of hashes forming the Merkle proof
     * @param leaf The leaf node being verified
     * @return bool True if the proof is valid
     */
    function verifyProof(
        bytes32[] calldata proof,
        bytes32 leaf
    ) public view returns (bool) {
        bytes32 computedHash = leaf;
        
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        
        return computedHash == merkleRoot;
    }
    
    /**
     * @notice Claims tokens/rewards for a whitelisted address
     * @param to Address to receive the claim
     * @param amount Amount to be claimed
     * @param proof Merkle proof to verify the claim
     */
    function claim(
        address to,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        // Generate leaf from address and amount
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        
        // Verify address hasn't claimed
        if (claimed[merkleRoot][to]) revert AlreadyClaimed();
        
        // Verify the proof
        if (!verifyProof(proof, leaf)) revert InvalidProof();
        
        // Mark as claimed
        claimed[merkleRoot][to] = true;
        
        // Emit claim event (implement based on your needs)
        emit Claimed(to, amount);
    }
    
    /**
     * @notice Check if an address has already claimed
     * @param addr Address to check
     * @return bool True if already claimed
     */
    function hasClaimed(address addr) external view returns (bool) {
        return claimed[merkleRoot][addr];
    }
    
    /**
     * @notice Generate a leaf hash from address and amount
     * @param account Address to hash
     * @param amount Amount to hash
     * @return bytes32 The leaf hash
     */
    function getLeafHash(
        address account,
        uint256 amount
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, amount));
    }
    
    /// @notice Emitted when a successful claim is made
    event Claimed(address indexed to, uint256 amount);
}