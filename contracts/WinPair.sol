// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* imports */
import "./WinFactory.sol";
import "./WinToken.sol";

/* Errors */
error WinPair__NotEnoughLiquidityA(uint balance);
error WinPair__NotEnoughLiquidityB(uint balance);
error WinPair__ZeroAmountDeposited(uint amount);
error WinPair__LiquidityProvidersExist(uint providers);
error WinPair__InsufficientBalance(uint balance);
error WinPair__ZeroAddress(address token);

contract WinPair {
    /* constant and immutable variables */
    uint private constant TRADING_FEE = 1;
    address private immutable i_tokenA;
    address private immutable i_tokenB;

    /* address type storage variables */
    address[] private s_liquidityProviders;
    address private s_tokenToBeSwapped;
    address private s_tokenToBeGiven;

    /* uint type storage variables */
    uint private s_balanceTokenA;
    uint private s_balanceTokenB;
    uint private s_k;
    uint private s_amountOtherToken;

    /* mappings */
    mapping(address => uint) private s_balanceOfUser;

    /* Events */
    event liquiditySet(uint indexed amountA, uint indexed amountB);
    event liquidityAdded(uint indexed amountA, uint indexed amountB);
    event swappedTokens(address indexed tokenA, address indexed tokenB);
    event paidLiquidityProviders(uint indexed amount);

    constructor(address tokenA, address tokenB) {
        i_tokenA = tokenA;
        i_tokenB = tokenB;
    }

    // should swap tokens based on user's input
    function swap(address _tokenToBeSwapped, uint _amountOfToken) public {
        // require statements
        checkAmount(_amountOfToken);
        checkLiquidity();

        uint initialTokenBalanceA = s_balanceTokenA;
        uint initialTokenBalanceB = s_balanceTokenB;

        // Logic behind swap
        //     x * y = k
        // --> 5 * 5 = 25
        // --> 4 * X = 25
        // --> X = 25 / 4

        if (i_tokenA == _tokenToBeSwapped) {
            require(
                s_balanceTokenA > _amountOfToken,
                "Not Enough liquidity for token"
            );
            s_balanceTokenA -= _amountOfToken;
            s_balanceTokenB = s_k / s_balanceTokenA;
            s_amountOtherToken = s_balanceTokenB - initialTokenBalanceB;
        } else {
            require(
                s_balanceTokenB > _amountOfToken,
                "Not Enough liquidity for token"
            );
            s_balanceTokenB -= _amountOfToken;
            s_balanceTokenA = s_k / s_balanceTokenB;
            s_amountOtherToken = s_balanceTokenA - initialTokenBalanceA;
        }

        // send the number of tokens the user wants
        (bool callSuccess, ) = payable(msg.sender).call{value: _amountOfToken}(
            ""
        );
        require(callSuccess, "Call failed");
        emit swappedTokens(s_tokenToBeSwapped, s_tokenToBeGiven);

        payLiquidityProviders();
    }

    // should pay trading fees to liquidity providers
    function payLiquidityProviders() public payable {
        s_balanceOfUser[msg.sender] -= TRADING_FEE;
        uint profit = TRADING_FEE / s_liquidityProviders.length;
        for (uint i = 0; i < s_liquidityProviders.length; i++) {
            // Figure out how to send trading fee to everyone based on number of WIN Tokens
            // you have

            s_balanceOfUser[s_liquidityProviders[i]] += profit;
        }
        emit paidLiquidityProviders(profit);
    }

    // should set liquidity if this is the first time the pair is being created
    function setLiquidity(uint _amountA, uint _amountB) external {
        // require that amounts are valid
        checkAmount(_amountA);
        checkAmount(_amountB);

        // require that there is no liquidity provider for this pair
        // -> can conclude that no one has deposited liquidity yet
        checkLiquidityProvidersExist();

        // update balance of tokens
        s_balanceTokenA += _amountA;
        s_balanceTokenB += _amountB;

        // s_k should remain constant for this pairk
        s_k = s_balanceTokenA * s_balanceTokenB;

        // fee for creating a new liquidity pool taken by DEX
        (bool callSuccess, ) = payable(msg.sender).call{value: TRADING_FEE}("");
        require(callSuccess, "Call failed");

        s_liquidityProviders.push(msg.sender);
        emit liquiditySet(_amountA, _amountB);
    }

    // should allow users to add liquidity for an existing pair
    function addLiquidity(uint _amount, address _token) external {
        checkAmount(_amount);

        uint initialTokenBalanceA = s_balanceTokenA;
        uint initialTokenBalanceB = s_balanceTokenB;

        // Logic for adding liquidity
        //     x * y = k
        // --> 5 * 5 = 25
        // --> 7* X = 25
        // --> X = 25 / 7

        if (i_tokenA == _token) {
            s_balanceTokenA += _amount;
            s_balanceTokenB = s_k / s_balanceTokenA;
            s_amountOtherToken = initialTokenBalanceB - s_balanceTokenB;
        } else {
            s_balanceTokenB += _amount;
            s_balanceTokenA = s_k / s_balanceTokenB;
            s_amountOtherToken = initialTokenBalanceA - s_balanceTokenA;
        }

        // add the user to the liquidity providers array
        s_liquidityProviders.push(msg.sender);

        // emit liquidity added event
        emit liquidityAdded(_amount, s_amountOtherToken);
    }

    function getAmountOtherToken() external view returns (uint) {
        return s_amountOtherToken;
    }

    // should return the number of tokens we have for tokenA
    function getLiquidityTokenA() external view returns (uint) {
        return (s_balanceTokenA);
    }

    // should return the number of tokens we have for tokenB
    function getLiquidityTokenB() external view returns (uint) {
        return (s_balanceTokenB);
    }

    function getTradingFee() external pure returns (uint) {
        return TRADING_FEE;
    }

    // function to update prices of each token based on quantity in reserves

    function checkAmount(uint _amount) internal pure {
        if (_amount <= 0) {
            revert WinPair__ZeroAmountDeposited(_amount);
        }
    }

    // should make sure there is enough of each token to let the trade go through
    function checkLiquidity() internal view {
        if (s_balanceTokenA <= 0) {
            revert WinPair__NotEnoughLiquidityA(s_balanceTokenA);
        }

        if (s_balanceTokenB <= 0) {
            revert WinPair__NotEnoughLiquidityB(s_balanceTokenB);
        }
    }

    // should check if liquidity providers exist
    function checkLiquidityProvidersExist() internal view {
        if (s_liquidityProviders.length > 0) {
            revert WinPair__LiquidityProvidersExist(
                s_liquidityProviders.length
            );
        }
    }

    // should check the balance of the user to see if they can pay trading fee
    function checkBalanceOfUser() public view {
        if (s_balanceOfUser[msg.sender] <= TRADING_FEE) {
            revert WinPair__InsufficientBalance(s_balanceOfUser[msg.sender]);
        }
    }

    function checkToken(address _token) internal pure {
        if (_token == address(0)) {
            revert WinPair__ZeroAddress(_token);
        }
    }
}
