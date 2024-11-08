 
安全挑战：Hack Vault

题目#1
Fork 代码库：
https://github.com/OpenSpace100/openspace_ctf

阅读代码  Vault.sol 及测试用例，在测试用例中 testExploit 函数添加一些代码，设法取出预先部署的 Vault 合约内的所有资金。
以便运行 forge test 可以通过所有测试。

 
```bash
forge clean&&forge test -vvvvv  --match-path test/HackCtf/Vault.t.sol --ffi
```
