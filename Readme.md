> 因为Caibiii目前比较忙，很难一个人进行维护，商量后觉得闭源很难进行长时间的维护，所以接下来会陆陆续续将部分代码开源，希望有代码能力可以一起参与这个项目，没有代码能力的服主可以提交issues来反馈测试分支碰到的bug，测试版本稳定后会合并到主分支。

## 修改介绍

当前测试分支在电信测试服测试过后，感觉没有很大问题，所以放到测试分支方便有兴趣的服主下载下来测试。

修改后的infected_control等插件源码在script文件夹里
特感行为插件名字更改为正确的名字，L4D2_TankThrow为AI_HardSI.smx，方便理解

目前已经用AI_HardSI_new.smx实现了L4D2_TankThrow和l4d2_asiai.smx两个插件功能，所以去掉这两个插件(暂时没删除)，增加了所有特感的加强插件。

### 新增插件介绍

#### l4d_TankStuckTeleport.smx

顾名思义，这个插件就是用来检测tank有没有被卡住的插件，当被卡住时，传送到生还者路程前200-300单位的距离，当有求生跑男时，tank也会触发传送惩罚。

#### AI_HardSI_new.smx

在原版L4D2_TankThrow.smx基础上，增加了特感激进进攻的指令(来自 l4d2_asiai.ssp)，增加了跳砖，其余的两个插件相差不大，所以直接用这个插件替代原来那两个插件。

### 插件修改介绍

#### infected_control.smx

刷特插件稍作修改，修复了有时候会多刷一只特感的bug，并且减少了每服务器帧的刷特循环，降低服务器var值，刷特也变得更加分散，传送逻辑改变，不再是6s后没人看到就能传送，改为连续3s，每0.1s检测一次，都没被看到就能允许传送。

#### l4d_infected_movement.smx

这个插件本来时tank得跳砖功能，但是跳砖已经继承到了AI_HardSI_new.smx插件中，就在这个插件上增加了Spitter跳吐的能力。

### l4d_target_override

更新为最新版本，并修改了一些目标顺序。

### 特感增强介绍

> 特感功能大部分都来自于[GitHub - GlowingTree880/L4D2_LittlePlugins: L4D2_LittlePlugins](https://github.com/GlowingTree880/L4D2_LittlePlugins)，感谢~~

#### Hunter

Hunter将优先选择拿机枪的玩家进行攻击，如果有墙面的时候优先选择弹墙，降低垂直高度限制，低扑更加灵活。

#### Smoker

Smoker优先拉超前或者落单者，拉喷子效果一般。

#### Tank

Tank将连跳到选定生还者前TankAttack+50的距离停止连跳，增加检测绕树功能，被绕的情况下重新选取目标。

#### Boomer

Boomer连跳速度加快，但是不会再有飞天炸了，应该算削了？

#### Spitter

Spitter优先吐被控的人，其次时人密度最大的地方，且用l4d_infected_movement.smx增加了跳吐。

#### Jockey

改的不多，就在原版上增加了在必要时候锁定的功能

#### Charger

由原版的300血冲锋改为350，倒霉的人就用刀砍不死了，目标由l4d_target_overide选择。

有了这些增强，那个原来chargerboomer增强也可以删除了
