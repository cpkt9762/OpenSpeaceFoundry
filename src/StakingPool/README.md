#  StakingPool 合约，
    实现 Stake 和 Unstake 方法，
    允许任何人质押ETH来赚钱 KK Token。
    其中 KK Token 是每一个区块产出 10 个，
    产出的 KK Token 需要根据质押时长和质押数量来公平分配。

 

 测试用例
  ```bash
    forge test -vvvvv --match-path test/StakingPool/Stake.t.sol
    [PASS] testClaim() (gas: 272975) 
    [PASS] testStake() (gas: 114171) 
    [PASS] testUnstake() (gas: 274324) 
    Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 752.64µs (447.74µs CPU time)
    Ran 1 test suite in 6.51ms (752.64µs CPU time): 3 tests passed, 0 failed, 0 skipped (3 total tests)
  ```