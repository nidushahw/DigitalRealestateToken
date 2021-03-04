// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.8.0;

import "./ERC721Standard.sol";

contract DigitalREToken is ERC721Standard {
    struct Asset {
        uint256 assetId;
        uint256 price;
    }

    uint256 public assetsCount;
    mapping(uint256 => Asset) public assetMap;
    address public supervisor;
    mapping(uint256 => address) private assetOwner;
    mapping(address => uint256) private ownedAssetsCount;
    mapping(uint256 => address) public assetApprovals;
    string private _name;
    string private _symbol;

    constructor(string memory _name_, string memory _symbol_) ERC721Standard(_name_, _symbol_) {
        supervisor = msg.sender;
        _name = _name_;
        _symbol = _symbol_;
    }

    function addAsset(uint256 price, address to) public {
        require(supervisor == msg.sender, "Not A Supervisor");
        assetMap[assetsCount] = Asset(assetsCount, price);
        mint(to, assetsCount);
        assetsCount = assetsCount + 1;
    }

    function build(uint256 assetId, uint256 value) public payable {
        require(isApprovedOrOwner(msg.sender, assetId), "Not An Approved owner");
        require(msg.value >= (value * 1000000000000000000 / 100), "Not enough commision");
        Asset memory oldAsset = assetMap[assetId];
        assetMap[assetId] = Asset(oldAsset.assetId, oldAsset.price + value);
    }

    function balanceOf() public view returns (uint256) {
        require(msg.sender != address(0), "ERC721: balance query for the zero address");
        return ownedAssetsCount[msg.sender];
    }

    function ownerOf(uint256 assetId) public view override returns (address) {
        address owner = assetOwner[assetId];
        require(owner != address(0), "No Asset Exists");
        return owner;
    }

    function transferFrom(address payable from, uint256 assetId) public payable {
        require(isApprovedOrOwner(msg.sender, assetId), "Not An Approved Owner");
        require(ownerOf(assetId) == from, "Not The asset Owner");
        clearApproval(assetId, getApproved(assetId));
        ownedAssetsCount[from]--;
        ownedAssetsCount[msg.sender]++;
        assetOwner[assetId] = msg.sender;
        from.transfer(assetMap[assetId].price * 1000000000000000000);
        emit Transfer(from, msg.sender, assetId);
    }

    function approve(address to, uint256 assetId) public override {
        address owner = ownerOf(assetId);
        require(to != owner, "CurrentOwnerApproval");
        require(msg.sender == owner, "NotTheAssetOwner");
        assetApprovals[assetId] = to;
        emit Approval(owner, to, assetId);
    }

    function getApproved(uint256 assetId) public view override returns (address) {
        require(exists(assetId), "Approved query for nonexistent token");
        return assetApprovals[assetId];
    }

    function clearApproval(uint256 assetId, address approved) public {
        require(isApprovedOrOwner(msg.sender, assetId), "Not An Approved Owner");
        if (assetApprovals[assetId] == approved) {
            assetApprovals[assetId] = address(0);
        }
    }

    function getAssetsSize() public view returns (uint256) {
        return assetsCount;
    }

    function mint(address to, uint256 assetId) internal override {
        require(supervisor == msg.sender, "Not A Manager");
        require(!exists(assetId), "AlreadyMinted");
        assetOwner[assetId] = to;
        ownedAssetsCount[to]++;
        emit Transfer(address(0), to, assetId);
    }

    function exists(uint256 assetId) internal view returns (bool) {
        return assetOwner[assetId] != address(0);
    }

    function isApprovedOrOwner(address spender, uint256 assetId) internal view returns (bool) {
        require(exists(assetId), "Query for nonexistent token");
        address owner = ownerOf(assetId);
        return (spender == owner || getApproved(assetId) == spender);
    }
}
