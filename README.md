# HLBLEManager

结合BabyBluetooth、GCDMulticastDelegate实现iOS蓝牙最方便的操作。

##### 支持使用CocoaPods引入, Podfile文件中添加:

```objc
pod 'HLBLEManager', '0.1.1'
```

# # 使用

#### 1.配置Info.plist文件

```
Privacy - Bluetooth Peripheral Usage Description
Privacy - Bluetooth Always Usage Description
```

#### 2.项目配置

`项目` -  `TARGETS` - `Signing & Capabilities` - `Background Modes`  -  勾选`Uses Bluetooth LE accessories`

#### 3.引入头文件

```objc
#import <HLBLEManager.h>
```

# Requirements

iOS 9.0 +, Xcode 7.0 +

# Dependency

- "BabyBluetooth"
- "GCDMulticastDelegate"

# Version

* 0.1.1 :
  
  添加支持ancs协议设备“自动连接”功能

* 0.1.0 :
  
  完成HLBLEManager基础搭建

# License

HLTool is available under the MIT license. See the LICENSE file for more info.
