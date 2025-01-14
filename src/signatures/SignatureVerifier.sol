// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/***
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 *     |W|e|b|3| |S|n|i|p|p|e|t|
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 */

/**
 * @title SignatureVerifier
 * @notice A utility contract for verifying ECDSA signatures with support for EIP-712
 * @dev Implements robust signature verification with multiple hash formats and replay protection
 */
contract SignatureVerifier {
    // Mapping to track used signatures for replay protection
    mapping(bytes32 => bool) private _usedSignatures;
    
    // Custom errors for gas optimization
    error InvalidSignature();
    error SignatureAlreadyUsed();
    error InvalidSignatureLength();
    
    // EIP-712 Domain Separator
    bytes32 private immutable DOMAIN_SEPARATOR;
    
    // EIP-712 TypeHash for basic message signing
    bytes32 private constant TYPED_MESSAGE_HASH = keccak256(
        "Message(string message,uint256 nonce,uint256 deadline)"
    );

    constructor(string memory name, string memory version) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @notice Verifies an EIP-712 typed message signature
     * @param message The message that was signed
     * @param nonce Unique nonce for replay protection
     * @param deadline Timestamp after which signature is invalid
     * @param signature The signature to verify
     * @return signer The address that signed the message
     */
    function verifyTypedSignature(
        string memory message,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) public returns (address signer) {
        // Check deadline
        if (block.timestamp >= deadline) revert InvalidSignature();
        
        // Create message hash
        bytes32 structHash = keccak256(
            abi.encode(
                TYPED_MESSAGE_HASH,
                keccak256(bytes(message)),
                nonce,
                deadline
            )
        );
        
        bytes32 hash = _hashTypedDataV4(structHash);
        
        // Verify signature hasn't been used
        if (_usedSignatures[hash]) revert SignatureAlreadyUsed();
        
        // Mark signature as used
        _usedSignatures[hash] = true;
        
        // Recover and verify signer
        signer = _recoverSigner(hash, signature);
        if (signer == address(0)) revert InvalidSignature();
    }

    /**
     * @notice Verifies a personal message signature (eth_sign)
     * @param message The message that was signed
     * @param signature The signature to verify
     * @return signer The address that signed the message
     */
    function verifyPersonalSignature(
        string memory message,
        bytes memory signature
    ) public pure returns (address signer) {
        // Create personal message hash
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", bytes(message).length, message)
        );
        
        // Recover and verify signer
        signer = _recoverSigner(hash, signature);
        if (signer == address(0)) revert InvalidSignature();
    }

    /**
     * @dev Creates a EIP-712 typed data hash
     */
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
    }

    /**
     * @dev Recovers signer from signature
     */
    function _recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) revert InvalidSignatureLength();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) v += 27;
        if (v != 27 && v != 28) revert InvalidSignature();

        return ecrecover(hash, v, r, s);
    }

    /**
     * @notice Checks if a signature has been used
     * @param hash The hash of the signed message
     * @return bool True if signature has been used
     */
    function isSignatureUsed(bytes32 hash) external view returns (bool) {
        return _usedSignatures[hash];
    }
}
