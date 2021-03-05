//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LPToken is ERC20, Ownable {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    }

    function mint (address receiver, uint256 amount) public onlyOwner {
        _mint(receiver, amount);
    }

    function burn (uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
}
