#!/bin/bash

# IPv6批量VLESS+TCP+Reality一键安装脚本
# 修复版 - 完整无截断

set -e  # 遇到错误立即退出

echo "========================================"
echo "IPv6 VLESS+TCP+Reality 一键部署脚本"
echo "========================================"

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 请使用root权限运行此脚本"
    echo "使用命令: sudo -i"
    exit 1
fi

# 停止已运行的服务（如果存在）
systemctl stop xray 2>/dev/null || true

echo "🔍 检测服务器IPv6地址..."

# 获取所有IPv6地址，排除本地和临时地址
IPV6_ADDRESSES=($(ip -6 addr show | grep 'inet6' | grep -v 'fe80' | grep -v '::1' | grep 'global\|deprecated' | awk '{print $2}' | cut -d'/' -f1 | head -10))

if [ ${#IPV6_ADDRESSES[@]} -eq 0 ]; then
    echo "❌ 未检测到IPv6地址！"
    echo "当前网络接口："
    ip -6 addr show
    echo ""
    echo "请确保："
    echo "1. 服务器提供商支持IPv6"
    echo "2. IPv6已正确配置"
    echo "3. 防火墙允许IPv6连接"
    exit 1
fi

echo "✅ 检测到 ${#IPV6_ADDRESSES[@]} 个IPv6地址："
for i in "${!IPV6_ADDRESSES[@]}"; do
    echo "  $((i+1)). ${IPV6_ADDRESSES[i]}"
done
echo ""

# 安装依赖
echo "📦 安装必要软件..."
apt-get update -qq
apt-get install -y unzip curl wget jq > /dev/null 2>&1

# 下载Xray
if [ ! -x "/usr/local/bin/xray" ]; then
    echo "⬇️  下载Xray核心..."
    LATEST_VERSION=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4 || echo "v1.8.4")
    wget -q "https://github.com/XTLS/Xray-core/releases/download/$LATEST_VERSION/Xray-linux-64.zip"
    unzip -q Xray-linux-64.zip
    mv xray /usr/local/bin/
    chmod +x /usr/local/bin/xray
    rm -f Xray-linux-64.zip geoip.dat geosite.dat LICENSE README.md
    echo "✅ Xray 安装完成"
else
    echo "✅ Xray 已存在"
fi

# 生成配置参数
echo "🔑 生成配置参数..."
UUID=$(cat /proc/sys/kernel/random/uuid)
START_PORT=20000
SNI="www.bing.com"
DEST="www.bing.com:443"

# 生成Reality密钥对
KEYS=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "Private key:" | cut -d' ' -f3)
PUBLIC_KEY=$(echo "$KEYS" | grep "Public key:" | cut -d' ' -f3)

echo "📝 生成配置文件..."
mkdir -p /etc/xray

# 生成完整的配置文件
cat > /etc/xray/config.json << EOL
{
    "inbounds": [
EOL

# 添加每个IPv6地址的入站配置
for i in "${!IPV6_ADDRESSES[@]}"; do
    PORT=$((START_PORT + i))
    IPV6_ADDR="${IPV6_ADDRESSES[i]}"
    
    # 添加逗号分隔符（除了第一个）
    if [ $i -gt 0 ]; then
        echo "        ," >> /etc/xray/config.json
    fi
    
    cat >> /etc/xray/config.json << EOL
        {
            "listen": "$IPV6_ADDR",
            "port": $PORT,
            "protocol": "vless",
            "tag": "inbound-$((i + 1))",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": "$DEST"
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "dest": "$DEST",
                    "serverNames": ["$SNI"],
                    "privateKey": "$PRIVATE_KEY",
                    "shortIds": ["", "0123456789abcdef"]
                }
            }
        }
EOL
done

cat >> /etc/xray/config.json << EOL
    ],
    "outbounds": [
EOL

# 添加每个IPv6地址的出站配置
for i in "${!IPV6_ADDRESSES[@]}"; do
    IPV6_ADDR="${IPV6_ADDRESSES[i]}"
    
    # 添加逗号分隔符（除了第一个）
    if [ $i -gt 0 ]; then
        echo "        ," >> /etc/xray/config.json
    fi
    
    cat >> /etc/xray/config.json << EOL
        {
            "sendThrough": "$IPV6_ADDR",
            "protocol": "freedom",
            "tag": "outbound-$((i + 1))"
        }
EOL
done

cat >> /etc/xray/config.json << EOL
    ],
    "routing": {
        "rules": [
EOL

# 添加路由规则
for i in "${!IPV6_ADDRESSES[@]}"; do
    # 添加逗号分隔符（除了第一个）
    if [ $i -gt 0 ]; then
        echo "            ," >> /etc/xray/config.json
    fi
    
    cat >> /etc/xray/config.json << EOL
            {
                "type": "field",
                "inboundTag": ["inbound-$((i + 1))"],
                "outboundTag": "outbound-$((i + 1))"
            }
EOL
done

cat >> /etc/xray/config.json << EOL
        ]
    }
}
EOL

echo "⚙️  创建系统服务..."
cat > /etc/systemd/system/xray.service << EOL
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xray -c /etc/xray/config.json
Restart=on-failure
User=root
RestartSec=3

[Install]
WantedBy=multi-user.target
EOL

# 启动服务
systemctl daemon-reload
systemctl enable xray
systemctl start xray

# 检查服务状态
sleep 3
if systemctl is-active --quiet xray; then
    echo "✅ Xray服务启动成功！"
else
    echo "❌ Xray服务启动失败！"
    echo "错误日志："
    journalctl -u xray -n 20 --no-pager
    exit 1
fi

# 输出结果
echo ""
echo "=========================================="
echo "🎉 IPv6 VLESS+TCP+Reality 部署完成！"
echo "=========================================="
echo "配置参数："
echo "UUID: $UUID"
echo "SNI域名: $SNI"
echo "公钥: $PUBLIC_KEY"
echo "shortId: 留空或使用 0123456789abcdef"
echo ""

echo "服务器列表："
echo "----------------------------------------"
for i in "${!IPV6_ADDRESSES[@]}"; do
    PORT=$((START_PORT + i))
    IPV6_ADDR="${IPV6_ADDRESSES[i]}"
    echo "服务器 $((i + 1)):"
    echo "  地址: $IPV6_ADDR"
    echo "  端口: $PORT"
    echo "  完整: [$IPV6_ADDR]:$PORT"
    echo ""
done

echo "=========================================="
echo "V2rayN 导入链接："
echo "=========================================="
for i in "${!IPV6_ADDRESSES[@]}"; do
    PORT=$((START_PORT + i))
    IPV6_ADDR="${IPV6_ADDRESSES[i]}"
    
    # 生成VLESS链接
    VLESS_URL="vless://$UUID@[$IPV6_ADDR]:$PORT?type=tcp&security=reality&pbk=$PUBLIC_KEY&fp=chrome&sni=$SNI&sid=&flow=xtls-rprx-vision#VLESS-Reality-IPv6-$((i + 1))"
    echo "$VLESS_URL"
    echo ""
done

echo "=========================================="
echo "重要说明："
echo "1. SNI域名 ($SNI) 仅用于伪装，无需拥有"
echo "2. 不需要通过Cloudflare绑定域名"
echo "3. 客户端网络必须支持IPv6"
echo "4. 可同时使用多个节点实现负载均衡"
echo ""
echo "管理命令："
echo "查看状态: systemctl status xray"
echo "重启服务: systemctl restart xray  "
echo "查看日志: journalctl -u xray -f"
echo "配置文件: /etc/xray/config.json"
echo "=========================================="

echo "🔧 测试IPv6连通性："
echo "ping6 -c 2 google.com"
ping6 -c 2 google.com 2>/dev/null && echo "✅ IPv6连通正常" || echo "⚠️  IPv6连通可能存在问题"

echo ""
echo "✅ 安装完成！请复制上面的VLESS链接到V2rayN客户端"