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
moon run apps/inspect_cli -- --federation-manifest examples/federation.manifest.json # 按专业清单联合检查
moon run apps/inspect_cli -- --federation-manifest examples/federation.manifest.json --json # 清单模式 JSON
moon run apps/inspect_cli -- --federation-diff examples/federation.manifest.json examples/federation-next.manifest.json # 比较联邦版本
moon run apps/inspect_cli -- --federation-diff examples/federation.manifest.json examples/federation-next.manifest.json --json # 差异 JSON
moon run apps/inspect_cli -- --help                    # 用法说明
```

浏览器版单文件检查器（拖放 IFC、查看空间树与可定位诊断）：

```text
moon build --target wasm-gc apps/browser_demo/wasm_api --release --deny-warn
python -m http.server 8000
```

在仓库根目录启动静态服务器后打开 `http://localhost:8000/apps/browser_demo/web/`。文件只在浏览器本地处理，页面限制单文件不超过 2 MiB。完整说明见 [docs/demo.md](docs/demo.md)。

退出码：普通联邦审计中 `0` 无未解决发现、`1` 有未允许的跨文件冲突、`2` 有解析/清单/读取错误；修订差异模式中 `0` 表示成功比较、`1` 表示存在重复 GlobalId 导致无法可靠配对、`2` 表示输入错误。旧 `--federation` 用法仍可直接传入多个文件；清单模式从 JSON 读取模型名、相对路径和专业标签，路径相对于清单文件解析。`allowed_shared_global_ids` 是大小写敏感的精确白名单：白名单中的跨文件重复项以 `FED002` info 展示但不阻断，其他重复项仍为 `FED001` warning。白名单只表示项目明确允许共享该 GlobalId，不会自动证明两侧构件语义等价。文件读取依赖 `moonbitlang/x`，在 wasm-gc / wasm 下需经 `moonrun` 运行（裸 `.wasm` 在浏览器中无文件系统主机函数），js 下依赖 `node:fs`。

`--federation-diff OLD.json NEW.json` 按清单中的模型名配对专业模型，再按构件 GlobalId 报告新增、删除和修改；它会忽略 STEP 文件内可能重排的实体编号，并输出改变的 STEP 参数位置、空间父级路径、直接引用该构件的关系记录，以及在其他模型中出现相同 GlobalId 的提示。此功能只做结构与引用差异，不解析几何，也不声称构件几何等价。示例中的 `federation.manifest.json` 与 `federation-next.manifest.json` 可直接运行。差异模式退出码 `1` 仅表示同一专业模型内部有重复 GlobalId，跨专业模型共享同一 GlobalId 会作为相关模型提示。

核心代码位于 `packages/`，应用位于 `apps/`。解析器不依赖平台 API，可用于 wasm-gc、wasm、js 和 native 目标。

## 报告输出

`packages/report_view` 提供三种视图：

- `json(AuditReport)`：输出实体数、类型数、引用数与发现数组。每条发现包含 `code`、`severity`、`entity_id`、`entity_type`、`target_id`、`location`（行、列、偏移量对象，缺失时为 `null`）、`message`、`suggestion`；
- `text(AuditReport)`：前三行为统计信息，随后每条发现一行，格式为 `[严重级别] 规则编号 #实体编号 说明`；
- `tree(RelationMap)`：按源文件顺序逐行输出实体编号、类型及其直接引用目标（扁平引用列表，非缩进层级树）。
- `spatial_tree(RelationMap)`：根据已索引的聚合和空间包含关系，以两空格缩进显示项目、场地、建筑、楼层、空间和构件。根节点按实体源文件顺序、子节点按关系出现顺序输出；未知类型若参与层级关系也会保留，独立的未知实体和关系记录不作为树根。
- `federation_text(FederationReport)` / `federation_json(FederationReport)`：输出跨 IFC 文件的重复 GlobalId、两侧文件名、实体信息和源位置。
- `federation_diff_text(FederationDiffReport)` / `federation_diff_json(FederationDiffReport)`：输出两个联邦快照的构件变化、参数位置、空间路径、直接关系影响和共享模型提示。

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
