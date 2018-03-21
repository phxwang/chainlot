# chainlot


## Feature
 * 购买指定号码（5x70 + 1x25）0.01ETH/ticket
 * 每5万个block抽奖一次，按照megamillions的规则
  * 5+1 jackpot
  * 5+0 5000 ETH
  * 4+1 50 ETH
  * 4+0 2.5 ETH
  * 3+1 1 ETH
  * 3+0 0.05 ETH
  * 2+1 0.05 ETH
  * 1+1 0.02 ETH
  * 0+1 0.01 ETH
 * 抽奖号用开奖时间前一个区块的hash来计算，最后48位每8位按照70或25分别取模，并只针对前一个区块生效的所有ticket进行抽奖（随机数有一定安全隐患）
 * 10%作为历史购买者分红
 * 1%作为开发者维护费用
 * 每邀请一个用户购买一个ticket，即可获得一个ticket赠送（相同号码）
## Interface
 * buyTicket (uint16[] numbers) payable public
 * buyRandom () payable public
 * award() ownable public
## 费用分析
 ### buyTicket
 1 tickets, 300,000gas, 3gwei, 0.001ETH, $0.6
 ### buyRandom
 10 tickets, 3,000,000gas, 3gwei, 0.01ETH, $6
 ### award
 10 tickets, 1,000,000gas 3gwei, 0.003ETH, $2
 50 tickets, 2,600,000gas 3gwei, 0.008ETH, $5



## TODO
 * 购买和摇奖 done
 * ERC 721
 * 历史购买者分成10%
 * 开发者分成5%
 * 分段计算中奖和发送奖金，因为gaslimit限制

