# Supported IFC subset

首版识别 `IFCPROJECT`、`IFCSITE`、`IFCBUILDING`、`IFCBUILDINGSTOREY`、`IFCSPACE`、`IFCWALL`、`IFCDOOR`、`IFCWINDOW`、`IFCRELAGGREGATES`、`IFCRELCONTAINEDINSPATIALSTRUCTURE` 和 `IFCRELDEFINESBYPROPERTIES`。未知类型保留为实体并产生 warning。完整 EXPRESS 类型系统、几何解析、压缩 IFC 和三维渲染不在首版范围内。

`ifc_entities` 将上述类型分为项目、空间、构件和关系四类；其他类型归为 `Unsupported`，仍保留其原始属性和引用。只对已识别类型从第一个字符串属性提取 `GlobalId`，不会把后续的名称误认为标识符。嵌套聚合中的实体引用按首次出现顺序去重。

`relation_map` 为实体编号、类型和双向引用建立索引；`children_of`/`parent_of` 只解释标准六属性形态的 `IFCRELAGGREGATES` 与 `IFCRELCONTAINEDINSPATIALSTRUCTURE`。子实体按关系出现顺序去重；若同一实体被多个关系指定父级，`parent_of` 返回首次出现的父级。悬空引用仍保留在查询结果中，交由后续审计规则报告。
