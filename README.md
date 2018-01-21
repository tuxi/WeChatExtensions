# 非越狱theos的Tweak创建的dylib安装到iOS设备

非越狱环境下iOS版WeChat 逆向研究示例，dylibz(动态库)注入、应用重签名

tweak的实质就是ios平台的动态库，iOS平台上有两种形势的动态库，dylib与framework。Framework这种开发者用的比较多，而dylib这种就相对比较少一点，比如libsqlite.dylib，libz.dylib等。而tweak用的正是dylib这种形势的动态库。越狱设备可以在/Library/MobileSubstrate/DynamicLibraries目录下查看iPhone上存在着的所有tweak。这个目录下除dylib外还存在着plist与bundle两种格式的文件，plist文件是用来标识该tweak的作用范围，而bundle是tweak所用到的资源文件



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

#### 制作需要注入微信的dylib动态库
制作dylib动态库的两种方式: [iOSOpenDev](http://www.iosopendev.com) 和 [theos](https://github.com/theos/theos)
由于iOSOpenDev总是安装失败，所以这里使用theos

- 使用终端命令，安装配置theos，过程其实就是将其Cloning into '/opt/theos'(这个目录可以自定义，但建议使用/opt/theos)...
1.安装ldid：`brew install dpkg ldid` ，在Theos开发插件中，iOS文件的签名是使用ldid工具来完成的，也就是说ldid取代了Xcode自带的Codesign；当出现`Updating Homebrew...`耐心等待即可；
2.配置$THEOS:  `export THEOS=/opt/theos` 等号后面是theos文件所在路径
3.Theos安装： `sudo git clone --recursive https://github.com/theos/theos.git /opt/theos`，Theos安装在/opt/目录下的，Cloning完成后，可cd到/opt目录下查看；
4.Cloning完成Theos后，要修改一下文件的权限：`sudo chown -R $(id -u):$(id -g) /opt/theos`
5.配置环境变量: 在终端执行`open ~/.bash_profile`打开此文件，在后面加入:
```
export PATH=/opt/theos/bin:$PATH
export THEOS=/opt/theos
```

出现的问题: 当执行`brew install dpkg ldid`提示
```
/usr/local/Homebrew/Library/Homebrew/brew.rb:12:in `<main>': Homebrew must be run under Ruby 2.3! (RuntimeError)
````
解决：重新执行`brew install dpkg ldid`

这里有个注意点，要在终端执行

```
source ~/.bash_profile
```
这样环境变量才会立即生效，不然输入
```
nic.pl
```
会提示
```
-bash: nic.pl: command not found
```

#### 创建tweak
使用theos来创建工程，创建工程也是比较简单的，就是调用我们theos目录中bin下的nic.pl命令。在执行nic.pl命令后，会让你选择新建工程的模板，目前theos中内置的是12套模板。当然我们此处创建的是tweak类型的工程，所有我们选择11
1. 新建工程，执行终端命令 `nic.pl`
然后，终端会显示12套模板，并提示`Choose a Template (required): `，我们输入`11`回车
2. 提示项目名`Project Name (required): `，输入项目名`wechatplugin`，回车
3. 该 deb 包的名字：`Package Name [com.yourcompany.wechatplugin]:` 输入`com.alpface.WeChatPlugin`回车
4. 作者`Author/Maintainer Name [Swae]:` 输入你的名
5. tweak 作用对象的 bundle identifier（比如微信为com.tencent.xin）：`[iphone/tweak] MobileSubstrate Bundle filter [com.apple.springboard]: ` 输入`com.tencent.xin`回车
6. tweak 安装完成后需要重启的应用名`[iphone/tweak] List of applications to terminate upon installation (space-separated, '-' for none) [SpringBoard]`,（比如微信为WeChat）

#### tweak项目中文件介绍

- 安装完成后进入cd wechatplugin/, 执行`ls -l`, 可以看到里面有四个文件:
完成后会看到四个文件(make 后将生成 .theos 、obj 文件夹).
``` Makefile          WeChatPlugin.plist  Tweak.xm          control ```

Tweak.xm: “xm”中的“x”代表这个文件支持Logos语法，如果后缀名是单独一个“x”，说明源文件支持Logos和C语法；如果后缀名是“xm”，说明源文件支持Logos和C/C++语法“xm”中的“x”代表这个文件支持Logos语法，如果后缀名是单独一个“x”，说明源文件支持Logos和C语法；如果后缀名是“xm”，说明源文件支持Logos和C/C++语法

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


#### 定制Tweak.xm
- 以微信中的设置页面为例: `NewSettingViewController`是微信的设置页面，我们hook它的`viewDidAppear:`方法
```
%hook NewSettingViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [self helloWorld];
}

%new
- (void)helloWorld {
    UIAlertController *alc = [UIAlertController alertControllerWithTitle:@"hello world" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alc addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:NULL]];
    [alc addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:NULL]];
    [self presentViewController:alc animated:YES completion:NULL];
}

%end
```
- 编写代码完成后，使用`make package`命令对其进行编译，注意:执行命令前先cd到项目文件夹 （使用`make package messages=yes`查看详情信息）
如果是在之前编写的基础上行修改，则需要重新编译, 需要先使用`make clean`，清理make, make package生成的文件
执行完成后，会在项目多两个文件夹:`.theos`和`obj`，那么在`.theos`->`obj`->`debug`中有一个`WeChatPlugin.dylib`就是我们生成的dylib动态库;

#### 修改生成的.dylib动态库中的依赖
- 通过 otool -L命令查看生成的.dylib文件
结果中的一段`/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate (offset 24)`
可以看到这里还有对CydiaSubstrate的依赖，这是不行的 , 这个是theos在越狱机上特有的, 在非越狱机上需要更改此依赖
- 修改依赖，将libsubstrate.dylib文件(该文件应该在/opt/thoes/lib/目录下),拷贝到与你生成的的.dylib一个目录下,通过下面的指令修改依赖,
```cd /Users/mofeini/Desktop/weChat/Project/wechatplugin/.theos/obj/debug
```
```
install_name_tool -change /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate @loader_path/libsubstrate.dylib WeChatPlugin.dylib
```
然后重新查看`otool -L WeChatPlugin.dylib`：
会发现依赖已经修改成`@loader_path/libsubstrate.dylib (offset 24)`

#### 重新签名自制的.dylib 和libsubstrate.dylib(很重要)
我们需要把生成的dylib和libsubstrate.dylib文件copy到WeChat.app中,然后用codesign开始签名
```
codesign -f -s 'iPhone Developer: Xiaoyuan Yang (29H47J82NP)' libsubstrate.dylib
codesign -f -s 'iPhone Developer: Xiaoyuan Yang (29H47J82NP)' ioswechat.dylib
```

#### 添加可执行文件的依赖动态注入
此处用到是[insert_dylib](https://github.com/Tyilo/insert_dylib)，先从gitHUb下载insert_dylib，编译后将 insert_dylib 放到`/usr/local/bin`目录中（不放到此目录中需要使用`./insert_dylib`，放在目录中后只需要使用`insert_dylib`）；
再将自制的dylib和libsubstrate.dylib拷贝到WeChat.app包中，执行以下命令:
```
cd /Users/mofeini/Desktop/weChat/WeChat-6.5.18/Payload/WeChat.app/
```
```
insert_dylib @executable_path/WeChatPlugin.dylib WeChat
```
以下为执行步骤
```
localhost:debug apple$ insert_dylib @executable_path/wechatplugin.dylib /Users/mofeini/Desktop/weChat/WeChat.app/WeChat
Binary is a fat binary with 2 archs.
LC_CODE_SIGNATURE load command found. Remove it? [y/n] n
LC_CODE_SIGNATURE load command found. Remove it? [y/n] n
Added LC_LOAD_DYLIB to all archs in /Users/mofeini/Desktop/weChat/WeChat.app/WeChat_patched
```
会生成一个WeChat_patched 这个就是修改了依赖关系的二进制文件，
#### 注意替换
注意: 别忘了之前将 自制的.dylib libsubstrate.dylib 拷贝进WeChat.app
如果WeChat_patched在WeChat.app中，还要将WeChat_patched拷贝进WeChat.app中 替换原来的WeChat, 把WeChat_patched的名字改回来WeChat

#### 应用重签名
将脱壳后的app进行重签名，我使用的是上面步骤中从pp助手下载的越狱版本的微信，如果使用加密的App重签名成功安到设备上也会闪退。
应用重签名的方法，我使用了[ios-app-signer](https://github.com/DanTheMan827/ios-app-signer)


#### 在Xcode上使用LLDB动态调试第三方app
前提需要调试的app必须是脱壳(即解密的), 这里以WeChat为例进行动态调试:
- 1.新建一个跟需要调试的app相同名称的项目，这里是WeChat
- 2.使用真机Command+b编译此项目，先编译的目的是为了生成一个文件，接下来有用的
- 3.在WeChat的target中的Build Phases里添加Run Script，
```
cp -rf /Users/mofeini/Desktop/Theos/weChat/success/Payload/WeChat.app /Users/mofeini/Library/Developer/Xcode/DerivedData/WeChat-grnvgkuvppvufhblzbxrfsegqzhb/Build/Products/Debug-iphoneos
```
> 注: cp -rf 后面的第一个路径是已经砸壳的WeChat.app包路径，第二个是第二步使用真机编译后生成的.app包所在的文件夹
> 此脚本的作用：
该脚本将我们砸壳的.app包跟我们创建的项目编译后的.app包替换，
他首先将第三方app拷贝替换我们新建工程生成的app，然后对第三方app使用我们的证书进行签名，最后将签名后的第三方app安装至物理机器上，就像是是在运行我们自己编写的app。
- 4.添加完脚本后，先clean整个工程，然后Run，可以在非越狱机器上

![2017-10-14 下午10.20.53.png](https://github.com/alpface/WeChatExtensions/blob/master/WeChat/屏幕快照%202017-10-14%20下午10.20.53.png)

- 错误解决:
问题1.``` Can't install application
xxx.app cannot be installed on iPhone. xxx.app does not contain a valid Info.plist
“CFBundleExecutable” specifies a file that is not executable```
解决方法: 这问题应该是执行权限不够，先进入.app包中`cd /Users/mofeini/Desktop/Theos/PinanJinGuanJia/PALifeApp/Payload/WeChat.app`，然后执行`chmod +x WeChat`，执行完成后clean下项目，再运行解决

问题2:
运行app时报错:```dyld: Library not loaded: @rpath/libswiftCore.dylib Referenced from: /var/co```, 如图
![屏幕快照 2017-10-15 上午12.17.25](https://github.com/alpface/WeChatExtensions/blob/master/WeChat/屏幕快照%202017-10-15%20上午12.17.25.png)
解决方法：使用ios-app-signer对第三方app进行重新签名生成新的ipa包，然解压ipa，将Run Script中的app路径改成新生成的，然后clean后运行即可

### 以下是一些错误解决
使用以下命令编译时候
```
make package
```
第一次会报以下错误
```
> Making stage for tweak ioswechat…
dpkg-deb: error: obsolete compression type 'lzma'; use xz instead

Type dpkg-deb --help for help about manipulating *.deb files;
Type dpkg --help for help about installing and deinstalling packages.
make: *** [internal-package] Error 2
```
查找了一些资料后发现，这个错误是dpkg引起的，随着版本的升级，打包格式发生了变化
```
dpkg-deb: error: obsolete compression type 'lzma'; use xz instead
```
解决方案是按以下路径找到该文件修改其内容
```
/opt/theos/makefiles/package/deb.mk
```
找到第六行
```
_THEOS_PLATFORM_DPKG_DEB_COMPRESSION ?= lzma
```
将其改为
```
_THEOS_PLATFORM_DPKG_DEB_COMPRESSION ?= xz
```

问题3:
2017年10月22日使用WeChat 6.5.19做实验，签名后安装，只要到进入app时就闪退了，问题如下:
```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Use of the class <INPreferences: 0x1744399a0> from an app requires the entitlement com.apple.developer.siri. Did you enable the Siri capability in your Xcode project?'
```
进入`WeChat.app/Pluglns`中，发现比WeChat 6.5.18多了两个文件:`WeChatSiriExtension`和`WeChatSiriExtensionUI`，
通过终端命令`otool` 输出这两个包内可执行文件 的load commands，发现`cryptid`这个对应的value都是1也就是加密状态，以下为执行为的命令，要先进入包内:
`otool -l WeChatSiriExtensionUI | grep -B 2 crypt`
`otool -l WeChatSiriExtension | grep -B 2 crypt`
由于手上没有越狱设备，无法测试能否砸壳，所以暂时将这两个包从Pluglns目录中删掉，重新签名运行后还是报这个错，暂时放弃此版本

问题4: 缺少`IO-Compress-Lzma`导致的一系列问题

##### 为什么安装`IO-Compress-Lzma`
由于换了新电脑，导致有些开发环境需要重新配置，今天在安装配置Theos后遇到一件非常恶心的事情：
使用`nic.pl`创建一个Theos项目后，运行`make package`时，总是报错，错误信息如下:
```
swaedeMBP:videotweak swae$ make package
> Making all for tweak VideoTweak…
==> Preprocessing Tweak.xm…
==> Compiling Tweak.xm (armv7)…
==> Linking tweak VideoTweak (armv7)…
==> Preprocessing Tweak.xm…
==> Compiling Tweak.xm (arm64)…
==> Linking tweak VideoTweak (arm64)…
==> Merging tweak VideoTweak…
==> Signing VideoTweak…
> Making stage for tweak VideoTweak…
Can't locate IO/Compress/Lzma.pm in @INC (you may need to install the IO::Compress::Lzma module) (@INC contains: /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/darwin-thread-multi-2level /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1 /usr/local/Cellar/perl/5.26.1/lib/perl5/5.26.1/darwin-thread-multi-2level /usr/local/Cellar/perl/5.26.1/lib/perl5/5.26.1 /usr/local/lib/perl5/site_perl/5.26.1/darwin-thread-multi-2level /usr/local/lib/perl5/site_perl/5.26.1) at /opt/theos/bin/dm.pl line 12.
BEGIN failed--compilation aborted at /opt/theos/bin/dm.pl line 12.
make: *** [internal-package] Error 2
```
- 实际上我在第一次使用`Theos `时也遇到过lzma的这种错误，第一次遇到错误如下:

```
> Making stage for tweak ioswechat…
dpkg-deb: error: obsolete compression type 'lzma'; use xz instead
Type dpkg-deb --help for help about manipulating *.deb files;
Type dpkg --help for help about installing and deinstalling packages.
make: *** [internal-package] Error 2

```
那一次我查找了一些资料后发现，这个错误是dpkg引起的，随着版本的升级，打包格式发生了变化
```
dpkg-deb: error: obsolete compression type 'lzma'; use xz instead
```
解决方案是按以下路径找到该文件修改其内容
```
/opt/theos/makefiles/package/deb.mk
```
找到第六行
```
_THEOS_PLATFORM_DPKG_DEB_COMPRESSION ?= lzma
```
将其改为
```
_THEOS_PLATFORM_DPKG_DEB_COMPRESSION ?= xz
```

-  解决过程：
我安装上面的解决方法却依旧无法解决，而且我在Google和stackoverflow上也寻找不到答案；
仔细查看问题`Can't locate IO/Compress/Lzma.pm in @INC (you may need to install the IO::Compress::Lzma module)`，其实就是缺少`IO::Compress::Lzma`，经过1个小时时间安装完成后，解决了我的问题;

##### 安装`IO::Compress::Lzma`
- 1.进入[cpn](http://search.cpan.org/dist/IO-Compress-Lzma/lib/IO/Compress/Xz.pm)下载[[IO-Compress-Lzma-2.074.tar.gz](http://search.cpan.org/CPAN/authors/id/P/PM/PMQS/IO-Compress-Lzma-2.074.tar.gz)
](http://www.cpan.org/authors/id/P/PM/PMQS/IO-Compress-Lzma-2.074.tar.gz)
- 2.mac上双击解压，或者终端执行`tar zxvf IO-Compress-Lzma-2.074.tar.gz`
- 3.`cd IO-Compress-Lzma-2.074`
- 4. 根据`README`安装依赖，文章下面记录的有安装依赖的包，这里就算已经安装过了：
```
* Perl 5.006 or better.
* Compress::Raw::Lzma
* IO::Compress
```
- 5.编译`IO::Compress::Lzma`, 依次执行下面:
```
perl Makefile.PL
make
make test
```
- 6.安装
```
make install
```
安装完成:
```
swaedeMBP:IO-Compress-Lzma-2.074 swae$ make install
Manifying 4 pod documents
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/.DS_Store
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/auto/.DS_Store
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/auto/IO/.DS_Store
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/IO/.DS_Store
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/IO/Compress/.DS_Store
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/IO/Compress/Lzma.pm
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/IO/Compress/Xz.pm
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/IO/Compress/Adapter/Lzma.pm
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/IO/Compress/Adapter/Xz.pm
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/IO/Uncompress/UnLzma.pm
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/IO/Uncompress/UnXz.pm
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/IO/Uncompress/Adapter/UnLzma.pm
Installing /usr/local/Cellar/perl/5.26.1/lib/perl5/site_perl/5.26.1/IO/Uncompress/Adapter/UnXz.pm
ifeq ($(_THEOS_PACKAGE_FORMAT_LOADED),)
Installing /usr/local/Cellar/perl/5.26.1/share/man/man3/IO::Compress::Lzma.3
ifeq ($(_THEOS_PACKAGE_FORMAT_LOADED),)
Installing /usr/local/Cellar/perl/5.26.1/share/man/man3/IO::Compress::Xz.3
Installing /usr/local/Cellar/perl/5.26.1/share/man/man3/IO::Uncompress::UnLzma.3
Installing /usr/local/Cellar/perl/5.26.1/share/man/man3/IO::Uncompress::UnXz.3
Appending installation info to /usr/local/Cellar/perl/5.26.1/lib/perl5/5.26.1/darwin-thread-multi-2level/perllocal.pod
```

##### 重新编译Theos项目
```
make clean
make package
```
最后我又遇见一个`make package`发生的问题:
```
swaedeMBP:videotweak swae$ make package
> Making all for tweak VideoTweak…
==> Preprocessing Tweak.xm…
==> Compiling Tweak.xm (armv7)…
==> Linking tweak VideoTweak (armv7)…
==> Preprocessing Tweak.xm…
==> Compiling Tweak.xm (arm64)…
==> Linking tweak VideoTweak (arm64)…
==> Merging tweak VideoTweak…
==> Signing VideoTweak…
> Making stage for tweak VideoTweak…
ERROR: package name has characters that aren't lowercase alphanums or '-+.'.
make: *** [internal-package] Error 255
```
解决方法:
参考http://bbs.iosre.com/t/theos/2049/15中某位同学的评论，这里直接粘贴:
```
[@snakeninny](http://bbs.iosre.com/u/snakeninny) 谢谢你告诉我使用 `make messages=yes`，看日志得知问题是因为大写问题, 我在运行 `make package install`时遇到上面基本一样的错误，
但是通过打印运行log信息来看，`make package install messages=yes`，遇到错误是：包名的字符不是小写。如下所示，而且当前项目的包名是：com.victor.iOSScreenShotTest
随即，我删掉，重新创建一个项目，包名是: com.victor.iosscreenshottest
`ERROR: package name has characters that aren't lowercase alphanums or '-+.'. make: *** [internal-package] Error 255` `

然后就运行正常了，再次感谢~~ ![:smile:](http://upload-images.jianshu.io/upload_images/2135374-04728acf9a5a4521.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240 ":smile:")

```

##### 安装`IO::Compress::Lzma`的依赖包
```
Before you can build IO-Compress-Lzma you need to have the following
installed on your system:

* Perl 5.006 or better.
* Compress::Raw::Lzma
* IO::Compress
```
- 安装`Perl ` 执行下面即可
```curl -L http://xrl.us/installperlosx | bash```
-  安装  `Compress::Raw::Lzma`
`使用cpanm`安装 , 执行：
```cpanm Compress::Raw::Lzma```
进入[cpan](http://search.cpan.org/~pmqs/Compress-Raw-Lzma-2.074/lib/Compress/Raw/Lzma.pm)下载[Compress-Raw-Lzma-2.074.tar.gz](http://search.cpan.org/CPAN/authors/id/P/PM/PMQS/Compress-Raw-Lzma-2.074.tar.gz)；
下载完成后, 依次执行下面：
```
tar zxvf Compress-Raw-Lzma-2.074.tar.gz
cd Compress-Raw-Lzma-2.074
perl Makefile.PL
make
make test
make install
```
此处参考http://blog.csdn.net/tty521/article/details/54301705
- 安装`IO::Compress`
实际上我就没有主动安装他，不过没有安装他也没问题，所以就没有安装


#### Tweak 调试项目
1.在tweak项目的makefile顶部添加DEBUG=1来开启debug，设置为0或者删除关闭debug。
也可以在make的时候带入参数：`make package install DEBUG=1`




