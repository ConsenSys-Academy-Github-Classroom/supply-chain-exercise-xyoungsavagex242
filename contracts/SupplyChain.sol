// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {
  //State Variables
  
  address public owner;

  uint public skuCount;

  mapping(uint => Item) public items;

  enum State{ForSale, Sold, Shipped, Received}
  State choice;
  State constant defaultChoice = State.ForSale;

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  //Events
  event LogForSale(uint sku);

  event LogSold(uint sku);

  event LogShipped(uint sku);

  event LogReceived(uint sku);

  //Modifiers

  modifier isOwner() {
    require (msg.sender == owner);
    _;
  }

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
    _;
  }

  modifier forSale(uint _sku) { 
    require(items[_sku].seller != address(0));
    require(items[_sku].state == State.ForSale);
    require(items[_sku].buyer == address(0));
    _;

  }

  modifier sold(uint _sku) {

    require(items[_sku].state == State.Sold);
    require(items[_sku].buyer != address(0));

    _;

  }

  modifier shipped(uint _sku) {

    require(items[_sku].state == State.Shipped);
    require(items[_sku].buyer != address(0));

    _;

  }

  modifier received(uint _sku) {

    require(items[_sku].state == State.Received);
    require(items[_sku].buyer != address(0));

    _;

  }

  constructor() public {
    owner == msg.sender;
    skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
     items[skuCount] = Item({
     name: _name, 
     sku: skuCount, 
     price: _price, 
     state: State.ForSale, 
     seller: msg.sender, 
     buyer: address(0)
    });

    skuCount = skuCount + 1;
    emit LogForSale(skuCount);
    return true;
  }

  function buyItem(uint sku) public payable forSale(sku) paidEnough(items[sku].price) checkValue(sku) {

    Item storage item = items[sku];
    item.seller.transfer(item.price);
    item.buyer = msg.sender;
    item.state = State.Sold;

    emit LogSold(sku);

  }

  function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller) {

    Item storage item = items[sku];
    item.state = State.Shipped;

    emit LogShipped(sku);

  }

function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer) {

    Item storage item = items[sku];
    item.state = State.Received;

    emit LogReceived(sku);
  }

  function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer){

  name = items[_sku].name;

  sku = items[_sku].sku;

  price = items[_sku].price;

  state = uint(items[_sku].state);

  seller = items[_sku].seller;

  buyer = items[_sku].buyer;

  return (name, sku, price, state, seller, buyer);

  }
}
