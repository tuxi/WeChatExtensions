# 制作微信插件

非越狱环境下iOS版WeChat 逆向研究示例，dylibz(动态库)注入、应用重签名，目的是为了熟悉iOS逆向相关知识点；

#### 基本原理
通过app启动时调用我们注入的dylib，进行app hook，最终能够执行我们注入的dylib。

#### 应用砸壳
App store里的应用都是加密的，没办法直接拿来使用，所以在做之前都需要一个砸壳的过程，而砸壳使用的工具是[dumpdecrypted](https://github.com/stefanesser/dumpdecrypted), 原理就是让app预先加载一个dumpdecrypted.dylib，然后在程序运行时，将代码动态解密，最后在内存中dump出来整个程序。当然砸壳是需要在越狱环境下进行的，所以我直接从PP助手等各种xx助手里面下载越狱应用（不是正版应用），也就是所谓的脱过壳的应用。

注意: 有好多应用是只有部分架构被解密，这时需要检查从xx助手下载的越狱应用是否已解密，还有就是Watch App以及一些扩展依然加密了，所以最好还是确认一下，否则的话，就算hook成功，签名成功，安装成功，app还是会闪退。

查看越狱应用是否已经解密的方式，以WeChat-6.5.18为例:
1.将xx助手中下载的WeChat-6.5.18.ipa包解压，会得到一个相同的名称的文件夹，然后进入该文件夹中->Payload->WeChat，右键WeChat->显示包内容，进入app包中
2.打开终端，并进入刚才解压的WeChat-6.5.18文件夹中Payload文件夹中，执行cd命令:
`cd /Users/mofeini/Desktop/weChat/WeChat-6.5.18/Payload`
3.通过终端，找到应用对应的二进制文件，查看该app包含哪些架构, 执行file命令:
`file WeChat.app/WeChat`
结果:
```
WeChat.app/WeChat: Mach-O universal binary with 2 architectures: [arm_v7: Mach-O executable arm_v7] [arm64]
WeChat.app/WeChat (for architecture armv7):    Mach-O executable arm_v7
WeChat.app/WeChat (for architecture arm64):    Mach-O 64-bit executable arm64
```
从结果中可以看到WeChat.app包含两个构架: `arm_v7` 和 `arm64`，关于架构和设备之间的关系，可以查看[iossupportmatrix](http://iossupportmatrix.com)。理论上只要把最老的架构解密即可，因为新的cpu会兼容老的架构。

4. 通过终端命令`otool` 输出app 的load commands，然后查看获取的`cryptid`这个对应的value来判断app是否被加密，1代表加密了，0代表解密，执行otool -l (注意不是1哦)命令；
`otool -l WeChat.app/WeChat | grep -B 2 crypt`
结果:
```
         cmd LC_ENCRYPTION_INFO
     cmdsize 20
    cryptoff 16384
   cryptsize 48906240
        cryptid 0
--
         cmd LC_ENCRYPTION_INFO_64
      cmdsize 24
     cryptoff 16384
    cryptsize 52396032
        cryptid 0
```
从结果中可以看到`cryptid`对应的value都是0，可以确定此app已经被解密了，第一个对应的是较老的armv7架构，后者则是arm64架构

由于微信的项目中包含多个target: 包含WeChatWatchNative和WeChatShareExtensionNew。所以我们还需要按照上面的步骤，确认以下二进制文件(其中有两个是Watch中的，一个是微信分享扩展)：
```
WeChat.app/Watch/WeChatWatchNative.app/WeChatWatchNative
WeChat.app/Watch/WeChatWatchNative.app/PlugIns/WeChatWatchNativeExtension.appex/WeChatWatchNativeExtension
WeChat.app/PlugIns/WeChatShareExtensionNew.appex/WeChatShareExtensionNew
```
结果:
WeChatWatchNative 未获取到信息
WeChatWatchNativeExtension cryptid 1
WeChatShareExtensionNew cryptid 0
注意: WeChatWatch还是加密的，会影响到下面步骤中的重签名，最简单的办法就是，对对应ipa包解压后，将里面的Watch文件夹删除，再进行重新签名

#### 应用重签名
将脱壳后的app进行重签名，我使用的是上面步骤中从pp助手下载的越狱版本的微信，如果使用加密的App重签名成功安到设备上也会闪退。
应用重签名的方法，我使用了[ios-app-signer](https://github.com/DanTheMan827/ios-app-signer)

#### 制作需要注入微信的dylib动态库
制作dylib动态库的两种方式: [iOSOpenDev](http://www.iosopendev.com) 和 [theos](https://github.com/theos/theos)
由于iOSOpenDev总是安装失败，所以这里使用theos

- 使用终端命令，安装配置theos，将其Cloning into '/opt/theos'...
安装ldid：`brew install dpkg ldid` ，在Theos开发插件中，iOS文件的签名是使用ldid工具来完成的，也就是说ldid取代了Xcode自带的Codesign；
配置$THEOS: `export THEOS=/opt/theos` 等号后面是theos文件所在路径
Theos安装：`sudo git clone --recursive https://github.com/theos/theos.git $THEOS`，因为我们的Theos一般是安装在/opt/目录下的，所以先cd到/opt目录下，然后从github上相关的地址clone下来即可；
下载好Theos后，要修改一下文件的权限：`sudo chown -R $(id -u):$(id -g) /opt/theos`
配置环境变量: 在终端执行`open ~/.bash_profile`打开此文件，在后面加入:
```
export PATH=/opt/theos/bin:$PATH
export THEOS=/opt/theos
```

#### 创建tweak
使用theos来创建工程，创建工程也是比较简单的，就是调用我们theos目录中bin下的nic.pl命令。在执行nic.pl命令后，会让你选择新建工程的模板，目前theos中内置的是12套模板。当然我们此处创建的是tweak类型的工程，所有我们选择11
- 新建工程，执行终端命令:
`nic.pl`
然后，终端会显示12套模板，并提示`Choose a Template (required): `，我们输入`11`回车
接下来会提示项目名`Project Name (required): `，输入项目名`wechatplugin`，回车
该 deb 包的名字：`Package Name [com.yourcompany.wechatplugin]:` 输入`com.ossey.WeChatPlugin`回车
作者`Author/Maintainer Name [Swae]:` 输入你的名
tweak 作用对象的 bundle identifier（比如微信为com.tencent.xin）：`[iphone/tweak] MobileSubstrate Bundle filter [com.apple.springboard]: ` 输入`com.tencent.xin`回车
tweak 安装完成后需要重启的应用名`[iphone/tweak] List of applications to terminate upon installation (space-separated, '-' for none) [SpringBoard]`,（比如微信为WeChat）

#### tweak项目中文件介绍

- 安装完成后进入cd wechatplugin/, 执行`ls -l`, 可以看到里面有四个文件:
完成后会看到四个文件(make 后将生成 .theos 、obj 文件夹).
``` Makefile          TKDemo.plist  Tweak.xm          control ```

- 对Makefile文件进行修改
Makefile : 工程用到的文件、框架、库等信息。
该文件过于简单，还需要添加一些信息。如
指定处理器架构ARCHS = armv7 arm64
指定SDK版本TARGET = iphone:latest:8.0
导入所需的framework等等。
修改后的Makefile文件：
```
ARCHS = armv7 arm64
TARGET = iphone:latest:8.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeChatPlugin
WeChatPlugin_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
    install.exec "killall -9 WeChat"

```

- WeChatPlugin.plist: 该文件中的 Bundles : 指定 bundle 为 tweak 的作用对象。也可添加多个 bundle, 指定多个为 tweak 作用对象。

- control: 该 tweak 所需的基本信息

- Tweak.xm: 主要是用来编写hook代码，它支持Logos和c/c++，可以让我们不用去写一些 runtime 方法
.x 文件支持Logos语法，.xm 文件支持Logos和C/C++语法

Logos 常用语法：
`%hook`: 指定需要hook的类，以`%end`结尾
`%orig` 在`%hook`内部使用，执行hook住方法的原代码
`%new`: 在`%hook`内部使用，给class添加新方法，与class_addMethod相同; 在Category中添加方法的区别: Category为编译时添加，class_addMethod为d动态添加
warm: 添加的方法需要在@interface中声明
`%c`：获取一个类，等同于objc_getClass、NSClassFromString










