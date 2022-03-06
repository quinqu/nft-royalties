// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract NFTRoyalties is ERC721 {
    address public owner; 
    // royaltyArr is a structure that holds the addresses
    // of people who will be payed a royalty for each sale. 
    address[] public royaltyArr;

    // Address of the ERC20 token. 
    address public txFeeToken; 

    // Amount to get in total per re-sale. 
    uint public txFeeAmount; 

    // txFeePercentage is the percentage of what to give to each person. 
    uint public royaltyPercentage; 

    // People who are excluded from paying royalties 
    mapping(address => bool) public excludeList; 

    constructor(address _owner, address[] memory _royaltyArr, address _txFeeToken, uint _royaltyPercentage) ERC721('My NFT', 'ABC') {
        owner = _owner;
        royaltyArr = _royaltyArr;
        txFeeToken = _txFeeToken;
        royaltyPercentage = _royaltyPercentage;
        for (uint i = 0; i < royaltyArr.length; i ++) {
            excludeList[royaltyArr[i]] = true; 
        }
        // _mint(artist, 0);
    }

    function setExcluded(address excluded, bool status) external {
        require(msg.sender == owner, "owner is the only person who can set values in excludeList");
        excludeList[excluded] = status; 
    } 

    // Here we are overriding transferFrom from the ERC721 standard. 
    // The tokenID (NFT)
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require( _isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');
        if(excludeList[from] == false) {
            _payTxFee(from);
        }
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        if(excludeList[from] == false) {
            _payTxFee(from);
        }
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');
        if(excludeList[from] == false) {
            _payTxFee(from);
        }
        _safeTransfer(from, to, tokenId, _data);
    }

    // You can't implement royalty system with ETH because the method 
    // signature requires a payable keyword (required for sending ETH) and would not match openzeppelin's 
    // method signature. 
    function _payTxFee(address from) internal {
        IERC20 token = IERC20(txFeeToken);
        uint len = royaltyArr.length; 
        uint amountPerRoyaltyReciever = txFeeAmount / len; 
        for (uint i = 0; i < royaltyArr.length; i++) {
            token.transferFrom(from, royaltyArr[i], amountPerRoyaltyReciever);
        }
    }
}