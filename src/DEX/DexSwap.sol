// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@uniswapv2/UniswapV2Router02.sol";
import "@uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@uniswapv2/interfaces/IERC20.sol";

contract DexSwap {
    IUniswapV2Router02 public routerV2;
    address public wEnt;

    constructor(address _uniswapV2Router) {
        routerV2 = IUniswapV2Router02(_uniswapV2Router);
        wEnt = routerV2.WETH();
    }

    /**
     * @notice 购买ETH
     * @param amountIn 输入的代币数量
     * @param tokenIn 输入的代币地址
     * @param amountOutMin 最小输出数量
     * @return amounts 输出数量
     */
    function buyETH(uint256 amountIn, address tokenIn, uint256 amountOutMin)
        external
        returns (uint256[] memory amounts)
    {
        // 如果用户没有授权，则授权
        if (IERC20(tokenIn).allowance(msg.sender, address(routerV2)) < amountIn) {
            IERC20(tokenIn).approve(address(routerV2), amountIn);
        }

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = address(wEnt);
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        amounts = routerV2.swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, block.timestamp);
    }

    /**
     * @notice 出售ETH
     * @param tokenOut 输出的代币地址
     * @return amounts 输出数量
     * msg.value: 输入的ETH数量
     */
    function sellETH(address tokenOut) external payable returns (uint256[] memory amounts) {
        require(msg.value > 0, "You need to sell some ETH");
        address[] memory path = new address[](2);
        path[0] = address(wEnt);
        path[1] = tokenOut;

        // to calucalte the expected token amount by swap with eth amount
        uint256 amountOut = getAmountOut(msg.value, path);

        // 出售ETH
        amounts = routerV2.swapETHForExactTokens{value: msg.value}(amountOut, path, msg.sender, block.timestamp);
    }

    /**
     * @notice 计算用户想要获得的代币数量
     * @param amountIn 输入的ETH数量
     * @param path 路径
     * @return amountOut 输出数量
     */
    function getAmountOut(uint256 amountIn, address[] memory path) internal view returns (uint256 amountOut) {
        require(path.length >= 2, "Invalid path");
        // 使用 Uniswap V2 路由器的 getAmountsOut 函数来计算代币数量
        uint256[] memory amounts = routerV2.getAmountsOut(amountIn, path);

        // 返回最后一个元素，即代币数量
        amountOut = amounts[amounts.length - 1];
    }

    receive() external payable {}
}
