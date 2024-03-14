#!/bin/bash

# 获取目标IPv4和IPv6地址
read -p "请输入目标内网IPv4地址: " ipv4_address
read -p "请输入目标IPv6地址（不包括/48后缀）: " ipv6_address_prefix

# 修改/etc/network/interfaces文件
sed -i "s/\(iface ens18 inet static.*address \).*/\1$ipv4_address\/24/" /etc/network/interfaces
sed -i "s/\(iface ens18 inet6 static.*address \).*/\1$ipv6_address_prefix::2\/48/" /etc/network/interfaces
sed -i "s/\(gateway \).*/\1$ipv6_address_prefix::1/" /etc/network/interfaces
sed -i "s/\(post-up ip route add local \).*/\1$ipv6_address_prefix::\/48 dev ens18/" /etc/network/interfaces

# 修改/etc/systemd/system/miku.service文件
sed -i "s/\(ExecStart=\/root\/s5 -i \).*/\1$ipv6_address_prefix::1\/48/" /etc/systemd/system/miku.service

# 修改/etc/npd6.conf文件
sed -i "s/\(prefix=\).*/\1$ipv6_address_prefix::\/48/" /etc/npd6.conf

# 修改/usr/local/etc/v2ray/config.json文件
sed -i "s/\"geosite:youtube\": \".*\"/\"geosite:youtube\": \"$ipv4_address\"/" /usr/local/etc/v2ray/config.json
sed -i "s/\"geosite:netflix\": \".*\"/\"geosite:netflix\": \"$ipv4_address\"/" /usr/local/etc/v2ray/config.json
sed -i "s/\"geosite:disney\": \".*\"/\"geosite:disney\": \"$ipv4_address\"/" /usr/local/etc/v2ray/config.json
sed -i "s/\"geosite:openai\": \".*\"/\"geosite:openai\": \"$ipv4_address\"/" /usr/local/etc/v2ray/config.json

# 执行重启
echo "所有修改已完成，系统将在5秒后重启..."
sleep 5
reboot
