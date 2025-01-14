# MerkleProofValidator

A gas-efficient smart contract for verifying Merkle proofs, particularly useful for large-scale airdrops and whitelist implementations on EVM-compatible chains.

## Deployed Contract

Base Sepolia: `0x3ed1ab82c329b5ab3f9b36aae505dcee4bc7b80d`

## Overview

The MerkleProofValidator contract provides a secure and gas-efficient way to verify whether an address is part of a predefined set (e.g., whitelist, airdrop recipients) without storing the entire set on-chain. This is achieved using Merkle trees, a cryptographic data structure that allows for efficient proof of inclusion.

## Understanding Merkle Trees

A Merkle tree is a binary tree where:
- Each leaf node is a hash of a data block (in our case, an address and amount)
- Each non-leaf node is a hash of its two child nodes
- The root node (Merkle root) represents a cryptographic fingerprint of all data in the tree

Benefits:
- Only need to store one hash (the root) on-chain
- Proofs are logarithmic in size relative to the total number of leaves
- Gas-efficient verification process
- Perfect for large datasets like airdrops or whitelists

Example of a simple Merkle tree:
```
                Root Hash
              /          \
        Hash(1,2)        Hash(3,4)
        /      \         /       \
    Hash(1)  Hash(2)  Hash(3)  Hash(4)
      |        |        |        |
    Data1    Data2    Data3    Data4
```

## Features

- Gas-optimized proof verification
- Double-claim protection
- Support for address-amount pairs
- Simple and auditable implementation
- Custom error messages for better debugging
- Event emission for successful claims

## Usage

### 1. Generating Merkle Tree and Proofs (Off-chain)

```javascript
const { MerkleTree } = require('merkletreejs');
const { keccak256 } = require('ethereum-cryptography/keccak');

// Your whitelist/airdrop data
const whitelist = [
  { address: "0x123...", amount: "100000000000000000000" },
  { address: "0x456...", amount: "200000000000000000000" }
];

// Create leaf nodes
const leaves = whitelist.map(item => 
  keccak256(
    Buffer.concat([
      Buffer.from(item.address.slice(2), 'hex'),
      Buffer.from(item.amount.padStart(64, '0'), 'hex')
    ])
  )
);

// Create tree
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

// Get root
const root = tree.getRoot().toString('hex');

// Generate proof for an address
const leaf = keccak256(Buffer.concat([
  Buffer.from(address.slice(2), 'hex'),
  Buffer.from(amount.padStart(64, '0'), 'hex')
]));
const proof = tree.getProof(leaf);
```

### 2. Claiming (On-chain)

```solidity
// Contract interface
interface IMerkleProofValidator {
    function claim(
        address to,
        uint256 amount,
        bytes32[] calldata proof
    ) external;
    
    function hasClaimed(address addr) external view returns (bool);
}

// Usage in your contract
contract YourContract {
    IMerkleProofValidator public validator;
    
    function claimAirdrop(uint256 amount, bytes32[] calldata proof) external {
        validator.claim(msg.sender, amount, proof);
        // Handle successful claim...
    }
}
```

## Error Messages

- `InvalidProof()`: The provided Merkle proof is invalid
- `AlreadyClaimed()`: The address has already claimed their allocation

## Events

```solidity
event Claimed(address indexed to, uint256 amount);
```

## Security Considerations

1. The Merkle root is immutable once set in the constructor
2. Double-claims are prevented via mapping
3. Proof verification ensures data integrity
4. No loops or unbounded operations

## Gas Efficiency

- Average gas costs:
  - Successful claim: ~45,000 gas
  - Failed claim: ~20,000 gas
  - Checking claim status: ~2,300 gas

## License

MIT