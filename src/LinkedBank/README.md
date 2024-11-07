
/*
 *   编写一个 Bank 存款合约，实现功能：
 *   1.可以通过 Metamask 等钱包直接给 Bank 合约地址存款
 *   2.在 Bank 合约里记录了每个地址的存款金额
 *   3.用可迭代的链表保存存款金额的前 10 名用户
 */

```bash
forge clean&&forge test -vvvvv  --match-path test/LinkedBank/TokenBank.t.sol --ffi
```

src/LinkedBank/LinkedBankKeys.sol 是链表的实现 