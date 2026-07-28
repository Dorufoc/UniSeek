# uniseek_app

`uniseek_app` 是 RK2206 LiteOS-M 的温湿度遥测组件。它独占板载 SHT30、LCD 和 RGB LED，启动后自动连接预配置 Wi-Fi，每 10 秒采集一次温湿度并通过 HTTP POST 上报。

## 配置

烧录前在 `include/uniseek_config.h` 设置 `UNISEEK_WIFI_SSID`、`UNISEEK_WIFI_PASSWORD`、`UNISEEK_SERVER_IP`、`UNISEEK_SERVER_PORT` 与 `UNISEEK_API_PATH`。示例使用 HTTP 明文 IPv4 服务；不要将真实密码输出到日志或提交到仓库。

默认请求为：

```http
POST /api/v1/telemetry HTTP/1.1
Content-Type: application/json

{"temperature":25.00,"humidity":50.00}
```

任意 HTTP 2xx 响应表示发送成功。

## 状态

- LCD 显示 Wi-Fi 状态和 IP、最新温度湿度、服务器结果、HTTP 状态码、重试次数及错误码。
- RGB 红色表示 Wi-Fi 未连接，黄色表示已连接 Wi-Fi 但传感器或服务器状态异常，绿色表示最近一次上报获得 2xx。
- Wi-Fi 每 5 秒检测并重连；发送失败时最多重试 3 次，每次间隔 2 秒。

## 构建与验证

`samples/BUILD.gn` 已将默认 feature 切换到 `uniseek_app`。使用项目既有 RK2206 固件构建、烧录流程即可。验证时分别测试可用服务、不可用服务、错误 Wi-Fi 凭据和断开 SHT30 的场景，确认 LCD、RGB 和串口日志状态一致。
