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
    string public baseURI;
    uint256 public maxSupply;

    bytes32 public merkleRoot;
    mapping(address => uint256) whiteListMints;

    constructor(
        string memory _baseURI,
        uint256 _maxSupply
    ) ERC721("Web3WomenNewbieD4", "WNWD4") {
        baseURI = _baseURI;
        maxSupply = _maxSupply;
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function mint() external payable {
        require(status == Status.Started, "Didn't start");

        require(totalSupply() < maxSupply, "Mint exceed max supply");
        require(price <= msg.value, "Ether value sent is not correct");

        uint256 mintIndex = totalSupply();
        _safeMint(_msgSender(), mintIndex + 1);
    }

    function airdrop(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(status == Status.Started, "Didn't start");

        require(
            receivers.length == amounts.length,
            "the length of accounts is not equal to amounts"
        );

        uint256 total = totalSupply();
        for (uint256 i = 0; i < receivers.length; i++) {
            total = total + amounts[i];
        }
        require(maxSupply >= total, "Exceeded max supply.");

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], amounts[i]);
        }
    }

    function allowlistMint(bytes32[] calldata merkleProof) external payable {
        require(
            status == Status.AllowListOnly || status == Status.Started,
            "Status error"
        );

        require(totalSupply() < maxSupply, "Mint exceed max supply");
        require(price <= msg.value, "Ether value sent is not correct");

        address from = _msgSender();

        require(whiteListMints[from] < 1, "You have minted in allow list");

        require(merkleProof.length > 0, "MerkleProof is empty.");
        bytes32 leaf = keccak256(abi.encodePacked(from));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "the whitelist mismatch."
        );

        _safeMint(from, 1);
        refundIfOver(price);

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
