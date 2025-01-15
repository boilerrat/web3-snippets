# SignatureVerifier

A gas-optimized utility contract for verifying ECDSA signatures with support for EIP-712 typed data and eth_sign signatures. This contract includes replay protection, deadline checks, and handles both standard and non-standard signature formats.

## Features

- EIP-712 typed data signature verification
- Personal message signature verification (eth_sign)
- Replay protection via nonce tracking
- Signature deadline validation
- Gas-optimized implementation using custom errors
- Support for multiple signature formats

## Functions

### verifyTypedSignature

```solidity
function verifyTypedSignature(
    string memory message,
    uint256 nonce,
    uint256 deadline,
    bytes memory signature
) public returns (address signer)
```

Verifies an EIP-712 typed message signature with replay protection and deadline validation.

Parameters:
- `message`: The message that was signed
- `nonce`: Unique nonce for replay protection
- `deadline`: Timestamp after which signature becomes invalid
- `signature`: The signature to verify (65 bytes: r, s, v)

Returns:
- `signer`: The address that signed the message

### verifyPersonalSignature

```solidity
function verifyPersonalSignature(
    string memory message,
    bytes memory signature
) public pure returns (address signer)
```

Verifies a personal message signature (eth_sign format).

Parameters:
- `message`: The message that was signed
- `signature`: The signature to verify (65 bytes: r, s, v)

Returns:
- `signer`: The address that signed the message

### isSignatureUsed

```solidity
function isSignatureUsed(bytes32 hash) external view returns (bool)
```

Checks if a signature has been used before.

Parameters:
- `hash`: The hash of the signed message

Returns:
- `bool`: True if signature has been used

## Error Codes

```solidity
error InvalidSignature();      // Signature verification failed
error SignatureAlreadyUsed();  // Signature has already been used
error InvalidSignatureLength(); // Signature length is not 65 bytes
```

## Usage Examples

### Basic EIP-712 Signature Verification

```solidity
// Deploy verifier
SignatureVerifier verifier = new SignatureVerifier("MyApp", "1");

// Verify a typed signature
try verifier.verifyTypedSignature(
    "Hello World",
    1234,  // nonce
    block.timestamp + 1 hours,  // deadline
    signature
) returns (address signer) {
    // Signature is valid, signer is the address that signed
} catch {
    // Signature is invalid
}
```

### Personal Message Verification

```solidity
// Verify a personal message
try verifier.verifyPersonalSignature(
    "Hello World",
    signature
) returns (address signer) {
    // Signature is valid
} catch {
    // Signature is invalid
}
```

## Security Considerations

- Always use a unique nonce for each signature to prevent replay attacks
- Set appropriate deadlines for time-sensitive operations
- Verify the returned signer address against expected signers
- The contract uses Solidity 0.8.28+ for built-in overflow protection

## Design Notes

- Uses custom errors for gas optimization
- Implements EIP-712 for structured data signing
- Assembly optimizations for signature recovery
- Immutable domain separator for gas efficiency
- Pure functions where possible to reduce state access

## License

MIT

## Deployment

Deployed and tested on Base Sepolia here:
https://sepolia.basescan.org/address/0xd48fe154b8f4f558526605fb71dc78021a1cb03a