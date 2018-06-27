# chainlot


## DEMO
 * http://rinkeby.cryptolotto6.org/demo.html

## Feature
 * 购买指定号码（5x70 + 1x25）0.01ETH/ticket
 * 每5万个block抽奖一次，按照megamillions的规则
  * 5+1 jackpot all
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
 * ERC721 token
 	* 实际的ticket物品token
 	* 作为历史提成分红的凭证
 * 奖池（参考DAO）
 	* 每轮抽奖设置一个奖池
 	* 奖池的2%作为开发者费用，10%作为历史购买者分红，其他用于奖券奖金
 	* 分红后剩余的积分转移到下一个奖池。
## 设计原则
 * 面向用户的接口尽量简单稳定，需要在主协议中体现
 * 管理接口可以灵活，尽量留在子协议中，便于后续扩展
## 运营流程
	* 开一堆新奖池，开奖blocknumber是N
	* 等待用户购买
	* blocknumber到达N
	* 计算N的中奖和奖金

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
 * 完善测试用例，正向反向都要测到
 * 网页格式美化
 * 适配移动
 * 支持逻辑升级
  * 分拆存储层和表现层，便于升级
  * Migrates的用法
  * 测试局部升级
    * 升级pool和poolfactory
    * 升级chainlot
 * 网页交互 
  * 购买 P1 
    * 指定 done
    * 随机 done
    * 支持随机购买多个数字 done
  * 查看总奖池及总历史奖池 P2 done
  * 用户邀请用户 P1 done
  * 查看个人token P2
  * 查看个人购买记录 P1 done
  * 查看历史购买记录 P2 done
  * 查看历史分成 P2 done
  * 提取历史分成 P2 done
  * 查看获奖记录 P2 done
 * 抽税机制重构 done
  * 在分奖池时就做分配，而不是在发奖的时候
 * 优化gas使用
  * 降低newpool的gas done
 * 完整的运营脚本
 	* 创建奖池 done
 	* 开奖 done
 	* 汇总奖池 done
 * 购买和摇奖 done
 * ERC 721 done
 * 积分机制（ERC 20） done
 * 使用积分购买ticket done
 * 分开计算中奖和发送奖金 done
 * 每次抽奖生成一个单独的合约 done
 * 合约逻辑拆分（单个合约太大创建不了了）done
 * 计算中奖和发送奖金优化
 	* 分段计算 done
 	* 容错检查 done
 	* 创建奖金池和抽奖同时进行 done
 	* 可以一次性创建多个奖金池，每次客户购买会根据当前的block自动切换 done
 * 历史购买者分成10% done
 	* 支持每个奖池分成给当前奖池及之前的所有历史ticket
 * 每次开奖后剩余积分转移到下个奖池 done
 * 开发者分成2% done
 * 邀请朋友得ticket done
 * 支持查看个人的相关收入（奖金+分红） done
 * 增加一个最简单的主协议（只用于购买）done
 * 
 

