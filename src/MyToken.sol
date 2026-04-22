// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyToken
 * @notice ERC20 with owner-governed minting, holder burning, and two-step ownership transfer (OpenZeppelin).
 * @dev Emits additional {Mint} and {Burn} events for indexers; standard ERC-20 {Transfer} still fires for mint/burn.
 */
contract MyToken is ERC20, ERC20Burnable, Ownable2Step {
    /// @notice Emitted when new tokens are created to `to` (mint path).
    event Mint(address indexed to, uint256 amount);

    /// @notice Emitted when tokens are destroyed from `from` (burn path).
    event Burn(address indexed from, uint256 amount);

    /**
     * @param name_ Token name (ERC-20 metadata).
     * @param symbol_ Token symbol (ERC-20 metadata).
     * @param initialOwner Account that receives {Ownable} rights; cannot be the zero address.
     */
    constructor(string memory name_, string memory symbol_, address initialOwner) ERC20(name_, symbol_) Ownable(initialOwner) {}

    /**
     * @notice Mint `amount` tokens to `to`. Callable only by the owner.
     * @param to Recipient; must not be the zero address (enforced by OpenZeppelin {_mint}).
     * @param amount Raw token amount (wei-like smallest units, respecting `decimals()`).
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Hook after balance updates: emit explicit {Mint}/{Burn} alongside inherited behavior.
     */
    function _update(address from, address to, uint256 value) internal override(ERC20) {
        super._update(from, to, value);
        if (from == address(0)) {
            emit Mint(to, value);
        }
        if (to == address(0)) {
            emit Burn(from, value);
        }
    }
}
