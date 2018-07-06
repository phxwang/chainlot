# chainlot


## DEMO
 * demo: http://rinkeby.cryptolotto6.org/demo.html
 * beta: http://www.cryptolotto6.org/beta.html

## Feature
 * 购买指定号码（5x70 + 1x25）0.01ETH/ticket
 * 奖池（参考DAO）
   * 每轮抽奖设置一个奖池，50000个block一轮
   * 抽奖号用该奖池最后一个block的hash及历史购买号码的hash综合计算，最后48位每8位按照70或25分别取模，并只针对该奖池中的所有ticket进行抽奖
   * 奖池的2%作为开发者费用，10%作为历史购买者分红，保留10%用于未来的奖池，其他用于奖券奖金
   * 分红和分奖金后剩余的积分转移到下一个最新的奖池
 * 抽奖规则按照megamillions的规则
   * 5+1 jackpot all
   * 5+0 5000 ETH
   * 4+1 50 ETH
   * 4+0 2.5 ETH
   * 3+1 1 ETH
   * 3+0 0.05 ETH
   * 2+1 0.05 ETH
   * 1+1 0.02 ETH
   * 0+1 0.01 ETH
 * 每邀请一个用户购买一个ticket，即可获得一个ticket赠送（相同号码）
 * ERC20积分(CLC)
   * 主合约将用户支付的以太坊兑换成积分
   * 奖金作为积分返还
   * 积分可以再次购买ticket
   * 可以避免transfer失败的问题
 * ERC20Token(CLT)
   * 每个奖池的10%转入CLT，用于奖池分红
   * 预留一部分给早期投资人和开发者
   * 后续每次购买Ticket都可以获得CLT，逐步递减
 * ERC721 token（CLTK)
   * 实际的ticket物品token
   * ~~作为历史提成分红的凭证~~

   
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
 * 1 tickets, 160,000 gas x 3gwei, 0.0005ETH, $0.3
 ### buyRandom
 * 1 tickets, 400,000 gas x 3gwei, 0.0012ETH, $0.5
 ### drawing
 * match: 25 tickets, 1,000,000gas
 * calculate: 10 tickets, 200,000gas
 * split: 140,000gas
 * distribute: 1,000,000gas
 * send: 100,000gas
 * transfer: 60,000gas
 * total: 125 tickets, 8,000,000 gas



## TODO
 * 建一个telegram群 P1
 * 安全性检查 P1
  * 所有的外部操作都要在状态改变之后 done
  * 输入越界检查，状态合法性检查
  * 安全计算库
  * fallback函数 done
  * 不能用tx.orgin做权限控制 done
  * 使用pool里面的number的循环hash作为salt来计算random done
  * 增加maintainer角色
 * 支持一次购买多个奖池的ticket P2
 * 把drawing tool用library实现 P2
 * 把random number的计算放到pool的合约里面 P2
 * 新增一个token，主要用于分红 P2
   * 买彩票才能获得token，返还比例随着token数量减少逐级递减。预留一部分给早期投资人和开发者
   * 奖池的10%返还到token的池子中 
   * 原有的token改成coin，只用于结算，去掉ticket的分红
 * 完善测试用例，正向反向都要测到 P2
 * 网页格式美化 P2
 * 适配移动 P2
 * 部署beta版到main net P2
  
## DONE
 * 支持逻辑升级
  * 分拆存储层和表现层，便于升级 done
  * Migrates的用法 done
 * 测试局部升级
    * 升级poolfactory
    * 升级chainlot done
    * 升级chainlotpublic done
    * 升级drawingtool done
 * 自动运维的脚本
  * 定时生成新的pool和定时开奖 done
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
