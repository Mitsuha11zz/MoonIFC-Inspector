# MoonIFC Inspector

面向 WASM 的轻量 IFC 建筑模型解析与结构检查器。除单文件审计外，项目提供跨多个专业 IFC 文件的联合检查，用于定位重复 GlobalId 并追溯两侧模型来源。

## 快速开始

```text
moon check --target all --deny-warn
moon test --target all --deny-warn
moon run apps/inspect_cli
moon run apps/browser_demo
```

检查和测试覆盖 wasm、wasm-gc、js、native 四个目标，测试数量以实际运行输出为准。

`apps/inspect_cli` 支持读取 `.ifc` 文件与四种视图切换：

```text
moon run apps/inspect_cli                              # 审计内置示例模型
moon run apps/inspect_cli -- examples/tiny-building.ifc            # 文本视图
moon run apps/inspect_cli -- --json examples/broken-references.ifc # JSON 视图
moon run apps/inspect_cli -- --tree examples/tiny-building.ifc     # 引用列表视图
moon run apps/inspect_cli -- --spatial-tree examples/spatial-hierarchy.ifc # 空间层级树
moon run apps/inspect_cli -- --federation examples/federation-architecture.ifc examples/federation-structure.ifc # 跨文件检查
moon run apps/inspect_cli -- --federation --json examples/federation-architecture.ifc examples/federation-structure.ifc # JSON
moon run apps/inspect_cli -- --help                    # 用法说明
```

退出码：`0` 无发现，`1` 有审计发现，`2` 存在 STEP 解析诊断或文件读取错误。联邦模式要求至少两个文件，只将不同文件间重复的已支持构件 GlobalId 报为 `FED001` warning；这是一条待复核提示，不直接判定为无效模型。每个文件内部的审计规则仍使用普通 `audit` 命令运行。文件读取依赖 `moonbitlang/x`，在 wasm-gc / wasm 下需经 `moonrun` 运行（裸 `.wasm` 在浏览器中无文件系统主机函数），js 下依赖 `node:fs`。

核心代码位于 `packages/`，应用位于 `apps/`。解析器不依赖平台 API，可用于 wasm-gc、wasm、js 和 native 目标。

## 报告输出

`packages/report_view` 提供三种视图：

- `json(AuditReport)`：输出实体数、类型数、引用数与发现数组。每条发现包含 `code`、`severity`、`entity_id`、`entity_type`、`target_id`、`location`（行、列、偏移量对象，缺失时为 `null`）、`message`、`suggestion`；
- `text(AuditReport)`：前三行为统计信息，随后每条发现一行，格式为 `[严重级别] 规则编号 #实体编号 说明`；
- `tree(RelationMap)`：按源文件顺序逐行输出实体编号、类型及其直接引用目标（扁平引用列表，非缩进层级树）。
- `spatial_tree(RelationMap)`：根据已索引的聚合和空间包含关系，以两空格缩进显示项目、场地、建筑、楼层、空间和构件。根节点按实体源文件顺序、子节点按关系出现顺序输出；未知类型若参与层级关系也会保留，独立的未知实体和关系记录不作为树根。
- `federation_text(FederationReport)` / `federation_json(FederationReport)`：输出跨 IFC 文件的重复 GlobalId、两侧文件名、实体信息和源位置。

空间层级示例：

```text
#1 IFCPROJECT
  #2 IFCSITE
    #3 IFCBUILDING
      #4 IFCBUILDINGSTOREY
        #5 IFCSPACE
          #6 IFCWALL
          #7 IFCDOOR
      #8 IFCBUILDINGSTOREY
        #9 IFCWINDOW
```

空间树用 `[missing]` 标记缺失子节点、`[missing parent #编号]` 标记悬空父级、`[cycle]` 标记循环边、`[already shown]` 标记已展示的共享子节点。没有可用根节点的循环分量会以 `[unrooted]` 起始；父级属于不展示的关系记录时标记 `[parent outside tree #编号]`。这些标记用于阅读异常结构，不增加审计规则。普通属性中的引用不会被推断为空间父子关系。

`report_view` 的测试见 `packages/report_view/report_view_test.mbt` 与 `packages/report_view/spatial_tree_test.mbt`。

## 范围

支持 HEADER/DATA 区段、实体编号、字符串、整数、浮点数、布尔值、枚举、引用、嵌套聚合以及 `$`/`*` 缺省值。支持的实体清单和已知限制见 [docs/supported-ifc.md](docs/supported-ifc.md)。

当前审计支持 `REF001` 悬空引用、`GID001` 重复 `GlobalId` 和 `SPAT001` 构件空间归属检查，结果顺序稳定，并保留实体位置与规则相关实体编号。

## 许可证

Apache-2.0
