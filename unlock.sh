#!/bin/bash

# 获取目标IPv4和IPv6地址
read -p "Please input your ipv4 address: " ipv4_address
read -p "Please input your ipv6 address without prefix）: " ipv6_address_prefix

# 更新/etc/network/interfaces配置
cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

iface ens18 inet6 static
        address ${ipv6_address_prefix}::2/48
        gateway ${ipv6_address_prefix}::1
        post-up ip route add local ${ipv6_address_prefix}::/48 dev ens18
        dns-nameservers 2001:4860:4860::8888

allow-hotplug ens18
iface ens18 inet static
        address ${ipv4_address}/24
        gateway 10.10.20.1
        # dns-* options are implemented by the resolvconf package, if installed
        dns-nameservers 10.10.10.10
EOF

# 更新/etc/systemd/system/miku.service配置
cat > /etc/systemd/system/miku.service <<EOF
[Unit]
Description=Miku Network Unlock Solution
Documentation=https://mikucloud.co
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/root/s5 -i ${ipv6_address_prefix}::1/48
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

# 更新/etc/npd6.conf配置
cat > /etc/npd6.conf <<EOF
// npd6 config file

prefix=${ipv6_address_prefix}::/48

interface = ens18

ralogging = off

listtype = none

listlogging = off

collectTargets = 100

linkOption = false

ignoreLocal = true

routerNA = true

maxHops = 255

pollErrorLimit = 20
EOF

# 更新/usr/local/etc/v2ray/config.json配置
cat > /usr/local/etc/v2ray/config.json <<EOF
{
  "dns": {
    "hosts": {
        "geosite:youtube": "${ipv4_address}",
        "geosite:netflix": "${ipv4_address}",
        "geosite:disney": "${ipv4_address}",
        "geosite:openai": "${ipv4_address}"
    },
    "servers": [
     "10.10.10.10"
    ]
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 53,
      "protocol": "dokodemo-door",
      "tag": "dns-in",
      "settings": {
        "address": "10.10.10.10",
        "port": 53,
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "dns",
      "tag": "dns-out"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": "dns-in",
        "outboundTag": "dns-out"
      }
    ]
  }
}
EOF

# 执行重启
echo "All done. Now rebooting..."
sleep 5
reboot
