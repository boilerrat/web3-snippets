// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/***
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 *     |W|e|b|3| |S|n|i|p|p|e|t|
 *     +-+-+-+-+ +-+-+-+-+-+-+-+
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title EmergencyRecovery
 * @notice Allows recovery of ETH and ERC20 tokens accidentally sent to the contract
 * @dev Implements security patterns for safe token and ETH recovery with optional multisig
 */
contract EmergencyRecovery is Ownable(msg.sender), ReentrancyGuard {
    /// @dev Custom errors
    error ZeroAddress();
    error ZeroAmount();
    error TransferFailed();
    error InsufficientBalance();
    error InvalidSignersCount();
    error SignerAlreadyApproved();
    error NotApprovedSigner();
    error InsufficientApprovals();
    error RecoveryNotRequested();
    error InvalidRecoveryRequest();
    error MultisigNotEnabled();
    
    /// @notice Structure to store recovery request details
    struct RecoveryRequest {
        address requestor;      // Address requesting the recovery
        address recipient;      // Address to receive the recovered assets
        address token;         // Token address (address(0) for ETH)
        uint256 amount;        // Amount to recover
        uint256 timestamp;     // When the request was created
        mapping(address => bool) approvals;  // Track approvals from signers
        uint256 approvalCount; // Number of approvals received
        bool isActive;         // Whether the request is still active
    }
    
    /// @notice Multisig configuration
    bool public isMultisigEnabled;
    uint256 public requiredApprovals;
    mapping(address => bool) public isApprovedSigner;
    address[] public signers;
    
    /// @notice Recovery request tracking
    uint256 public currentRequestId;
    mapping(uint256 => RecoveryRequest) public recoveryRequests;
    
    /// @notice Recovery request cooldown period (24 hours)
    uint256 public constant RECOVERY_COOLDOWN = 24 hours;
    
    /// @notice Events
    event EthRecovered(address indexed requestor, address indexed to, uint256 amount);
    event TokensRecovered(address indexed token, address indexed requestor, address indexed to, uint256 amount);
    event RecoveryRequested(uint256 indexed requestId, address indexed requestor, address token, uint256 amount);
    event RecoveryApproved(uint256 indexed requestId, address indexed signer);
    event MultisigEnabled(uint256 requiredApprovals, address[] signers);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    /// @notice Allows receiving ETH
    receive() external payable {}
    
    /**
     * @notice Enables multisig functionality
     * @param _signers Array of signer addresses
     * @param _requiredApprovals Number of required approvals
     */
    function enableMultisig(
        address[] calldata _signers,
        uint256 _requiredApprovals
    ) external onlyOwner {
        if (_signers.length < _requiredApprovals) revert InvalidSignersCount();
        if (_requiredApprovals == 0) revert InvalidSignersCount();
        
        // Clear existing signers
        for (uint256 i = 0; i < signers.length; i++) {
            isApprovedSigner[signers[i]] = false;
        }
        
        // Set new signers
        for (uint256 i = 0; i < _signers.length; i++) {
            if (_signers[i] == address(0)) revert ZeroAddress();
            if (isApprovedSigner[_signers[i]]) revert SignerAlreadyApproved();
            isApprovedSigner[_signers[i]] = true;
        }
        
        signers = _signers;
        requiredApprovals = _requiredApprovals;
        isMultisigEnabled = true;
        
        emit MultisigEnabled(_requiredApprovals, _signers);
    }
    
    /**
     * @notice Disables multisig functionality
     */
    function disableMultisig() external onlyOwner {
        isMultisigEnabled = false;
        requiredApprovals = 0;
        
        // Clear signers
        for (uint256 i = 0; i < signers.length; i++) {
            isApprovedSigner[signers[i]] = false;
        }
        delete signers;
    }
    
    /**
     * @notice Requests a recovery of ETH
     * @param recipient Address to receive the ETH
     * @param amount Amount of ETH to recover
     */
    function requestEthRecovery(
        address recipient,
        uint256 amount
    ) external {
        if (recipient == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (amount > address(this).balance) revert InsufficientBalance();
        
        _createRecoveryRequest(msg.sender, recipient, address(0), amount);
    }
    
    /**
     * @notice Requests a recovery of ERC20 tokens
     * @param token Token address to recover
     * @param recipient Address to receive the tokens
     * @param amount Amount of tokens to recover
     */
    function requestTokenRecovery(
        address token,
        address recipient,
        uint256 amount
    ) external {
        if (token == address(0)) revert ZeroAddress();
        if (recipient == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (amount > balance) revert InsufficientBalance();
        
        _createRecoveryRequest(msg.sender, recipient, token, amount);
    }
    
    /**
     * @notice Approves a recovery request (for multisig)
     * @param requestId ID of the recovery request
     */
    function approveRecovery(uint256 requestId) external {
        if (!isMultisigEnabled) revert MultisigNotEnabled();
        if (!isApprovedSigner[msg.sender]) revert NotApprovedSigner();
        
        RecoveryRequest storage request = recoveryRequests[requestId];
        if (!request.isActive) revert RecoveryNotRequested();
        if (request.approvals[msg.sender]) revert SignerAlreadyApproved();
        
        request.approvals[msg.sender] = true;
        request.approvalCount++;
        
        emit RecoveryApproved(requestId, msg.sender);
        
        // Execute recovery if enough approvals
        if (request.approvalCount >= requiredApprovals) {
            _executeRecovery(requestId);
        }
    }
    
    /**
     * @notice Executes a recovery request (owner can bypass multisig)
     * @param requestId ID of the recovery request
     */
    function executeRecovery(uint256 requestId) external onlyOwner {
        _executeRecovery(requestId);
    }
    
    /**
     * @notice Internal function to create a recovery request
     */
    function _createRecoveryRequest(
        address requestor,
        address recipient,
        address token,
        uint256 amount
    ) internal {
        uint256 requestId = ++currentRequestId;
        
        RecoveryRequest storage request = recoveryRequests[requestId];
        request.requestor = requestor;
        request.recipient = recipient;
        request.token = token;
        request.amount = amount;
        request.timestamp = block.timestamp;
        request.isActive = true;
        
        emit RecoveryRequested(requestId, requestor, token, amount);
    }
    
    /**
     * @notice Internal function to execute a recovery
     */
    function _executeRecovery(uint256 requestId) internal nonReentrant {
        RecoveryRequest storage request = recoveryRequests[requestId];
        if (!request.isActive) revert RecoveryNotRequested();
        
        // Mark request as processed
        request.isActive = false;
        
        // Execute recovery based on token type
        if (request.token == address(0)) {
            // ETH recovery
            (bool success, ) = request.recipient.call{value: request.amount}("");
            if (!success) revert TransferFailed();
            emit EthRecovered(request.requestor, request.recipient, request.amount);
        } else {
            // Token recovery
            bool success = IERC20(request.token).transfer(request.recipient, request.amount);
            if (!success) revert TransferFailed();
            emit TokensRecovered(request.token, request.requestor, request.recipient, request.amount);
        }
    }
    
    /**
     * @notice Returns the contract's current ETH balance
     */
    function getEthBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @notice Returns the contract's balance of a specific ERC20 token
     */
    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}