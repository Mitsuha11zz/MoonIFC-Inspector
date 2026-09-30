# Architecture

`step_text` 负责无平台依赖的 STEP 文本扫描；`ifc_entities` 把记录转换为领域实体；`relation_map` 提供引用和空间层级查询；`model_rules` 生成单模型结构审计发现；`model_federation` 解析专业模型清单，并统一编排各模型的结构审计与跨文件 GlobalId 策略检查。它还按清单模型名和构件 GlobalId 比较两个快照；修订比较忽略文件局部 STEP 编号，并从变更构件沿已识别 IFC 关系生成稳定、有上限的结构关联路径；这些路径用于定位关联实体，不推断几何或工程因果。`report_view` 负责文本、JSON 和关系树/审查/差异报告输出。应用包只组合这些领域包，不把规则复制到 CLI 或浏览器层。
