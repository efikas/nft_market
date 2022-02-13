//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./IERC721.sol";

contract Market {
    enum ListingStatus {
        Active, Sold, Cancelled
    }

    struct Listing {
        ListingStatus status;
        address seller;
        address token;
        uint tokenId;
        uint price;
    }

    event Listed (
        uint listingId,
        address seller,
        address token,
        uint tokenId,
        uint price
    );

    event Sale(
        uint listingId,
        address buyer, 
        address token,
        uint tokenId,
        uint price
    );

    event Cancel(
        uint listingId,
        address seller
    );


    uint private _listingId = 0;
    mapping(uint => Listing) private _listings;

    function getListing(uint listingId) public view returns (Listing memory){
        return _listings[listingId]; 
    }

    function listToken(address token,  uint tokenId, uint price) public {
        IERC721(token).transferFrom(msg.sender, address(this), tokenId);
        Listing memory listing = Listing(ListingStatus.Active,  msg.sender, token, tokenId, price);
 
        _listingId++;
        _listings[_listingId] = listing;

        emit Listed(_listingId, msg.sender, token, tokenId, price);
    }


    function buyToken (uint listingId) external payable {
        Listing storage listing = _listings[listingId];

        require(msg.sender != listing.seller, "Seller cannot be buyer");
        require(listing.status == ListingStatus.Active, "Listing is not active");

        require(msg.value >= listing.price, "Insufficient fund"  );
        IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenId);

        //pay the seller
        payable(listing.seller).transfer(listing.price); 
        
        emit Sale(
            listingId,
            msg.sender,
            listing.token,
            listing.tokenId,
            listing.price
        );
    }

    function cancel (uint listingId) external {
        Listing storage listing = _listings[listingId];

        require(msg.sender == listing.seller, "Only seller can cancel listing");
        require(listing.status == ListingStatus.Active, "Listing is not active");

        listing.status = ListingStatus.Cancelled;
        IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenId);

        emit Cancel(listingId, listing.seller); 
    }
}
