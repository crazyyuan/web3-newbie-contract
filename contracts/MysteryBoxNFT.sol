// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Web3WomenNewbieD2 is
    ERC721Enumerable,
    VRFConsumerBaseV2,
    ConfirmedOwner
{
    address private constant _vrfCoordinator =
        0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    uint256 public constant price = 0.001 ether;
    string public baseURI;

    uint64 s_subscriptionId;
    VRFCoordinatorV2Interface COORDINATOR;
    uint public totalBoxes; // 所有盲盒数量
    bool public allowReveal = false; // 是否可以开盲盒
    uint public revealedCount; // 已开盲盒的数量
    string public constant unrevealURI =
        "ipfs://bafkreifllatjbirndw5umq5lsj77ibcebnrbhvk24qrpfyweqleicg457y"; // 盲盒的默认 metadata json 地址

    struct TokenInfo {
        bool requested;
        uint fileId;
    }
    mapping(uint => TokenInfo) private tokenInfoMap; // tokenId => TokenInfo
    mapping(uint => uint) public vrfTokenIdMap; // requestId => tokenId
    mapping(uint => uint) public referIdMap; // 存储文件池中的文件是否被使用过

    constructor(
        string memory _baseURI,
        uint256 _totalBoxes,
        uint64 subscriptionId
    )
        ERC721("Web3WomenNewbie", "WNW")
        VRFConsumerBaseV2(_vrfCoordinator)
        ConfirmedOwner(msg.sender)
    {
        baseURI = _baseURI;

        totalBoxes = _totalBoxes;

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function mint() external payable {
        require(totalSupply() < totalBoxes, "Mint exceed max supply");
        require(price <= msg.value, "Ether value sent is not correct");

        uint256 mintIndex = totalSupply();
        _safeMint(_msgSender(), mintIndex + 1);
    }

    // 请求开盲盒
    function requestReveal(uint _tokenId) external {
        require(allowReveal, "you can not open the box now"); // 确保当前允许开盲盒
        require(
            ownerOf(_tokenId) == msg.sender,
            "the nft does not belong to you"
        ); // 确保要开的 nft 属于 msg.sender
        require(
            !tokenInfoMap[_tokenId].requested,
            "the nft has requested random number"
        ); // 确保 _tokenId 未请求过随机数

        // 请求随机数(需要钱包有充足Link代币)
        uint requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            3,
            100000,
            5
        );
        tokenInfoMap[_tokenId].requested = true;

        // 存储 requestId 对应的 tokenId
        vrfTokenIdMap[requestId] = _tokenId;
    }

    // chainlink 回调，并传入请求ID 和 随机数
    function fulfillRandomWords(
        uint requestId,
        uint[] memory randomWords
    ) internal override {
        // 获取tokenId
        uint tokenId = vrfTokenIdMap[requestId];
        // 随机数
        uint random = randomWords[0];

        TokenInfo memory tokenInfo = tokenInfoMap[tokenId];

        // tokenId 已请求过随机数了 且 未设置盲盒ID
        if (tokenInfo.requested && tokenInfo.fileId == 0) {
            uint remainCount = totalBoxes - revealedCount;
            // 从剩下的文件池中随机取一个(生成 1 ~ remainCount 之间的随机数)
            uint index = (random % remainCount) + 1;

            // 获取随机的 index 是否曾被随机过
            uint referId = referIdMap[index];

            if (referId > 0) {
                // 曾随机到 index
                // 1. 设置 tokenId 对应的文件id是 referId
                // 2. 将 referIdMap[index] 设置为末尾未使用的元素
                tokenInfo.fileId = referId;
                referIdMap[index] = remainCount;
            } else {
                // 未随机到 index
                // 1. 设置 tokenId 对应的文件id是 index
                // 2. 将 referIdMap[index] 设置为末尾未使用的元素
                tokenInfo.fileId = index;
                referIdMap[index] = remainCount;
            }
            // 已开盲盒数 + 1
            revealedCount++;
        }
    }

    function setAllowReveal(bool _allowReveal) external onlyOwner {
        allowReveal = _allowReveal;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "token not exist");
        if (!allowReveal) return unrevealURI;

        uint fileId = tokenInfoMap[tokenId].fileId;
        // 盲盒未开
        if (fileId == 0) return unrevealURI;
        return string(abi.encodePacked(baseURI, Strings.toString(fileId)));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }
}
