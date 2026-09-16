# MoonIFC Inspector

面向 WASM 的轻量 IFC 建筑模型解析、结构审计与可视化检查器。首版聚焦 IFC STEP 文本的可控子集：解析实体、构建引用关系、输出稳定的审计报告，并提供静态浏览器 Demo 外壳。

## 快速开始

```text
moon check --target all --deny-warn
moon test --target all --deny-warn
moon run apps/inspect_cli
moon run apps/browser_demo
```

核心代码位于 `packages/`，应用位于 `apps/`。解析器不依赖平台 API，可用于 wasm-gc、wasm、js 和 native 目标。

## 范围

支持 HEADER/DATA 区段、实体编号、字符串、整数、浮点数、布尔值、枚举、引用、嵌套聚合以及 `$`/`*` 缺省值。支持的实体清单和已知限制见 [docs/supported-ifc.md](docs/supported-ifc.md)。

## 许可证

Apache-2.0
