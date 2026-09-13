# Android 远程会话入口交接

更新：2026-09-13；状态：源码已准备，设备与原生构建验证待环境恢复。

- 后续首页改为常用/会话/实例，默认限量预览、折叠机器分组，支持关注/隐藏/恢复及离线清理，错误只显示汇总；共享 Dart 的 360px 页面检查通过，Android 原生仍待验证。这批改动随本文提交到 `main`，使用维护者交接 prompt 中的新完整 SHA，`799d9b2` 仅是上轮基线。
- 已核对 Android 底部导航直接使用共享 `HomePage`，关注/隐藏复用现有 SharedPreferences，无需新增 Kotlin 代码或插件。搜索键盘显示“搜索”，提交及切换首页分栏时收起；同步详情可滚动适配横屏/大字号。
- 维护者确认上次 Windows 在 `799d9b2` 上无需改码、直接测试通过；本轮新首页尚待 Windows 复测，Android 仍没有原生验证结论。

## 本轮已写好的代码

| 范围 | 行为 |
| --- | --- |
| 共享会话目录 | 冷启动查询 idle/历史主会话；搜索、最多 50 个固定入口、按账号/Gateway 缓存；会话一键深链直达 |
| 共享隧道 | 每实例独立 loopback origin，同实例会话复用；JWT 原地续认证与断线重连，写请求不重放 |
| Android 浏览器 | 继续使用 `LaunchMode.inAppWebView`；用户启用后台保活时，打开 WebUI 前再次请求启动现有前台服务 |
| 生命周期 | 从 WebView 或后台返回 Notify 时刷新会话并立即重试已断开的隧道，已有健康连接继续使用 |
| 小屏布局 | 窄屏/大字体将会话操作排在标题下方，支持换行；拖动列表收起搜索键盘 |
| 密钥与配置 | 共享 Dart 使用已有 flutter_secure_storage 按账号/Gateway 保存新密钥，支持重复查看、补录旧密钥、Bash/PowerShell 配置导出和机器名占位；360px 弹窗 widget 检查已通过 |

## 后续对齐与使用

1. 本轮改动随交接文档提交到 `main`，以 Linux Agent 交接 prompt 中完整 SHA 为对齐点；`ac2aba0` 是历史发布版本。
2. 共享 Dart 与 `packages/notify_api/lib/` 已包含功能；不要在 Android 侧另写协议或手改生成文件。
3. Gateway 已部署 `opencode-notify-gateway:20260913-catalog-query`，修复会话查询 `limit` 导致的 HTTP 400。OpenCode 所在机器仍需更新 Notify Plugin 并重启 OpenCode。
4. 有环境后参照 [client-setup.md](client-setup.md) 构建；Release APK 不使用 `--no-pub`，避免现有 Flutter registrant 问题。签名继续使用本机未入库配置。

## 待维护者设备验收

- 启动时所有会话均 idle，仍能搜索/固定/直达；重启客户端后固定记录保留。
- 小屏、横竖屏和系统大字体下按钮可触达；输入搜索词后滚动能收起键盘。
- 常用页默认限量；实例按机器折叠；关注、隐藏及恢复跨重启保留；键盘“搜索”和分栏切换均能收起键盘，同步详情可滚动。
- 新建密钥后关弹窗、重启客户端仍能查看/复制；配置包含真实密钥与填写的机器名，原生凭据存储和剪贴板待真机验证。
- 同实例不同会话复用端口；不同实例各自保持连接；返回 Notify 后能继续打开。
- WebUI 连续使用超过 15 分钟，切网后在原 origin 恢复；未确认的提示词不会重复提交。
- 电池优化豁免和现有前台服务启用时验证锁屏/后台恢复；用户关闭保活、系统强杀或移除任务后不承诺隧道持续可用。

共享 Dart 已通过 Linux 静态分析、针对性检查及 Linux Release 构建；没有本轮 Android 构建、安装或真机结论。Windows 通过后可在 Linux 构建 Release APK，但 Windows 结果不能证明 Android WebView、前台服务、凭据存储和后台恢复正确。正式发布使用统一源 SHA/版本、原有 Release 签名，并记录 Android 自身构建、签名/包内容检查和维护者设备验收状态。
