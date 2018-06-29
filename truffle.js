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
      gasPrice: 2000000000 // Gas limit used for deploys
    },
    main: {
      host: "127.0.0.1", // Connect to geth on the specified
      port: 9545,
      from: "0xd3db3028e92d98ce48e5e21256696d2e5ae04d9e", // default address to use for any transaction Truffle makes during migrations
      network_id: 0,
      gasPrice: 1000000000 // Gas limit used for deploys
    }
  }
};