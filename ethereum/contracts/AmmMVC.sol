//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPToken.sol";
import "hardhat/console.sol";

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

// @title AMM.MVC
// @notice example implementation of constant function market making DEX in Solidity
contract AmmMVC is AmmReserve {
    using SafeMath for uint256;

    constructor(address _aToken,
                address _bToken,
                string memory _lpname,
                string memory _lpsymbol)
        {
            (aToken, aTokenAddress) = (IERC20(_aToken), address(_aToken));
            (bToken, bTokenAddress) = (IERC20(_bToken), address(_bToken));
            lpToken= new LPToken(_lpname, _lpsymbol);
            lpTokenAddress = address(lpToken);
        }

    // @notice add the caller's tokens onto the pools
    // @dev token A and B must be approved beforehand
    // @param _aAmount the amount of atokens to deposit
    // @param _bAmount the amount of btokens to deposit
    // @return amount of LP tokens minted to the caller
    function addLiquidity(uint256 _aAmount, uint256 _bAmount)
        public
        nonZero(_aAmount)
        nonZero(_bAmount)
        returns
        (uint256)
    {
        uint256 toMint;
        if (lpToken.totalSupply() > 0) {
            require(
                    _aAmount.div(_bAmount) == getAReserve().div(getBReserve()),
                    "the inputs are not the same ratio as the reserve"
                    );
        }
        // we simply mint the amount of a tokens deposited, given that the ratio is correct
        toMint = _aAmount;
        aToken.transferFrom(msg.sender, address(this), _aAmount);
        bToken.transferFrom(msg.sender, address(this), _bAmount);
        _setAReserve(getAReserve().add(_aAmount));
        _setBReserve(getBReserve().add(_bAmount));
        lpToken.mint(msg.sender, toMint);
        return toMint;
    }

    // @notice redeem an amount of LP token for token A and B
    // @dev LP token must be approved beforehand
    // @param _amount the amount of LP token to redeem
    // @return the amount of token A and B withdrawn to caller
    function removeLiquidity(uint256 _amount)
        public
        nonZero(_amount)
        returns
        (uint256 aRemoved, uint256 bRemoved)
    {
        lpToken.transferFrom(msg.sender, address(this), _amount);
        // remove tokens from reserve prorportionate to the current LP supply
        aRemoved = _amount.mul(getAReserve()).div(lpToken.totalSupply());
        bRemoved = _amount.mul(getBReserve()).div(lpToken.totalSupply());
        lpToken.burn(_amount);
        _setAReserve(getAReserve().sub(aRemoved));
        _setBReserve(getBReserve().sub(bRemoved));
        aToken.transfer(msg.sender, aRemoved);
        bToken.transfer(msg.sender, bRemoved);
    }

    // @notice calculate the expected A token output from B token amount
    // @param _bAmount amount in B token
    // @return the amount of token A
    function calculateBtoAOutput(uint256 _bAmount) public view returns (uint256) {
        uint256 memory invarient = getInvariant();
        uint256 newAReserve = invarient.div(getBReserve().add(_bAmount));
        return getAReserve().sub(newAReserve);
    }

    // @notice calculate the expected B token output from A token amount
    // @param _aAmount amount in A token
    // @return the amount of token B
    function calculateAtoBOutput(uint256 _aAmount) public view returns (uint256) {
        uint256 memory invarient = getInvariant();
        uint256 newBReserve = invarient.div(getAReserve().add(_aAmount));
        return getBReserve().sub(newBReserve);
    }

    // @notice swap B token for A token
    // @dev token B must be approved beforehand
    // @param _bAmount amount of btoken to swap
    // @return the amount of A token returned to caller
    function swapBtoA(uint256 _bAmount) public nonZero(_bAmount) returns (uint256) {
        uint256 aOutput = calculateBtoAOutput(_bAmount);
        bToken.transferFrom(msg.sender, address(this), _bAmount);
        aToken.transfer(msg.sender, aOutput);
        _setAReserve(getAReserve().sub(aOutput));
        _setBReserve(getBReserve().add(_bAmount));
        return aOutput;
    }

    // @notice swap A token for B token
    // @dev token A must be approved beforehand
    // @param _aAmount amount of btoken to swap
    // @return the amount of B token return to caller
    function swapAtoB(uint256 _aAmount) public nonZero(_aAmount) returns (uint256) {
        uint256 bOutput = calculateAtoBOutput(_aAmount);
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
