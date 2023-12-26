// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//INTERNAL IMPORT FOR NFT OPENZIPLINE
import {ERC721URIStorage} from "node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from  "node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

//import "hardhat/console.sol";


contract NFTmarketplace is ERC721, ERC721URIStorage{

    uint256 private _tokenIds;
    uint256 private _itemSold;

    uint256 listingPrice = 0.0025 ether;

    address payable owner;

    mapping(uint256 => MarketItem) private idMarketItem;

    struct MarketItem{
        uint256 tokendId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    modifier onlyOwner{
        require(msg.sender == owner, "only owner of the marketplace can change the listing price");
        _;
    }

    constructor() ERC721("NFT Metaverse Token", "MYNFT"){
        owner == payable(msg.sender); 
    }

    function updateListingPrice(uint256 _listingPrice) onlyOwner public payable{
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256){
        return listingPrice;
    }

    function createToken(string memory tokenURI, uint256 price) public payable returns(uint256){
        _tokenIds++;
        uint256 newTokenID = _tokenIds;

        _mint(msg.sender, newTokenID);
        
        _setTokenURI(newTokenID, tokenURI);
        
        createMarketItem(newTokenID, price);

        return newTokenID;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be bigger than 0");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, adrress(this), tokenId);

        emit idMarketItemCreated(tokenId, msg.sender, adrress(this), price, false);
    }

    function reSellToken(uint256 tokenId, uint256 price) public payable{
        require(idMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemSold--;

        _transfer(msg.sender, adrress(this), tokenId);
    }

    function createMarketSell(uint256 tokenId) public payable{
        uint256 price = idMarketItem[tokenId].price;

        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));

        _itemSold++;

        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }

    function fetchMarketItem() public view returns(MarketItem[] memory){
        uint256 itemCount = _tokenIds;
        uint256 unSoldItemCount = _tokenIds - _itemSold;
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        for (uint256 i = 0; i < itemCount; i++){
            if(idMarketItem[i+1].owner == address(this)){
                uint256 currentId = i+1;

                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    function fetchMyNFT() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i = 0; i < totalCount; i++){
            if(idMarketItem[i+1].owner == msg.sender){
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++){
            if(MarketItem[i+1].owner == msg.sender){
                uint256 currentId = i+1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    function fetchItemsListed() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds;
        uint256 itemCount = 0;
        uint256 itemIndex = 0;

        for (uint256 i = 0; i < totalCount; i++){
            if (idMarketItem[i+1].seller == msg.sender){
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++){
            if (idMarketItem[i+1].seller == msg.sender){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[itemIndex] = currentItem;
                itemIndex++;
            }
        }
        return items;
    }

    
}