# Supported IFC subset

首版识别 `IFCPROJECT`、`IFCSITE`、`IFCBUILDING`、`IFCBUILDINGSTOREY`、`IFCSPACE`、`IFCWALL`、`IFCDOOR`、`IFCWINDOW`、`IFCRELAGGREGATES`、`IFCRELCONTAINEDINSPATIALSTRUCTURE` 和 `IFCRELDEFINESBYPROPERTIES`。未知类型会保留为实体，但当前不会单独产生类型 warning。完整 EXPRESS 类型系统、几何解析、压缩 IFC 和三维渲染不在首版范围内。

`ifc_entities` 将上述类型分为项目、空间、构件和关系四类；其他类型归为 `Unsupported`，仍保留其原始属性和引用。只对已识别类型从第一个字符串属性提取 `GlobalId`，不会把后续的名称误认为标识符。嵌套聚合中的实体引用按首次出现顺序去重。

`relation_map` 为实体编号、类型和双向引用建立索引；`children_of`/`parent_of` 只解释标准六属性形态的 `IFCRELAGGREGATES` 与 `IFCRELCONTAINEDINSPATIALSTRUCTURE`。子实体按关系出现顺序去重；若同一实体被多个关系指定父级，`parent_of` 返回首次出现的父级。悬空引用仍保留在查询结果中，交由后续审计规则报告。

`report_view.spatial_tree` 与 CLI 的 `--spatial-tree` 按这些已索引的关系生成缩进空间树，不从普通属性引用推断层级。每个实际节点最多展开一次；循环边、共享子节点和缺失引用显示标记，无根的循环分量仍会输出。参与层级的未知实体保留，独立未知实体和关系记录不作为树根。该视图保留所有已索引的子边，第二次遇到同一个子节点时显示 `[already shown]`，不把多父关系自动修正为合法 IFC 结构。

## 当前审计规则

`model_rules.audit` 当前按固定顺序运行以下规则：

- `REF001`：对不存在的引用目标生成 `Error`，记录来源实体编号、类型、实体起始行列位置、缺失目标编号、说明和修复建议。未知实体类型也参与引用检查。
- `GID001`：对重复的非空 `GlobalId` 生成 `Error`。首次出现的实体作为原始占用者，后续实体各产生一条结果，`target_id` 指向原始占用者。比较区分大小写；缺失、空字符串及未支持实体的首个字符串属性不参与检查。
- `SPAT001`：对 `IFCWALL`、`IFCDOOR` 和 `IFCWINDOW` 检查已索引的父级链中是否存在空间实体；找不到时生成 `Warning`。悬空父级由 `REF001` 报告，避免重复发现。该规则沿用 `parent_of` 的首次父级策略，不能据此完成所有 IFC 空间语义校验。

同一来源实体对同一目标的重复引用只报告一次；不同来源实体分别报告。结果按实体源文件顺序、引用首次出现顺序排列。合法的前向引用、自引用和循环引用不会触发本规则。统计中的引用数量指去重后的来源实体与目标编号组合数，而非文本中的出现次数。

规则只检查关系图中保留的实体，不合并 STEP 解析错误，也不检查根实体或其他 IFC 语义。结果按 `REF001`、`GID001`、`SPAT001` 的规则顺序排列，每条规则内部按源文件顺序稳定输出。结果位置指来源实体的起始位置，并非具体属性符号的位置。

## 跨文件联合检查

`model_federation.audit` 接受多个带来源名称的实体集合，仅对不同输入文件间重复的非空构件 `GlobalId` 生成 `FED001` warning。`audit_with_allowlist` 可通过大小写敏感的精确 GlobalId 白名单，把声明允许共享的重复项标为 `FED002` info；它仍会出现在报告中，但不计入未解决冲突数。当前范围仅包含已识别的 `IFCWALL`、`IFCDOOR` 和 `IFCWINDOW`；项目、空间结构及关系实体不会作为跨文件构件冲突候选。报告保留首次出现与后续出现两侧的模型名、专业标签、实体编号、实体类型和源位置；相同文件内的重复值仍由单文件 `GID001` 处理。输入文件顺序和实体顺序决定稳定的首次占用者及结果顺序。未知类型不会提取 `GlobalId`。允许列表表示显式项目策略，不判断两个构件在几何或属性上是否相同。

CLI 既支持 `--federation [--text|--json] MODEL1.ifc MODEL2.ifc [...]`，也支持 `--federation-manifest FILE.json`。清单包含至少两个 `models` 成员，每个成员需要唯一 `name`、`path`、`discipline`；`path` 相对于清单文件解析。可选字段 `allowed_shared_global_ids` 接受精确字符串列表。该模式只报告跨文件 GlobalId 冲突，不替代对每个文件运行 `audit`；清单错误、读取失败或 STEP 解析诊断仍以退出码 `2` 标示。示例见 `examples/federation.manifest.json`。

## 联邦修订差异范围

`--federation-diff OLD.json NEW.json` 读取两份联邦清单，将同名模型视为同一专业输入，再仅对当前已识别的 `IFCWALL`、`IFCDOOR`、`IFCWINDOW` 按非空 GlobalId 配对。新增、删除、类型变化和规范化 STEP 参数变化会分别报告；在其他模型中发现相同 GlobalId 时会列出相关模型。差异报告同时给出旧/新空间父级路径，以及直接引用该构件的已识别关系实体。重复 GlobalId 会被标为 `ambiguous`，不猜测配对，退出码为 `1`。

此处的 `ambiguous` 专指同一专业模型文件内部重复 GlobalId；跨专业模型之间的同 ID 不视为配对歧义，而会列为相关模型提示。

比较时不会将文件内的 `#实体编号` 当作跨版本身份：指向带 GlobalId 的实体时按 GlobalId 识别；其他引用按实体类型和递归规范化属性结构比较。`changed_arguments` 使用 STEP 参数的 1 起始位置，不代表具备 EXPRESS 属性名语义。该功能不解析几何、不做碰撞或形状相等判断，也不会检查未识别 IFC 类型。当前只报告构件元素差异，不报告清单白名单本身的策略变更。示例：`examples/federation.manifest.json` 对比 `examples/federation-next.manifest.json`。
