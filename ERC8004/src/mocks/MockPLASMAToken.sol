// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockPLASMAToken
 * @notice Mock ERC-20 token for testing purposes
 * @dev Simple ERC-20 with public minting for tests
 */
contract MockPLASMAToken is ERC20 {
    /**
     * @notice Constructor
     */
    constructor() ERC20("PLASMA Token", "PLASMA") {
        // Mint initial supply to deployer for testing
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    /**
     * @notice Mint tokens to any address (for testing)
     * @param to Address to mint to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @notice Burn tokens from caller
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
