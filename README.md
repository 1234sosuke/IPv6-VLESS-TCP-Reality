# IPv6 VLESS+TCP+Reality 一键安装脚本

这是一个用于在支持IPv6的服务器上批量部署VLESS+TCP+Reality的一键安装脚本。该脚本会自动检测服务器上的所有IPv6地址，并为每个地址配置一个独立的VLESS+Reality节点。

## 特点

- 自动检测并使用所有可用的IPv6地址
- 为每个IPv6地址创建独立的入站和出站配置
- 自动生成Reality协议所需的密钥对
- 提供完整的V2rayN客户端导入链接
- 无需域名，使用Reality协议进行伪装

## 使用方法

### 快速安装

在Ubuntu/Debian系统上，使用以下命令一键安装：

```bash
curl -fsSL https://raw.githubusercontent.com/1234sosuke/IPv6-VLESS-TCP-Reality/main/fix_ipv6_vless.sh | bash
```

### 手动安装

1. 下载脚本：

```bash
wget https://raw.githubusercontent.com/1234sosuke/IPv6-VLESS-TCP-Reality/main/fix_ipv6_vless.sh
```

2. 添加执行权限：

```bash
chmod +x fix_ipv6_vless.sh
```

3. 使用root权限运行脚本：

```bash
sudo ./fix_ipv6_vless.sh
```

## 系统要求

- Ubuntu 18.04+ 或 Debian 10+
- 支持IPv6的VPS服务器
- 客户端网络必须支持IPv6

## 管理命令

安装完成后，可以使用以下命令管理Xray服务：

- 查看状态: `systemctl status xray`
- 重启服务: `systemctl restart xray`
- 查看日志: `journalctl -u xray -f`
- 配置文件: `/etc/xray/config.json`

## 注意事项

1. SNI域名仅用于伪装，无需拥有
2. 不需要通过Cloudflare绑定域名
3. 客户端网络必须支持IPv6
4. 可同时使用多个节点实现负载均衡

## 客户端配置

安装完成后，脚本会生成V2rayN客户端的导入链接。复制这些链接到V2rayN客户端即可使用。

## 许可证

MIT License