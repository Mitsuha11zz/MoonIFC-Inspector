# Supported IFC subset

首版识别 `IFCPROJECT`、`IFCSITE`、`IFCBUILDING`、`IFCBUILDINGSTOREY`、`IFCSPACE`、`IFCWALL`、`IFCDOOR`、`IFCWINDOW`、`IFCRELAGGREGATES`、`IFCRELCONTAINEDINSPATIALSTRUCTURE` 和 `IFCRELDEFINESBYPROPERTIES`。未知类型会保留为实体，但当前不会单独产生类型 warning。完整 EXPRESS 类型系统、几何解析、压缩 IFC 和三维渲染不在首版范围内。

`ifc_entities` 将上述类型分为项目、空间、构件和关系四类；其他类型归为 `Unsupported`，仍保留其原始属性和引用。只对已识别类型从第一个字符串属性提取 `GlobalId`，不会把后续的名称误认为标识符。嵌套聚合中的实体引用按首次出现顺序去重。

`relation_map` 为实体编号、类型和双向引用建立索引；`children_of`/`parent_of` 只解释标准六属性形态的 `IFCRELAGGREGATES` 与 `IFCRELCONTAINEDINSPATIALSTRUCTURE`。子实体按关系出现顺序去重；若同一实体被多个关系指定父级，`parent_of` 返回首次出现的父级。悬空引用仍保留在查询结果中，交由后续审计规则报告。

## 当前审计规则

`model_rules.audit` 当前按固定顺序运行以下规则：

- `REF001`：对不存在的引用目标生成 `Error`，记录来源实体编号、类型、实体起始行列位置、缺失目标编号、说明和修复建议。未知实体类型也参与引用检查。
- `GID001`：对重复的非空 `GlobalId` 生成 `Error`。首次出现的实体作为原始占用者，后续实体各产生一条结果，`target_id` 指向原始占用者。比较区分大小写；缺失、空字符串及未支持实体的首个字符串属性不参与检查。

同一来源实体对同一目标的重复引用只报告一次；不同来源实体分别报告。结果按实体源文件顺序、引用首次出现顺序排列。合法的前向引用、自引用和循环引用不会触发本规则。统计中的引用数量指去重后的来源实体与目标编号组合数，而非文本中的出现次数。

规则只检查关系图中保留的实体，不合并 STEP 解析错误，也不检查空间归属、根实体或其他 IFC 语义。结果按 `REF001`、`GID001` 的规则顺序排列，每条规则内部按源文件顺序稳定输出。结果位置指来源实体的起始位置，并非具体属性符号的位置。
