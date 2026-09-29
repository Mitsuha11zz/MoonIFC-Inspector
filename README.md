# MoonIFC Inspector

面向 WASM 的轻量 IFC 建筑模型解析、结构审计与可视化检查器。首版聚焦 IFC STEP 文本的可控子集：解析实体、构建引用关系、输出稳定的审计报告，并提供静态浏览器 Demo 外壳。

## 快速开始

```text
moon check --target all --deny-warn
moon test --target all --deny-warn
moon run apps/inspect_cli
moon run apps/browser_demo
```

实测：`moon test --target all` 在 wasm、wasm-gc、js、native 四个目标上均为 23 通过、0 失败；`moon check --target all --deny-warn` 在严格模式下通过。注意上述 23 为补齐 `report_view` 测试前的数字，需以实际输出为准。

`apps/inspect_cli` 支持读取 `.ifc` 文件与三种视图切换：

```text
moon run apps/inspect_cli                              # 审计内置示例模型
moon run apps/inspect_cli -- examples/tiny-building.ifc            # 文本视图
moon run apps/inspect_cli -- --json examples/broken-references.ifc # JSON 视图
moon run apps/inspect_cli -- --tree examples/tiny-building.ifc     # 引用列表视图
moon run apps/inspect_cli -- --help                    # 用法说明
```

退出码：`0` 无发现，`1` 有发现，`2` 存在 STEP 解析诊断或文件读取错误。文件读取依赖 `moonbitlang/x`，在 wasm-gc / wasm 下需经 `moonrun` 运行（裸 `.wasm` 在浏览器中无文件系统主机函数），js 下依赖 `node:fs`。

核心代码位于 `packages/`，应用位于 `apps/`。解析器不依赖平台 API，可用于 wasm-gc、wasm、js 和 native 目标。

## 报告输出

`packages/report_view` 提供三种视图：

- `json(AuditReport)`：输出实体数、类型数、引用数与发现数组。每条发现包含 `code`、`severity`、`entity_id`、`entity_type`、`target_id`、`location`（行、列、偏移量对象，缺失时为 `null`）、`message`、`suggestion`；
- `text(AuditReport)`：前三行为统计信息，随后每条发现一行，格式为 `[严重级别] 规则编号 #实体编号 说明`；
- `tree(RelationMap)`：按源文件顺序逐行输出实体编号、类型及其直接引用目标（扁平引用列表，非缩进层级树）。

`report_view` 的测试见 `packages/report_view/report_view_test.mbt`。

## 范围

支持 HEADER/DATA 区段、实体编号、字符串、整数、浮点数、布尔值、枚举、引用、嵌套聚合以及 `$`/`*` 缺省值。支持的实体清单和已知限制见 [docs/supported-ifc.md](docs/supported-ifc.md)。

当前审计支持 `REF001` 悬空引用、`GID001` 重复 `GlobalId` 和 `SPAT001` 构件空间归属检查，结果顺序稳定，并保留实体位置与规则相关实体编号。

## 许可证

Apache-2.0
