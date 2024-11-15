// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "@src/DEX/DexSwap.sol";
import "@src/DEX/WETH9.sol";
import "@uniswapv2/UniswapV2Factory.sol";
import "@uniswapv2/UniswapV2Pair.sol";
import "@uniswapv2/UniswapV2Router02.sol";
import "@uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@uniswapv2/libraries/UniswapV2Library.sol";
import {RNT as RNTToken} from "@src/RNT/RNT.sol";

contract DexSwapTest is Test {
    DexSwap myDex;
    WETH9 WETH;
    RNTToken RNT;
    IUniswapV2Router02 uniswapV2Router;
    UniswapV2Factory factory;
    address tokenWETH;
    address tokenRNT;

    function setUp() public {
        WETH = new WETH9();
        factory = new UniswapV2Factory(address(0));
        uniswapV2Router = new UniswapV2Router02(address(factory), address(WETH));
        RNT = new RNTToken();
        myDex = new DexSwap(address(uniswapV2Router));
        // add 20 ETH, 1000 RNT
        (uint256 amountWETH, uint256 amountRNT, uint256 liquidity) = _addLiquidity(20 ether, 1000 ether);
    }

    /**
     * @notice Test buy ETH with RNT
     * 测试BUY ETH with RNT
     */
    function testBuyETHWithRNT() public {
        _addLiquidity(20 ether, 1000 ether);
        // Approve and deposit tokens
        uint256 buyETHAmount = 1 ether;
        RNT.approve(address(myDex), buyETHAmount);

        address[] memory path = new address[](2);
        path[0] = address(RNT);
        path[1] = address(WETH);

        uint256[] memory amountOuts = uniswapV2Router.getAmountsOut(buyETHAmount, path);

        // get balance before buy eth
        uint256 balanceBeforeBuyETH = address(this).balance;
        console.log("balanceBeforeBuyETH:", balanceBeforeBuyETH);

        uint256 amountOut = amountOuts[amountOuts.length - 1];

        myDex.buyETH(buyETHAmount, address(RNT), amountOut);

        // Check if the balance of the contract has increased
        assertGe(address(this).balance, balanceBeforeBuyETH + amountOut);
    }

    /**
     * @notice Test sell ETH for RNT
     * 测试Sell ETH for RNT
     */
    function testSellETHForRNT() public {
        uint256 balanceRNTBeforeSellETH = RNT.balanceOf(address(this));
        console.log("balanceRNTBeforeSellETH:", balanceRNTBeforeSellETH);

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(RNT);

        uint256[] memory amounts = uniswapV2Router.getAmountsOut(1 ether, path);
        assertTrue(amounts[amounts.length - 1] > 0);
        assertTrue(amounts[0] == 1 ether);

        uint256 expectedRNTAmountOut = amounts[amounts.length - 1];

        // sell ETH
        myDex.sellETH{value: 1 ether}(address(RNT));

        // Check if the balance of RNT has increased
        uint256 finalBalance = RNT.balanceOf(address(this));
        assertEq(finalBalance, balanceRNTBeforeSellETH + expectedRNTAmountOut);
    }

    /**
     * @notice Add liquidity
     * 添加流动性
     * amountWETH: 输入的WETH数量
     * amountRNT: 输入的RNT数量
     */
    function _addLiquidity(uint256 amountWETH, uint256 amountRNT)
        private
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        // Approve tokens
        WETH.deposit{value: amountWETH}();
        RNT.approve(address(uniswapV2Router), amountRNT);
        WETH.approve(address(uniswapV2Router), amountWETH);

        tokenWETH = address(WETH);
        tokenRNT = address(RNT);

        // Add liquidity
        (amountA, amountB, liquidity) = uniswapV2Router.addLiquidity(
            tokenWETH, tokenRNT, 10 ether, 1000 ether, 0, 0, address(this), block.timestamp
        );
    }

    // Function to receive ETH from WETH withdraw
    receive() external payable {}
}
