## TODO
 * 建一个telegram群 P2
 * 支持一次购买多个奖池的ticket P2
 * 把random number的计算放到pool的合约里面 P2
 * 完善测试用例，正向反向都要测到 P2
 * 网页格式美化 P2
 * 适配移动 P2
   * 适配opera等dapp浏览器
 * 部署beta版到main net P2
 * 降低购买ticket的gas消耗 P2
 * 屏蔽中国ip地址段 P2
 * CLT设置HardCap，一段时间没达到就可以打开开关原价提走  P2
 * 给所有require和assert加上返回值 P2
 * 把抽奖算法封装成独立contract，源代码公开 P2
 * 禁止单笔高额参与，一次最多买100个ticket P2
 

## DOING
 * 支持预留私募份额 P1
 * dev cut可以分成多个人 P1
 * 把历史中奖列表展示出来 P1

## DONE
 * 增加邀请分成，生成邀请码，邀请的人拿到10%的返点，被邀请的人打九折 P1
   * 去掉邀请送券的机制
 * 分红按照匹配数的权重进行分配，并设定上限 P1
   * 计算一个新的数字组合，和megamillion不一样。小奖要多，但金额小
 * 所有的coin也调整为游戏 P1
 * 整个文案调整为数字竞猜游戏 P1 
 * 增强安全性，进行多重hash P1
 * 分析lomo3d，加入可以借鉴的点 P1
 * 使用安全工具扫描代码 P1 done
 * 使用安全的ERC20模板 done
 * 安全性 done
   * 输入越界检查，状态合法性检查
   * 安全计算库
   * 增加maintainer角色
 * 增加token的锁定 done
   * 每挖出一个非锁定的token，才释放等比例的锁定token
 * 考虑token挤兑的问题 done
   * 限制每笔提取的额度，逐步降低价格
 * 新增一个token，主要用于分红 P1
   * 设计衰减的兑换机制 done
   * 在页面上展示token的汇率 done
 * 安全性检查 P1
   * 所有的外部操作都要在状态改变之后 done
   * fallback函数 done
   * 不能用tx.orgin做权限控制 done
   * 使用pool里面的number的循环hash作为salt来计算random done
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