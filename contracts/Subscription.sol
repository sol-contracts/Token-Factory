/* Contract of basic subscription

  NOTE that thic contract require 1 whole token (with 18 decimals) to subscribe
  this mechanics possible will break if token has not 18 decimals.
  probably we need to set multiplex = token decimals or we need to set 18 _decimals
  as a standard token decimals

  advertisment is selling for tokens, price is setting up by owner of Subscription
  it will give us ability to separate price for subscription and price for advertisment
  inside channel, so user can buy subscription for 0.01$ but by advertisment for 100$ for example

  NOTE also that for now it is only basic functionality for buing advertisment
  in the future I suppose we need to improve this, to give owner ability to accept OR
  reject incoming ads proposals before accepting payments

*/

pragma solidity ^0.4.24;

import "./Token.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Subscription is Ownable {

  // Token stuff
  Token token;
  mapping (address => uint) public users;
  address crowdsale;

  uint8 public decimals;
  uint public mainUnit;

  // Deal staff
  struct DealInfo {
      uint LockId;
      address buyer;
      uint lockedFunds;
      uint16 status;
  }


  mapping (uint => DealInfo) public deals;

  //enum types for DealStatus
  uint16 constant internal Open = 0;
  uint16 constant internal Accepted = 1;
  uint16 constant internal Rejected = 2;



  // EVENTS-------------DEBUG ----------------------------------------------------------------

    //event counters
    uint public contentCount = 0;
    uint public logsCount = 0;

    event LogDebug(string message);

    event LogEvent(uint indexed lockId, uint16 eventType, address indexed sponsor, uint payment);

//----------------------------------------------------------------------------------------
  // array of sponsors.
  mapping (address => bool) public sponsors;




  event signedUp(address who);
  event signedOut(address who);
  event banned(address who);


  constructor(address _token, address _owner, address _crowdsale) public {

    token = Token(_token);
    owner = _owner;
    crowdsale = _crowdsale;

    decimals = token.decimals();
    setUnit();

  }

  function getUsers(address _user) public view returns(uint){
    uint user = users[_user];
    return user;
  }

  function setUnit() internal returns (bool) {
    uint n = decimals - 1;
    mainUnit = 10 ** n;
    return true;
  }


  function signUp() public{

    uint am = 1 * mainUnit;
    token.transferFrom(msg.sender,this,am);
    users[msg.sender]=am;
    emit signedUp(msg.sender);
  }

  function signOut() public{
    uint am = 1 * mainUnit;
    token.transfer(msg.sender,am);
    users[msg.sender]=0;
    emit signedOut(msg.sender);
  }

  function banUser(address _user) public onlyOwner {

    uint am = 1 * mainUnit;
    token.transfer(crowdsale,am);
    users[_user]=0;
    emit banned(msg.sender);

  }



/*

        DEAL MECHANISM
  Deal mechanics originally designed for SONM marketplace.
  Also you could find some primitives here:
  https://github.com/JackBekket/escrow-eth

  I will use simplifyc escrow mechanisc because I want to implement escrow
  mechanins to the Moon Shard in the future



*/

//Start deal with escrow
function start(uint _lockId, uint _value) public {

    //reject money transfers for bad status


    //create default DealInfo struct or access existing
    // it MAY BE  a pitfall, cause I'm not sure are we saving deals right way?
    // but obviously info exist only inside a function, doesn't it?
    DealInfo memory info = deals[_lockId];

    //lock only once for a given id
    // This is a serious part, do NOT remove it
    if(info.lockedFunds > 0) revert();

    //lock funds
    // This part will transfer from sponsor address token value
    require(token.transferFrom(msg.sender,this,_value));


    // buyer init escrow deal.
    info.buyer = msg.sender;
    info.lockedFunds = _value;
    // 0 = Open
    info.status = 0;
  //  pendingCount += _count;
    sponsors[msg.sender] = true;

    // Save details
     deals[_lockId] = info;

    //Start order to event log
    emit LogEvent(_lockId, Open, msg.sender, _value);
}

// Accept deal
function accept(uint _lockId) public onlyOwner
{
  DealInfo memory info = deals[_lockId];
  info.status = 1;
  uint _value = info.lockedFunds;
  deals[_lockId] = info;
  require(token.transfer(owner,_value));

  //Accept order eventType
  emit LogEvent(_lockId, Accepted, msg.sender, _value);

}

// Reject deal
function reject(uint _lockId) public onlyOwner
{
  DealInfo memory info = deals[_lockId];
  info.status = 2;
  uint _value = info.lockedFunds;
  address _to = info.buyer;
  deals[_lockId] = info;
  require(token.transfer(_to,_value));
  emit LogEvent(_lockId, Accepted, msg.sender, _value);

}

}
