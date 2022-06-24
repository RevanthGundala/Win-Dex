// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WinToken is ERC20 {
    uint private s_totalSupply;

    constructor(uint256 initialSupply) ERC20("WinToken", "Win") {
        s_totalSupply += initialSupply;
        _mint(msg.sender, initialSupply);
    }
}
