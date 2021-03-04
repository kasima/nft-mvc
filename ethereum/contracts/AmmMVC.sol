//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPToken.sol";
/* import "hardhat/console.sol"; */

contract AmmReserve {
    using SafeMath for uint256;

    address public aTokenAddress;
    address public bTokenAddress;
    address public lpTokenAddress;
    IERC20 internal aToken;
    IERC20 internal bToken;
    LPToken internal lpToken;
    uint256 private poolA;
    uint256 private poolB;

    function getBReserve() public view returns (uint256){
        return poolB;
    }

    function getAReserve() public view returns (uint256){
        return poolA;
    }

    function getInvariant() public view returns (uint256) {
        return getAReserve().mul(getBReserve());
    }

    function _setAReserve(uint256 _amount) internal {
        poolA = _amount;
    }

    function _setBReserve(uint256 _amount) internal {
        poolB = _amount;
    }
}

contract AmmMVC is AmmReserve {
    using SafeMath for uint256;

    constructor(address _aToken,
                address _bToken,
                string memory _lpname,
                string memory _lpsymbol)
        public {
        (aToken, aTokenAddress) = (IERC20(_aToken), address(_aToken));
        (bToken, bTokenAddress) = (IERC20(_bToken), address(_bToken));
        lpToken= new LPToken(_lpname, _lpsymbol);
        lpTokenAddress = address(lpToken);
    }

    function addLiquidity(uint256 _aAmount, uint256 _bAmount)
        public
        nonZero(_aAmount)
        nonZero(_bAmount)
    {
        uint256 oldInvariant = getInvariant();
        require(
                SafeMath.mod(oldInvariant, _aAmount.mul(_bAmount) ) == 0,
                "LP inputs is not proportional to the reserves"
                );
        uint256 toMint;
        if (lpToken.totalSupply() == 0) {
            // liquidity provisioned should reflect the total Invariant in the system
            toMint = _aAmount.mul(_bAmount);
        } else {
            uint256 addInvariant = _aAmount.mul(_bAmount);
            uint256 newTotalSupply = addInvariant
                .add(oldInvariant)
                .mul(lpToken.totalSupply())
                .div(oldInvariant);
            toMint = newTotalSupply.sub(lpToken.totalSupply());
        }
        aToken.transferFrom(msg.sender, address(this), _aAmount);
        bToken.transferFrom(msg.sender, address(this), _bAmount);
        _setAReserve(getAReserve().add(_aAmount));
        _setBReserve(getBReserve().add(_bAmount));
        lpToken.mint(msg.sender, toMint);
    }

    function removeLiquidity(uint256 _amount) public nonZero(_amount) {
        lpToken.transferFrom(msg.sender, address(this), _amount);
        uint256 proportion = _amount.div(lpToken.totalSupply());
        uint256 aRemoved = getAReserve().mul(proportion);
        uint256 bRemoved = getBReserve().mul(proportion);
        lpToken.burn(_amount);
        _setAReserve(getAReserve().sub(aRemoved));
        _setBReserve(getBReserve().sub(bRemoved));
        aToken.transfer(msg.sender, aRemoved);
        bToken.transfer(msg.sender, bRemoved);
    }

    function getBtoAOutput(uint256 _bAmount) public view nonZero(_bAmount) returns (uint256) {
        uint256 invarient = getInvariant();
        uint256 newAReserve = invarient.div(getBReserve().add(_bAmount));
        return getAReserve().sub(newAReserve);
    }

    function getAtoBOutput(uint256 _aAmount) public view nonZero(_aAmount) returns (uint256) {
        uint256 invarient = getInvariant();
        uint256 newBReserve = invarient.div(getAReserve().add(_aAmount));
        return getBReserve().sub(newBReserve);
    }

    function swapBtoA(uint256 _bAmount) public nonZero(_bAmount) returns (uint256) {
        uint256 aOutput = getBtoAOutput(_bAmount);
        bToken.transferFrom(msg.sender, address(this), _bAmount);
        aToken.transfer(msg.sender, aOutput);
        _setAReserve(getAReserve().sub(aOutput));
        _setBReserve(getBReserve().add(_bAmount));
        return aOutput;
    }

    function swapAtoB(uint256 _aAmount) public nonZero(_aAmount) returns (uint256) {
        uint256 bOutput = getAtoBOutput(_aAmount);
        aToken.transferFrom(msg.sender, address(this), _aAmount);
        bToken.transfer(msg.sender, bOutput);
        _setAReserve(getAReserve().add(_aAmount));
        _setBReserve(getBReserve().sub(bOutput));
        return bOutput;
    }

    modifier nonZero(uint256 _amount) {
        require(_amount != 0, "amount can't be zero");
        _;
    }
}
