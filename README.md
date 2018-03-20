# chainlot


## 功能
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
 * 10%作为系统维护费用
 * 每邀请多一个用户购买一个ticket，即可获得一个ticket赠送（相同号码）
## 接口设计
 * buyTicket (uint16[] numbers) payable public
 * award() ownable public


## TODO
 * 购买和摇奖
 * ERC 721
 * 历史购买者分成10%
 * 开发者分成1%

