module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  //contracts_build_directory: "./output",
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
    rinkeby: {
      host: "127.0.0.1", // Connect to geth on the specified
      port: 8545,
      from: "0xd4f1e463501a85be4222dbef9bca8a4af76e08aa", // default address to use for any transaction Truffle makes during migrations
      network_id: 4,
      gasPrice: 1000000000 // Gas limit used for deploys
    }
  }
};

//web3.personal.unlockAccount("0xd4f1e463501a85be4222dbef9bca8a4af76e08aa", "pheonix", 0)
//web3.eth.getBalance("0xd4f1e463501a85be4222dbef9bca8a4af76e08aa")