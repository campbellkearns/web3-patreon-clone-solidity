// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract Series is Ownable {
  using SafeMath for uint;
  string public title;
  uint public pledgePerEpisode;
  uint public minimumPublicationPeriod;

  mapping(address => uint) public pledges;
  address[] pledgers;
  uint public lastPublicationBlock;
  mapping(uint => string) public publishedEpisodes;
  uint public episodeCounter;

  constructor(string memory _title_, uint _pledgePerEpisode_, uint _minimumPublicationPeriod_) public {
    title = _title_;
    pledgePerEpisode = _pledgePerEpisode_;
    minimumPublicationPeriod = _minimumPublicationPeriod_;
  }

  function pledge() public payable {
    require(pledges[msg.sender].add(msg.value) >= pledgePerEpisode, "Pledge must be great than pledge per episode.");
    require(msg.sender != owner(), "An owner cannot pledge on their own series.");

    bool oldPledger = false;
    for(uint i = 0; i < pledgers.length; i++) {
      if(pledgers[i] == msg.sender) {
        oldPledger = true;
        break;
      }
    }
    if(!oldPledger) {
      pledgers.push(msg.sender);
    }

    pledges[msg.sender] = pledges[msg.sender].add(msg.value);
  }

  function withdraw() public {
    uint amount = pledges[msg.sender];
    if(amount > 0) {
      pledges[msg.sender] = 0;
      payable(msg.sender).transfer(amount);
    } 
  }

  function publish(string memory episodeLink) public onlyOwner {
    require(lastPublicationBlock == 0 || block.number > lastPublicationBlock.add(minimumPublicationPeriod), "Owner cannot publish right now.");

    lastPublicationBlock = block.number;
    episodeCounter++;
    publishedEpisodes[episodeCounter] = episodeLink;

    uint episodePay = 0;
    for(uint i = 0; i < pledgers.length; i++) {
      if(pledges[pledgers[i]] >= pledgePerEpisode) {
        pledges[pledgers[i]] = pledges[pledgers[i]].sub(pledgePerEpisode);
        episodePay = episodePay.add(pledgePerEpisode);

      }
    }
    payable(owner()).transfer(episodePay);
  }

  function close() public onlyOwner {
    for(uint i = 0; i < pledgers.length; i++) {
      uint amount = pledges[pledgers[i]];
      if(amount > 0) {
        payable(pledgers[i]).transfer(amount);
      }
    }
    selfdestruct(payable(owner()));
  }

  function totalPledgers() public view returns(uint) {
    return pledgers.length;
  }

  function activePledgers() public view returns(uint) {
    uint active = 0;
    for(uint i = 0; i < pledgers.length; i++) {
      if(pledges[pledgers[i]] >= pledgePerEpisode) {
        active++;
      }
    }
    return active;
  }

  function nextEpisodePay() public view returns(uint) {
    uint episodePay = 0;
    for(uint i = 0; i < pledgers.length; i++) {
      if(pledges[pledgers[i]] >= pledgePerEpisode) {
        episodePay = episodePay.add(pledgePerEpisode);
      }
    }
    return episodePay;
  }
}
