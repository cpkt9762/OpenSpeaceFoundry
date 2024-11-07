// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@src/AirdopMerkleNFTMarket/AirdopMerkleNFTMarke.sol";
import "@src/AirdopMerkleNFTMarket/MyNFT.sol";
import "@src/AirdopMerkleNFTMarket/MyPermitToken.sol";
import "./SignatureHelper.sol";

contract AirdropMerkleNFTMarkeTest is Test {
    AirdropMerkleNFTMarke airdropMerkleNFTMarke;
    address alice;
    uint256 alicepk;
    MyPermitToken myPermitToken;
    MyERC721NFT myNFT;
    bytes32 merkleRoot = keccak256("root");
    SignatureHelper signatureHelper;
    address whiteUser;
    bytes32[] merkleproof;

    function setUp() public {
        (alice, alicepk) = makeAddrAndKey("alice");
        myPermitToken = new MyPermitToken();
        myNFT = new MyERC721NFT();

        /**
         * // 白名单用户地址
         *         const whitelist = [
         *         '0x1111111111111111111111111111111111111111',
         *         '0x2222222222222222222222222222222222222222',
         *         '0x3333333333333333333333333333333333333333',
         *         '0x4444444444444444444444444444444444444444'
         *         ];
         *
         * Merkle Root: 0x8ea0e3a5b1bcc3d21d094be4a529068bb97ef23671d5a18bc24c5ae11cffdbf7
         *     Proof for address: 0x1111111111111111111111111111111111111111 [
         *     '0x2ab0a4443bbea3fbe4d0e1503d11ff1367842fb0c8b28a5c8550f27599a40751',
         *     '0x0aafebc39b02f78812dd98aa2d43138e57bf2e2129476469fcffb7c1d572f346'
         *     ]
         */
        merkleproof = new bytes32[](2);
        merkleproof[0] = 0x2ab0a4443bbea3fbe4d0e1503d11ff1367842fb0c8b28a5c8550f27599a40751;
        merkleproof[1] = 0x0aafebc39b02f78812dd98aa2d43138e57bf2e2129476469fcffb7c1d572f346;
        merkleRoot = 0x8ea0e3a5b1bcc3d21d094be4a529068bb97ef23671d5a18bc24c5ae11cffdbf7;

        whiteUser = address(0x1111111111111111111111111111111111111111);

        bytes32 leaf = keccak256(abi.encodePacked(whiteUser));
        bool isWhitelisted = MerkleProof.verify(merkleproof, merkleRoot, leaf);
        console.log("isWhitelisted", isWhitelisted);

        signatureHelper = new SignatureHelper(myPermitToken.DOMAIN_SEPARATOR());
        airdropMerkleNFTMarke = new AirdropMerkleNFTMarke(address(myPermitToken), address(myNFT), merkleRoot);
        myPermitToken.mint(address(airdropMerkleNFTMarke), 1000);
        vm.deal(alice, 1000 ether);
        vm.deal(whiteUser, 1000 ether);
        myPermitToken.transfer(whiteUser, 1 ether);
    }

    /*
     测试 claimNFT
    */
    function test_claimNFT() public {
        uint256 price = 1000;
        uint256 deadline = block.timestamp + 1 days;
        uint256 tokenId = 0;
        uint256 nonce = 0;
        // owner mint nft 并授权给市场
        vm.startPrank(alice);
        tokenId = myNFT.mintNFT("ipfs://AliceNFT");
        myNFT.approve(address(airdropMerkleNFTMarke), tokenId);

        //
        airdropMerkleNFTMarke.list(tokenId, price, deadline);
        vm.stopPrank();

        // 离线签名
        SignatureHelper.Permit memory permit = SignatureHelper.Permit(alice, whiteUser, tokenId, nonce, deadline);
        bytes32 digest = signatureHelper.getTypeData(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicepk, digest);

        // 授权
        vm.startPrank(alice);
        uint256 amount = 500;
        airdropMerkleNFTMarke.permitPrePay(alice, whiteUser, tokenId, amount, deadline, v, r, s);

        // 通过默克尔树验证白名单，并利用 permitPrePay 的授权，转入 token 转出 NFT
        airdropMerkleNFTMarke.claimNFT(tokenId, whiteUser, merkleproof);
        vm.stopPrank();
    }

    // test multicall
    function test_multicall() public {
        uint256 tokenId = 0;

        vm.startPrank(alice);
        tokenId = myNFT.mintNFT("ipfs://AliceNFT");
        myNFT.approve(address(airdropMerkleNFTMarke), tokenId);

        // owner 上架
        uint256 price = 1000;
        uint256 deadline = block.timestamp + 1 days;
        airdropMerkleNFTMarke.list(tokenId, price, deadline);
        vm.stopPrank();

        // 离线签名
        uint256 nonce = 0;
        SignatureHelper.Permit memory permit =
            SignatureHelper.Permit(alice, address(airdropMerkleNFTMarke), tokenId, nonce, deadline);
        bytes32 digest = signatureHelper.getTypeData(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicepk, digest);

        // 购买
        vm.startPrank(alice);
        vm.stopPrank();

        vm.startPrank(whiteUser);

        bytes memory data =
            abi.encodeWithSelector(airdropMerkleNFTMarke.claimNFT.selector, tokenId, whiteUser, merkleproof);
        bytes[] memory datas = new bytes[](1);
        datas[0] = data;
        airdropMerkleNFTMarke.multicall(datas);
        vm.stopPrank();
    }
}
