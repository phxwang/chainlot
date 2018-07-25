# chainlot


## DEMO
 * demo: http://rinkeby.cryptolotto6.org/demo.html
 * beta: http://www.cryptolotto6.org/beta.html

## Feature
 * 购买指定号码（5x100）0.01ETH/ticket
 * 奖池（参考DAO）
    * 每轮抽奖设置一个奖池，50000个block一轮
    * 抽奖号用所有参与者购买号码的hash综合计算，并只针对该奖池中的所有ticket进行抽奖
    * 奖池的2%作为开发者费用，10%作为历史购买者分红，保留10%用于未来的奖池，其他用于奖券奖金
    * 分红和分奖金后剩余的积分转移到下一个最新的奖池
 * 分红规则（奖池比例+上限）
    * Hit 5 48% 无上限
    * Hit 4 5% 最高5000ETH
    * Hit 3 5% 最高50ETH
    * Hit 2 10% 最高1ETH
    * Hit 1 10% 最高0.02ETH
 * ERC20Coin(CLC)
    * 主合约将用户支付的以太坊的90%兑换成积分，1:1兑换
    * 奖金通过积分返还
    * ~~ 积分可以再次购买ticket，不需要支付10%的token兑换费 ~~
    * 可以避免transfer失败的问题
    * 积分可以兑换成以太坊，1:1兑换
 * ERC20Token(CLT)
    * 共发行10亿个token
    * 早期50%的token可以直接兑换，一个ETH兑换10万个token，供募集5000个ETH，价值250万美金
    * 普通用户每次购买Ticket的10%会被兑换为CLT，每5千万个token兑换比例提升50%
    * 购买ticket的20%的以太坊转入CLT，作为准备金
    * CLT可以兑换成以太坊，兑换比例=CLT准备金x5/CLT总流通数，每次兑换上限是准备金总量的20%
    * 支持预留份额给指定的地址
 * ~~ERC721 token（CLTK)~~
    * 实际的ticket物品token
    * ~~作为历史提成分红的凭证~~
 * 邀请分成机制：生成邀请码，邀请的人拿到10%的返点，被邀请的人打九折
 * ~~每邀请一个用户购买一个ticket，即可获得一个ticket赠送（相同号码）~~
 
   
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