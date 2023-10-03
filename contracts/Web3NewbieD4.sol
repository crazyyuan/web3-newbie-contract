// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Web3WomenNewbieD4 is ERC721Enumerable, Ownable {
    enum Status {
        Waiting,
        Started,
        Finished,
        AllowListOnly
    }
    Status public status;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public constant price = 0.001 ether;
    uint256 public constant allowPrice = 0.0005 ether;
    string public baseURI;
    uint256 public maxSupply;

    bytes32 public merkleRoot;
    mapping(address => uint256) whiteListMints;

    address[] public whiteList;

    constructor(
        string memory _baseURI,
        uint256 _maxSupply
    ) ERC721("Web3WomenNewbieD4", "WNWD4") {
        baseURI = _baseURI;
        maxSupply = _maxSupply;
        _tokenIdCounter.increment();
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setAllowList(address[] calldata list) public onlyOwner {
        for (uint256 i = 0; i < whiteList.length; i++) {
            whiteList.pop();
        }
        for (uint256 i = 0; i < list.length; i++) {
            whiteList.push(list[i]);
        }
    }

    function mint() external payable {
        require(status == Status.Started, "Didn't start");

        require(totalSupply() < maxSupply, "Mint exceed max supply");
        require(price <= msg.value, "Ether value sent is not correct");

        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), tokenId);
        _tokenIdCounter.increment();
    }

    function airdrop(address[] calldata receivers) external onlyOwner {
        require(status == Status.Started, "Didn't start");

        uint256 total = totalSupply();
        for (uint256 i = 0; i < receivers.length; i++) {
            total = total + 1;
        }
        require(maxSupply >= total, "Exceeded max supply.");

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(receivers[i], tokenId);
            _tokenIdCounter.increment();
        }
    }

    function allowlistMint2(bytes32[] calldata merkleProof) external payable {
        require(
            status == Status.AllowListOnly || status == Status.Started,
            "Status error"
        );

        require(totalSupply() < maxSupply, "Mint exceed max supply");
        require(allowPrice <= msg.value, "Ether value sent is not correct");

        address from = _msgSender();

        require(whiteListMints[from] < 1, "You have minted in allow list");

        require(merkleProof.length > 0, "MerkleProof is empty.");
        bytes32 leaf = keccak256(abi.encodePacked(from));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "the whitelist mismatch."
        );

        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(from, tokenId);
        _tokenIdCounter.increment();

        refundIfOver(allowPrice);

        whiteListMints[from] = 1;
    }

    function allowlistMint() external payable {
        require(
            status == Status.AllowListOnly || status == Status.Started,
            "Status error"
        );

        require(totalSupply() < maxSupply, "Mint exceed max supply");
        require(allowPrice <= msg.value, "Ether value sent is not correct");

        address from = _msgSender();

        require(whiteListMints[from] < 1, "You have minted in allow list");

        bool verified = false;
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (from == whiteList[i]) {
                verified = true;
                break;
            }
        }
        require(verified, "the whitelist mismatch.");

        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(from, tokenId);
        _tokenIdCounter.increment();

        refundIfOver(allowPrice);

        whiteListMints[from] = 1;
    }

    function refundIfOver(uint256 totalPrice) private {
        require(msg.value >= totalPrice, "insufficient ETH.");
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            return "";
        }
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }
}
