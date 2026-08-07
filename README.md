# PanPDF

PanPDF 是基于 [Stirling PDF](https://github.com/ActiveInAI/PanPDF) 2.11.0 的本地 PDF 工具箱，重新品牌为 **Pan PDF**，并默认在**未注册/未登录**状态下开放全部可用功能。

## 功能

- 未登录即可使用几乎所有工具（转换、合并、拆分、水印、签名、OCR、表单、页面编辑等）
- 品牌统一为 Pan PDF，Logo 使用 `docs/logo-mark.svg`
- 应用内 GitHub 链接指向 `https://github.com/ActiveInAI/PanPDF`
- 已禁用遥测/统计（Analytics、PostHog、Scarf）
- 已启用 Alpha 功能与 URL 转 PDF（内置 URL 安全策略，默认拦截内网地址）

## 快速开始

```bash
# 1. 从官方镜像提取 jar 并应用 Pan 品牌补丁（生成 patched/*.jar，不入库）
./scripts/rebuild_patched.sh

# 2. 启动
export PANPDF_API_KEY=your-api-key
docker compose up -d

# 3. 访问
# http://localhost:8083
```

可配置环境变量：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `PANPDF_BIND` | `0.0.0.0` | 容器监听地址 |
| `PANPDF_PORT` | `8083` | 宿主机端口 |
| `PANPDF_API_KEY` | `change-me` | 全局 API Key，请务必修改 |

## 目录结构

- `config/`：脱敏后的应用配置（`settings.yml`）
- `customFiles/static/`：前端品牌覆盖层（标题、文案、Logo、多语言）
- `scripts/apply_patches.py`：Java class 常量池重写器，用于替换后端品牌字符串
- `scripts/rebuild_patched.sh`：从官方镜像生成补丁 jar
- `packaging/`：安装包构建脚本（Windows x64 便携包、Ubuntu amd64/arm64 .deb）
- `docs/`：Logo 与品牌素材

## 安装包

构建脚本：`packaging/build-packages.sh`，产物输出到 `dist/`（不入库）：

- `PanPDF-windows-x64.zip`：Windows x64 便携包，内含 JRE、补丁应用与 `install-panpdf.ps1` 安装脚本（开始菜单快捷方式）
- `panpdf_2.11.0-1_amd64.deb`：Ubuntu/Debian x64，自动安装 systemd 服务 `panpdf`
- `panpdf_2.11.0-1_arm64.deb`：Ubuntu/Debian arm64，同上

Linux 安装后访问 `http://localhost:8083`，服务由 systemd 管理：

```bash
sudo apt install ./panpdf_2.11.0-1_amd64.deb   # 或 arm64 包
systemctl status panpdf
```

安装包内置 Temurin 21 JRE；LibreOffice/Ghostscript/qpdf/Tesseract 等高级转换与 OCR 工具通过 `.deb` 的 `Recommends` 提示安装。

## 许可与归属

- 本仓库中的覆盖层与脚本以 MIT 许可发布
- 上游 Stirling PDF 为 MIT/Open-Core 项目，品牌与代码版权归原作者所有
- 官方镜像中的 proprietary jar 不在本仓库内分发，由 `rebuild_patched.sh` 在本地从官方镜像生成

## 链接

- 主页：<https://github.com/ActiveInAI/PanPDF>
- Issues：<https://github.com/ActiveInAI/PanPDF/issues>
