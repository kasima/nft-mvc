//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract AmmReserve {
    uint256 private aReserve;
    uint256 private bReserve;

    function getBReserve() public view returns (uint256){
        return bReserve;
    }

    function getAReserve() public view returns (uint256){
        return aReserve;
    }

    function setAReserve(uint256 _amount) public returns (uint256) {
        aReserve = _amount;
        return aReserve;
    }

    function setBReserve(uint256 _amount) public returns (uint256) {
        bReserve = _amount;
        return bReserve;
    }

}

contract AmmMVC is AmmReserve {
    using SafeMath for uint256;

    function getAFromB(uint256 _b) public view returns (uint256) {
        uint256 invarient = getAReserve().mul(getBReserve());
        uint256 newAReserve = invarient.div(getBReserve().add(_b));
        return getAReserve().sub(newAReserve);
    }

    function getBFromA(uint256 _a) public view returns (uint256) {
        uint256 invarient = getAReserve().mul(getBReserve());
        uint256 newBReserve = invarient.div(getAReserve().add(_a));
        return getBReserve().sub(newBReserve);
    }

    function swapAFromB(uint256 _b) public returns (uint256) {
        uint256 aOutput = getAFromB(_b);
        setBReserve(getBReserve().add(_b));
        setAReserve(getAReserve().sub(aOutput));
        return aOutput;
    }

    function swapBFromA(uint256 _a) public returns (uint256){
        uint256 bOutput = getBFromA(_a);
        setAReserve(getAReserve().add(_a));
        setBReserve(getBReserve().sub(bOutput));
        return bOutput;
    }

}
