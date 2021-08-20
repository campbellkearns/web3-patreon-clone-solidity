var Series = artifacts.require("./Series.sol")

module.exports = function(deployer){
  deployer.deploy(Series, "My First Show", web3.utils.toWei("0.005", "ether"), 14*24*60*60/15);
}