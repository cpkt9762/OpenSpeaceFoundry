使用Solidity内联汇编修改合约Owner地址


# 使用Solidity内联汇编修改合约Owner地址

## 1. 使用 forge 测试合约
forge test -vv  --match-path test/AsmOwer/MyWallet.t.sol


## 2. 日志输出
[⠊] Compiling...
No files changed, compilation skipped

Ran 3 tests for test/AsmOwer/MyWallet.t.sol:MyWalletTest
[PASS] test_getOwner() (gas: 10820)
[PASS] test_setOwner() (gas: 16754)
[PASS] test_transferOwnership() (gas: 16647)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 1.03ms (149.90µs CPU time)