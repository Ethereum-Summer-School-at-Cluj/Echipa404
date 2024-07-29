// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BroskiBottle is Ownable {
    struct CollectionRequest {
        address supplier;
        address collector;
        uint256 bottleCount;
        uint256 tokenAmount;
        bool supplierConfirmed;
        bool collectorConfirmed;
        bool isCompleted;
    }

    IERC20 public bottleToken;
    CollectionRequest[] public requests;
    uint256 public constant FEE_PERCENTAGE = 100; // 1% fee
    uint256 public constant TOKENS_PER_BOTTLE = 1; // Static token amount per bottle

    event RequestCreated(uint256 requestId, address indexed supplier, uint256 bottleCount, uint256 tokenAmount);
    event RequestAccepted(uint256 requestId, address indexed collector);
    event CollectionConfirmed(uint256 requestId);

    constructor(address tokenAddress) Ownable(msg.sender) {
        bottleToken = IERC20(tokenAddress);
    }

    function createRequest(uint256 bottleCount) public {
        uint256 tokenAmount = bottleCount * TOKENS_PER_BOTTLE;
        requests.push(CollectionRequest({
            supplier: msg.sender,
            collector: address(0),
            bottleCount: bottleCount,
            tokenAmount: tokenAmount,
            supplierConfirmed: false,
            collectorConfirmed: false,
            isCompleted: false
        }));
        emit RequestCreated(requests.length - 1, msg.sender, bottleCount, tokenAmount);
    }

    function acceptRequest(uint256 requestId) public {
        require(requestId < requests.length, "Invalid request ID");
        CollectionRequest storage request = requests[requestId];
        require(request.collector == address(0), "Request already accepted");
        request.collector = msg.sender;
        emit RequestAccepted(requestId, msg.sender);
    }

    function confirmCollection(uint256 requestId) public {
        require(requestId < requests.length, "Invalid request ID");
        CollectionRequest storage request = requests[requestId];
        require(msg.sender == request.supplier || msg.sender == request.collector, "Only involved parties can confirm");
        
        if (msg.sender == request.supplier) {
            request.supplierConfirmed = true;
        } else if (msg.sender == request.collector) {
            request.collectorConfirmed = true;
        }

        if (request.supplierConfirmed && request.collectorConfirmed) {
            request.isCompleted = true;
            transactBottles(requestId);
            emit CollectionConfirmed(requestId);
        }
    }

    function transactBottles(uint256 requestId) internal {
        CollectionRequest storage request = requests[requestId];
        require(request.isCompleted, "Collection not completed");
        require(bottleToken.allowance(request.collector, address(this)) >= request.tokenAmount, "Token allowance too low");

        uint256 feeAmount = (request.tokenAmount * FEE_PERCENTAGE) / 10000;
        uint256 remainingAmount = request.tokenAmount - feeAmount;
        uint256 supplierAmount = remainingAmount / 2;
        uint256 collectorAmount = remainingAmount - supplierAmount;

        // Transfer fee to the app (contract owner)
        require(bottleToken.transferFrom(request.collector, owner(), feeAmount * 10 ** 18), "Fee transfer failed");
        
        // Transfer tokens from collector to supplier
        require(bottleToken.transferFrom(request.collector, request.supplier, supplierAmount * 10 ** 18), "Supplier transfer failed");
        
        // Transfer remaining tokens from collector to collector as profit
        require(bottleToken.transferFrom(request.collector, request.collector, collectorAmount * 10 ** 18), "Collector transfer failed");
    }
}
