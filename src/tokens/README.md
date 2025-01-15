# SafeERC20Transfer

A gas-optimized utility contract for safely handling ERC20 token transfers, specifically designed to handle both standard and non-standard token implementations.

## Features

- Handles both standard and non-standard ERC20 token transfers
- Gas-efficient implementation (safeTransfer avg: ~55k gas, safeTransferFrom avg: ~43k gas)
- Verifies transfer success through return value checks
- Works with tokens that don't return success boolean
- Minimal and simple implementation for lower attack surface

## Usage

```solidity
// Import the contract
import {SafeERC20Transfer} from "./SafeERC20Transfer.sol";

contract YourContract is SafeERC20Transfer {
    // For transferring tokens owned by the contract
    function transferTokens(IERC20 token, address recipient, uint256 amount) external {
        safeTransfer(token, recipient, amount);
    }

    // For transferring tokens on behalf of someone else (requires approval)
    function transferTokensFrom(IERC20 token, address from, address to, uint256 amount) external {
        safeTransferFrom(token, from, to, amount);
    }
}
```

## Functions

### safeTransfer
Transfers tokens owned by the contract to a recipient.
```solidity
function safeTransfer(
    IERC20 token,
    address recipient,
    uint256 amount
) public returns (bool)
```

### safeTransferFrom
Transfers tokens from one address to another (requires approval).
```solidity
function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 amount
) public returns (bool)
```

## Testing Status

- ✅ Full test suite with Forge
- ✅ Fuzz testing completed
- ✅ Deployment tested on Base Sepolia
- ✅ Contract verified on Basescan

## Security Notes

- Simple and auditable implementation
- Uses Solidity 0.8.28+ for built-in overflow protection
- Tested against both standard and non-standard ERC20 implementations

## License

MIT

## Contract Address

Deployed and verified on Base Sepolia: `0x949a9cd24f8445f65ed782adb98b0f075ef858a2`

## Base Sepolia Explorer

https://sepolia.basescan.org/address/0x949a9cd24f8445f65ed782adb98b0f075ef858a2     

## Gist Location

https://gist.github.com/web3snippets/949a9cd24f8445f65ed782adb98b0f075ef858a2