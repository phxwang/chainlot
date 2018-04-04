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
 * ERC20积分
 	* 主合约将用户支付的以太坊兑换成积分
 	* 奖金作为积分返还
 	* 积分可以再次购买ticket
## Interface
 * buyTicket (uint16[] numbers) payable public
 * buyRandom () payable public
 * award() onlyOwner public
## 费用分析
 ### buyTicket
 * 1 tickets, 160,000gas x 3gwei, 0.0005ETH, $0.3
 ### buyRandom
 * 1 tickets, 160,000gas x 3gwei, 0.0005ETH, $0.3
 ### award
 * match: 10 tickets, 350,000gas x 3gwei, 0.001ETH, $0.6
 * calculate: 10 tickets, 200,000gas x 3gwei, 0.0006ETH, $0.36
 * send: 10 tickets, 120,000gas x 3gwei, 0.0004ETH, $0.24



## TODO
 * 购买和摇奖 done
 * ERC 721 done
 * 积分机制（ERC 20） done
 * 使用积分购买ticket done
 * 分开计算中奖和发送奖金 done
 * 计算中奖和发送奖金分段，以便扩展
 	* 分段计算
 	* 容错机制
 * 历史购买者分成10% done
 * 开发者分成5% done
 * 邀请朋友得ticket done
 * 支持逻辑升级

