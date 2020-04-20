# luci-app-scutclient
* 将https://github.com/scutclient/scutclient/blob/master/openwrt/Makefile 放到 package/scutclient
* 解压放到feeds/luci/applications
* 再执行./scripts/feeds install -a -p luci
* 然后make menuconfig
* 就可以在Luci的Applications看到编译选项
