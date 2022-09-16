> 因为Caibiii目前比较忙，很难一个人进行维护，商量后觉得闭源很难进行长时间的维护，所以接下来会陆陆续续将部分代码开源，希望有代码能力可以一起参与这个项目，没有代码能力的服主可以提交issues来反馈测试分支碰到的bug，测试版本稳定后会合并到主分支。
## 9月修改介绍
- ai_hunter_new 放宽了点垂直高度限制

- ai_charger_2 稍微修改了点属性，让牛连跳不那么激进，以此增加牛冲锋的概率

- ai_tank_2 修复了tank位于生还者下方可能使用纵云梯空中再次向上加速的情况，降低了tank跳砖的高度，增加了梯子检测方法，在距离tank 150单位如果能检测到梯子，tank将不会锁定视角，大大降低tank被梯子卡住的问题

- ai_hardsi_2 增加了tank低于50速的时，检测面前是否有门的情况，让克被门卡住的可能性大大降低

- text插件增加了版本控制能力，将切换模式乱七八杂的text作了整合，也方便投票某些功能时，老版本text插件可能没有，比如多人运动

- 刷特插件稍微修改，适配新版left4dhooks，并增加特感不能和玩家不能在同一个nav区域，稍微增加分散度

- AnneTankTeleport修复传送tank后tank依旧往卡住点走的问题，且增加所有人都在tank flow前时，不触发跑男的惩罚（用于克卡住生还者前推的情况）

感谢树树子对特感加强得持续更新和修bug

## 7月修改介绍

- 使用树树子tank2.0和charger 2.0更换ai_tank_new和ai_charger_new

- AI_HardSI_new 被 AI_HardSI_2.0替代，主要用来匹配tank2.0版本，而且删除里面原有的charger，smoker，jockey控制

- ~~tank传送稍微修改传送条件，获取flow失败的时候不进行检测~~

- ~~ai_smoker_new更新，解决了射线刷特导致smoker刷到半空中成为斗宗强者的问题~~

- ai_boomer_new属性小幅调整，要不打不到人了，喷人的时候花洒式

- 刷特插件也修复了smoker传送导致的斗宗smoker问题，同时倒地的人视线不会影响特感传送时间累计

- ~~10特及以上增加AnneHappyPlus武器配置~~

- 适配ai_jockey_new到7月插件(5月有问题没有加载)

- 优化刷特，降低了对服务器的压力，要不然刷特服务器帧数太难看啦（我目前不知道哪里还能优化，大佬们有空看看源码发表发表看法或者pullrequest，到目前如果云服还卡没人有解决办法的话暂时只能调服务器刷新率了）

- 增加自动更新插件，自动更新test分支的最近更新(比较大版本可能需要手动更新，小版本更新每天自动更新，其中updater.smx为更新工具，AnneUpdater为Anne插件自动更新插件，自动更新的具体插件下面有)

- 刷特再次大幅优化，而且刷特的spawnpos小幅修改，让特感生成位置更加多样，L4D2_VScriptWrapper_NavAreaBuildPath改为L4D2_NavAreaBuildPath检测由vscript脚本模式改为sdkcalls模式，检测更加严格且准确。[left4dhooks版本需要大于1.110，谢谢Silvers大佬帮忙实现了东的request，感谢他的支持和帮助]

- 由于test分支东和Caibiii都已经不再维护整个架构结构，所以以后将只会提供下面自动更新插件的源码和插件，需要你自己将test分支的插件替换掉[Caibiii维护分支](https://github.com/Caibiii/AnneServer)的对应插件或直接使用[东维护分支](https://github.com/fantasylidong/AnneZonemod)

### 自动更新的插件

            "Plugin"    "Path_SM/plugins/optional/ai_boomer_new.smx"
            "Plugin"    "Path_SM/plugins/optional/ai_charger_2.smx"
            "Plugin"    "Path_SM/plugins/optional/AI_HardSI_2.smx"
            "Plugin"    "Path_SM/plugins/optional/ai_hunter_new.smx"
            "Plugin"    "Path_SM/plugins/optional/ai_smoker_new.smx"
            "Plugin"    "Path_SM/plugins/optional/ai_spitter_new.smx"
            "Plugin"    "Path_SM/plugins/optional/ai_tank_2.smx"
            "Plugin"    "Path_SM/plugins/optional/ai_jockey_new.smx"
            "Plugin"    "Path_SM/plugins/optional/Alone.smx"
            "Plugin"    "Path_SM/plugins/optional/hunters.smx"
            "Plugin"    "Path_SM/plugins/optional/infected_control.smx"

## 修改介绍

当前测试分支在电信测试服测试过后，感觉没有很大问题，所以放到测试分支方便有兴趣的服主下载下来测试。

修改后的infected_control等插件源码在script文件夹里
特感行为插件名字更改为正确的名字，L4D2_TankThrow为AI_HardSI.smx，方便理解

目前已经用AI_HardSI_new.smx实现了L4D2_TankThrow和l4d2_asiai.smx两个插件功能，所以去掉这两个插件(暂时没删除)，增加了所有特感的加强插件。

### 新增插件介绍

#### l4d2_Anne_stuck_tank_teleport.smx(你可以删除，默认安装）

原来那个防卡tank和Anne搭配不好，借鉴infected_control和l4d_tankantistuck，写了这个版本tank防卡和跑男惩罚插件。

    ChangeLog:
    
    1.5
        修改tank传送可能被卡住的情况
    
    1.4
        救援关不启动rush传送，修改Tank流程检测.生还者进度超过98%的也不会传送（防止传送到安全门内）
    
    1.3 
        增加倒地被控玩家不进入检测
    
    1.2 
        增加tank流程检测
    
    1.1 
         修改tank传送逻辑
    
    1.0 
        版本发布

#### AI_HardSI_new.smx

在原版L4D2_TankThrow.smx基础上，增加了特感激进进攻的指令(来自 l4d2_asiai.ssp)，增加了跳砖，其余的两个插件相差不大，所以直接用这个插件替代原来那两个插件。

### 插件修改介绍

#### infected_control.smx

刷特插件稍作修改，修复了有时候会多刷一只特感的bug，并且减少了每服务器帧的刷特循环，降低服务器var值，刷特也变得更加分散，传送逻辑改变，不再是6s后没人看到就能传送，改为连续5s，每0.1s检测一次，都没被看到就能允许传送。

#### l4d_infected_movement.smx(spitter跳吐和boomer跳吐已经提供了关闭投票）

这个插件本来时tank的跳砖功能，但是跳砖已经继承到了ai_tank_new.smx插件中，就在这个插件上增加了Spitter跳吐的能力。

#### l4d_target_override

更新为最新版本，并修改了一些目标顺序。

#### Alone

单人装逼插件已经用新版刷特逻辑替代，并且继承了老版对smoker加伤，不刷boomer spitter等功能（但是刷特种类依旧是读取特感限制来刷，不过应该没影响）

#### l4d_target_override

更新到最新版本，多了一些目标可以选择，修改后的l4d_target_override.cfg在data文件内。

#### hunter

1vht插件也用新版刷特逻辑替代，并且1vht模式用了增强的hunter。

### 特感增强介绍

> 特感功能大部分都来自于[GitHub - GlowingTree880/L4D2_LittlePlugins: L4D2_LittlePlugins](https://github.com/GlowingTree880/L4D2_LittlePlugins)，感谢~~

#### Hunter

Hunter将优先选择拿机枪的玩家进行攻击，如果有墙面的时候优先选择弹墙，降低垂直高度限制(这会导致水平速度加快，你如果你用原来的，把这个从7改回原来的10)，低扑更加灵活。

#### Smoker

Smoker优先拉超前或者落单者，拉喷子效果一般。

#### Tank

Tank将连跳到选定生还者前TankAttack+50的距离停止连跳，增加检测绕树功能，被绕的情况下重新选取目标。增加了消耗克的投票。

#### Boomer

Boomer连跳速度加快，但是不会再有飞天炸了，应该算削了？update:可以空中吐，但是相比2-2应该还是算削了

#### Spitter

Spitter优先吐被控的人，其次时人密度最大的地方，且用l4d_infected_movement.smx增加了跳吐。

#### Jockey

改的不多，就在原版上增加了在必要时候锁定的功能

#### Charger

由原版的300血冲锋改为350，倒霉的人就用刀砍不死了，目标由l4d_target_overide选择。
有了这些增强，原来那个aichargerboomer插件也可以删除了

## 结语

如果由发现*Bug*希望能够提交issue，有好的想法实现了可以pull request到项目，好的想法会合并到分支里。如果发现源码的错误也希望提出并pull request，长久的维护离不开大家的努力~

## 重要提示

第一阶段测试插件基本完成，从2022年4月15日开始进行15-30天的测试时间，如果没有大bug将会合并分支到main分支。
