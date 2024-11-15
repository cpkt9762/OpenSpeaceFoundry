
# 编写 MyDex 合约，任何人都可以通过 sellETH 方法出售ETH兑换成 USDT，也可以通过 buyETH 将 USDT 兑换成 ETH。 

```bash
   
    interface IDex {

        /**
        * @dev 卖出ETH，兑换成 buyToken
        *      msg.value 为出售的ETH数量
        * @param buyToken 兑换的目标代币地址
        * @param minBuyAmount 要求最低兑换到的 buyToken 数量
        */
        function sellETH(address buyToken,uint256 minBuyAmount) external payable  

        /**
        * @dev 买入ETH，用 sellToken 兑换
        * @param sellToken 出售的代币地址
        * @param sellAmount 出售的代币数量
        * @param minBuyAmount 要求最低兑换到的ETH数量
        */
        function buyETH(address sellToken,uint256 sellAmount,uint256 minBuyAmount) external   
    }

---bash---

---test---
    forge test -v --match-path test/DEX/DexSwap.t.sol  
    [PASS] testBuyETHWithRNT() (gas: 344407)
    [PASS] testSellETHForRNT() (gas: 232710)
    Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 5.01ms (3.82ms CPU time)
    Ran 1 test suite in 51.34ms (5.01ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
---