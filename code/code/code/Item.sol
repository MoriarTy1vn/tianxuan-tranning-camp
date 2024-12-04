pragma solidity ^0.4.24;

import "./ERC721.sol";

contract Item is ERC721{
    
    struct GameItem{
        string name; // Name of the Item
        uint level; // Item Level
        uint rarityLevel;  // 1 = normal, 2 = rare, 3 = epic, 4 = legendary
    }
    
    GameItem[] public items; // First Item has Index 0
    address public owner;
    mapping(address => uint[]) private userAssets; // 用户资产
    mapping(address => bool) private whiteList; // 白名单
    mapping(bytes => bool) private usedSignatures; // 已使用签名
    mapping(uint => uint) private tokenPrices; // Token价格

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Minted(address indexed user, uint tokenId);
    event BatchMinted(address indexed admin, address[] users, uint[] tokenIds);
    event WhiteListAdded(address[] users);
    event WhiteListRemoved(address[] users);
    
    constructor () public payable {
        owner = msg.sender; // The Sender is the Owner; Ethereum Address of the Owner
    }
    
    function createItem(string _name, address _to) public{
        require(owner == msg.sender); // Only the Owner can create Items
        uint id = items.length; // Item ID = Length of the Array Items
        items.push(GameItem(_name,5,1)); // Item ("Sword",5,1)
        _mint(_to,id); // Assigns the Token to the Ethereum Address that is specified
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyWhiteListed() {
        require(whiteList[msg.sender], "Not in white list");
        _;
    }

    // 更换Owner
    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // 管理员批量mint NFT
    function batchMintByOwner(address[] memory users, uint[] memory tokenIds) public onlyOwner {
        require(users.length == tokenIds.length, "Mismatched arrays");
        for (uint i = 0; i < users.length; i++) {
            userAssets[users[i]].push(tokenIds[i]);
            emit Minted(users[i], tokenIds[i]);
        }
        emit BatchMinted(msg.sender, users, tokenIds);
    }

    // 用户自己购买NFT
    function mint(uint tokenId) payable public {
        require(msg.value >= tokenPrices[tokenId], "Insufficient payment");
        userAssets[msg.sender].push(tokenId);
        emit Minted(msg.sender, tokenId);
    }

    // 白名单用户自己mint
    function mintByWhiteList(uint tokenId) public onlyWhiteListed {
        userAssets[msg.sender].push(tokenId);
        emit Minted(msg.sender, tokenId);
    }

    // 批量增加白名单
    function addWhiteList(address[] memory users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            whiteList[users[i]] = true;
        }
        emit WhiteListAdded(users);
    }

    // 批量移除白名单
    function removeWhiteList(address[] memory users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            whiteList[users[i]] = false;
        }
        emit WhiteListRemoved(users);
    }

    // 查询用户的资产
    function owner(address user) public view returns (uint[] memory) {
        return userAssets[user];
    }

    // 链下白名单验证 (签名方式)
    function mintWithSignature(uint tokenId, uint price, bytes memory signature) public payable{
        require(!usedSignatures[signature], "Signature already used");
        require(msg.value >= price, "Insufficient payment");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, tokenId, price));
        require(recoverSigner(hash, signature) == owner, "Invalid signature");

        usedSignatures[signature] = true;
        userAssets[msg.sender].push(tokenId);
        emit Minted(msg.sender, tokenId);
    }

    // 签名验证工具函数
    function recoverSigner(bytes32 hash, bytes memory signature) private pure returns (address) {
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(messageHash, v, r, s);
    }

    function splitSignature(bytes memory signature) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }

    // 定义token价格
    function setTokenPrice(uint tokenId, uint price) public onlyOwner {
        tokenPrices[tokenId] = price;
    }

    // 查询token价格
    function getTokenPrice(uint tokenId) public view returns (uint) {
        return tokenPrices[tokenId];
    }
    
}