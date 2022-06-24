// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./WinFactory.sol";
import "./WinToken.sol";

error WinPair__UnproportionalAmountDeposited(uint amountA, uint amountB);
error WinPair__NotEnoughLiquidity();
error WinPair__ZeroAmountDeposited(uint amount);
error WinPair__LiquidityProvidersExist();
error WinPair__InsufficientBalance();

contract WinPair {
    address private immutable i_tokenA;
    address private immutable i_tokenB;
    address[] private s_liquidityProviders;
    address private tokenToBeSwapped;
    address private tokenToBeGiven;

    uint private s_balanceTokenA;
    uint private s_balanceTokenB;
    uint private constant TRADING_FEE = 1;

    mapping(address => uint) private tokenTobalance;
    mapping(address => uint) private balanceOfUser;

    /* Events */
    event liquiditySet(uint indexed amountA, uint indexed amountB);
    event liquidityAdded(uint indexed amountA, uint indexed amountB);
    event swappedTokens(address indexed tokenA, address indexed tokenB);
    event balancesUpdated(address indexed tokenA, address indexed tokenB);
    event paidLiquidityProviders(uint indexed amount);

    constructor(address tokenA, address tokenB) {
        i_tokenA = tokenA;
        i_tokenB = tokenB;
    }

    // Tasks:
    // swap tokens
    // update balances of each token
    // subtract trading fee from user's account
    function swap(address _tokenToBeSwapped, uint _amountOfToken)
        public
        returns (uint)
    {
        // require statement
        checkAmount(_amountOfToken);
        checkLiquidity();

        // calculate how many tokens should be recieved
        // x * y = k
        /*

        EXAMPLE
        1. enter in tokenToBeSwapped and _amountOfToken
        2. Look into the liquidity pool for that token pair (how many of each token do I have)
        3. Determine the ratio from amountOfTokenTObeRecieved to _amountOfTokenToBeSwapped

        Let's say I have 10 ETH / 5 BTC in this Liquidity Pool.
        I want to get some BTC, so I swap 1 ETH for X BTC. 
        How to solve for X?
        10 ETH / 5 WBTC = 9 ETH / X WBTC
        5/10 = 4/

        45 / 10 = X WBTC
        9 = s_balanceTokenA
        X = s_balanceTokenB
        5 - X = amount of WBTC we give to user

    */

        uint initialBalanceA = s_balanceTokenA;
        uint initialBalanceB = s_balanceTokenB;
        uint amountGiven;

        if (i_tokenA == _tokenToBeSwapped) {
            tokenToBeSwapped = i_tokenA;
            tokenToBeGiven = i_tokenB;

            s_balanceTokenA -= _amountOfToken;
            s_balanceTokenB =
                (s_balanceTokenA * initialBalanceB) /
                initialBalanceA;

            amountGiven = initialBalanceB - s_balanceTokenB;
        } else {
            tokenToBeSwapped = i_tokenB;
            tokenToBeGiven = i_tokenA;

            s_balanceTokenB -= _amountOfToken;
            s_balanceTokenA =
                (s_balanceTokenB * initialBalanceA) /
                initialBalanceB;
            amountGiven = initialBalanceA - s_balanceTokenA;
        }

        // tell the user to pay for those fees and send them to the liquidity providers
        balanceOfUser[msg.sender] -= TRADING_FEE;

        for (uint i = 0; i < s_liquidityProviders.length; i++) {
            // Figure out how to send trading fee to everyone based on number of WIN Tokens
            // you have

            balanceOfUser[s_liquidityProviders[i]] +=
                TRADING_FEE /
                s_liquidityProviders.length;
        }

        // send the number of tokens the user wants
        (bool callSuccess, ) = payable(msg.sender).call{value: _amountOfToken}(
            ""
        );
        require(callSuccess, "Call failed");

        emit swappedTokens(tokenToBeSwapped, tokenToBeGiven);

        // update each of the balances in the LP when swap is made
        // tokenTobalance[tokenToBeSwapped] -= _amountOfToken;
        // tokenTobalance[tokenToBeGiven] += amountGiven;
        emit balancesUpdated(tokenToBeSwapped, tokenToBeGiven);
        return amountGiven;
    }

    // function to get number of liquidity providers for pair
    // function to pay fees to liquidity providers (based on who has ERC20 token)
    function payLiquidityProviders() public payable {}

    // function to set liqiudity if this is the first itme the pair is being created
    function setLiquidity(uint _amountA) external {
        // require that amounts are valid
        checkAmount(_amountA);
        // require that there is no liquidity provider for this pair
        // -> can conclude that no one has deposited liquidity yet
        checkLiquidityProvidersExist();

        s_balanceTokenA += _amountA;

        // figure out how much it costs user to deposit liqiudity
        //  balanceOfUser[msg.sender] -=

        s_liquidityProviders.push(msg.sender);
        emit liquiditySet(_amountA, _amountB);
    }

    // function to add liquidity to that pair
    //should give our ERC20 token if liquidity is added
    // based on liquidity provided

    function addLiquidity(uint _amountA, uint _amountB) external {
        //   checkPairDoesNotExist(i_pair);
        checkAmount(_amountA, _amountB);

        s_balanceTokenA += _amountA;
        s_balanceTokenB += _amountB;

        s_liquidityProviders.push(msg.sender);
        emit liquidityAdded(_amountA, _amountB);
    }

    // should return the number of tokens we have for tokenA
    function returnLiquidityTokenA() external view returns (uint) {
        return (s_balanceTokenA);
    }

    // should return the number of tokens we have for tokenB
    function returnLiquidityTokenB() external view returns (uint) {
        return (s_balanceTokenB);
    }

    // function to update prices of each token based on quantity in reserves

    function checkAmount(uint _amount) internal pure {
        if (_amount <= 0) {
            revert WinPair__ZeroAmountDeposited(_amount);
        }
    }

    // should make sure there is enough of each token to let the trade go through

    function checkLiquidity() internal view {
        if (s_balanceTokenA <= 0 || s_balanceTokenB <= 0) {
            revert WinPair__NotEnoughLiquidity();
        }
    }

    function checkLiquidityProvidersExist() internal view {
        if (s_liquidityProviders.length > 0) {
            revert WinPair__LiquidityProvidersExist();
        }
    }

    function getTradingFee() external view returns (uint) {
        return TRADING_FEE;
    }

    function checkBalanceOfUser() public view {
        if (balanceOfUser[msg.sender] <= TRADING_FEE) {
            revert WinPair__InsufficientBalance();
        }
    }
}
