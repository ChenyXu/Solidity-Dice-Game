// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Dice is VRFConsumerBaseV2 {
    using SafeMath for uint;

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId = 1787;
    address vrfCoordinator = 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f;
    bytes32 keyHash = 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;

    address public owner;
    uint public dealerBalance;
    mapping (uint => betInfo) public IdToBetInfo;

    enum Choice {BIG, SMALL, NONE}

    struct betInfo{
        address player;
        uint size;
        Choice choice;
        Choice result;
    }

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        owner = msg.sender;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function requestRandomWords() internal returns(uint) {
        uint s_requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
        return s_requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint result = randomWords[0] % 6 + 1;
        if (result > 0 && result <=3){
            IdToBetInfo[requestId].result = Choice.SMALL;
        } else {
            IdToBetInfo[requestId].result = Choice.BIG;
        }

        
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function dealerDeposit() external payable onlyOwner {
        dealerBalance = dealerBalance.add(msg.value);
    }

    function dealerWithdraw() external onlyOwner {
        address payable _owner = payable(owner);
        _owner.transfer(address(this).balance);
        dealerBalance = 0;
    }

    function betBig() external payable returns(uint) {
        uint id = requestRandomWords();
        IdToBetInfo[id] = betInfo(msg.sender, msg.value, Choice.BIG, Choice.NONE);
        return id;
    }

    function betSmall() external payable returns(uint) {
        uint id = requestRandomWords();
        IdToBetInfo[id] = betInfo(msg.sender, msg.value, Choice.SMALL, Choice.NONE);
        return id;        
    }

    function playerWithdraw(uint _requestId) external {
        require(msg.sender == IdToBetInfo[_requestId].player,"You are not the winner");
        require(IdToBetInfo[_requestId].result != Choice.NONE);
        if (IdToBetInfo[_requestId].choice == IdToBetInfo[_requestId].result){
            address payable _address = payable(msg.sender);
            _address.transfer(IdToBetInfo[_requestId].size * 2);
        }
    }

}
