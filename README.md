# Kate 字体路由插件

一个面向 Windows Kate/KTextEditor 的小型插件，分别路由代码、中文和 Emoji 字体。

这个插件为 Kate/KTextEditor 设置下面的字体规则：

| 内容 | 字体 |
|---|---|
| 英文、代码及主字体已有的字符 | `GeistMono Nerd Font Mono`（仍在 Kate 外观设置中选择） |
| 汉字（Han script，且主字体缺字时） | `Maple Mono CN` |
| Emoji presentation 与 Emoji 序列 | `Noto Color Emoji` |

插件不修改 Kate 的配置文件，也不替换主字体。它只在加载时调用 Qt 6.9 的应用级字体回退接口。

> 当前交付的是已检查的源码包，不含预编译 DLL。原因是本机 Kate 安装只有运行库，没有与 Kate 26.08.1 / Qt 6.11.1 / KDE Frameworks 6.29.0 匹配的开发包。请先按下文用 KDE Craft 构建；不要拿其他 Qt/KF6 版本随意编译的 DLL 混用。

## 前提

- Kate 使用 Qt 6.9 或更新版本。
- 三个字体已经安装，并且 Kate 能在字体列表中看到它们。
- Windows 上建议使用 Kate 默认的 DirectWrite 后端；不要用 `fontengine=gdi`、`nodirectwrite` 或 `nocolorfonts` 启动参数。
- 编译插件需要与目标 Kate 匹配的 Qt、KDE Frameworks、编译器和架构。官方 Windows Kate 使用 KDE Craft 构建，因此最稳妥的方式也是在匹配的 Craft 环境中构建此插件。

本机已检测到的目标环境为：

```text
Kate:           26.08.1
Qt:             6.11.1
KDE Frameworks: 6.29.0
架构/工具链:     x64 / MSVC 2022
Kate:           C:\Program Files\Kate\bin\kate.exe
```

## 构建

首次使用 KDE Craft 时，先按 KDE 官方 Windows Craft 文档安装 Craft 和 Visual Studio 2022 的“使用 C++ 的桌面开发”工作负载。

打开 `CraftRoot` 终端，安装构建依赖：

```powershell
craft kde/frameworks/extra-cmake-modules
craft kde/frameworks/tier1/kcoreaddons
craft kde/frameworks/tier3/ktexteditor
```

进入本项目目录并运行：

```powershell
pwsh -File .\build.ps1
```

完成后，脚本会显示 `katefontrouting.dll` 的位置。

## 安装

1. 完全退出 Kate。
2. 以管理员身份打开 PowerShell 7。
3. 在项目目录运行：

```powershell
pwsh -File .\install.ps1
```

如果脚本没有自动找到 Kate：

```powershell
pwsh -File .\install.ps1 -KateExecutable 'C:\Program Files\Kate\bin\kate.exe'
```

脚本会检查 Kate 的 Qt 版本，查找现有的 `katefiletreeplugin.dll`，再把插件放进同一个 KTextEditor 插件目录。本机对应位置是：

```text
C:\Program Files\Kate\bin\kf6\ktexteditor\katefontrouting.dll
```

已有同名插件会先留下带时间戳的备份。

## 启用与设置

1. 启动 Kate。
2. 打开 `设置 → 配置 Kate → 插件`，勾选“字体路由 / Font Routing”。第三方插件不会被 Kate 自动启用。
3. 在 Kate 的编辑器字体设置中只选择：

```text
GeistMono Nerd Font Mono
```

这套字体在本机也可能以内部族名 `GeistMono NFM` 显示；如果列表里没有完整名称，就选择 `GeistMono NFM`。插件不接管主字体，因此这两种显示名不会影响中文与 Emoji 路由。

4. 完全退出并重新启动 Kate 一次。Qt 会在每次启动时由插件重新建立回退规则。

测试文本：

```text
const greeting = "Hello, 世界"; // 😀 🐱 🚗 ❤️ 👍
✓ → ★  󰀻
```

第二行的符号或 Nerd Font 私用区字符很可能继续由 GeistMono 绘制，这是正常行为：主字体已有 glyph 时不会进入普通 fallback。只有 Emoji presentation/Emoji 序列会进入 Qt 的专用 Emoji 路由；例如 `♥` 与 `♥️` 可能使用不同字体。

## 卸载

完全退出 Kate 后，以管理员身份运行：

```powershell
pwsh -File .\uninstall.ps1
```

脚本不会删除 DLL，而是将其改名为带时间戳的 `.disabled-*` 文件，便于恢复。

## 修改字体

在 `src/katefontroutingplugin.cpp` 顶部修改：

```cpp
const QStringList HanFallbackFonts{QStringLiteral("Maple Mono CN")};
const QStringList EmojiFallbackFonts{QStringLiteral("Noto Color Emoji")};
```

然后重新构建并安装。主字体仍由 Kate 自己的编辑器字体设置控制。

## 限制

- 这是进程级设置，会影响同一 Kate 进程中的所有 KTextEditor 视图。
- Han 规则仅在主字体缺字时工作；它不会强制替换主字体已经包含的汉字或符号。
- `QChar::Script_Han` 不包含所有中文标点；Common script 标点仍由主字体或系统回退决定。
- Qt 6.9 的 Emoji 规则面向彩色 Emoji 和 Emoji 序列，不会把每个“看起来像 Emoji”的普通符号都强制交给 Noto Color Emoji。
- 若另一组件在插件加载后再次修改相同的应用级字体列表，最后写入者生效。插件卸载时只会在当前值仍等于本插件设置时恢复先前值。

## 官方资料

- [Qt QFontDatabase](https://doc.qt.io/qt-6/qfontdatabase.html)
- [KTextEditor 6 插件模板](https://github.com/KDE/ktexteditor/tree/master/templates/ktexteditor6-plugin)
- [Windows 使用 KDE Craft 构建](https://develop.kde.org/docs/getting-started/building/craft/)
