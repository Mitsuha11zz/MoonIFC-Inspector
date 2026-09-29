# Architecture

`step_text` 负责无平台依赖的 STEP 文本扫描；`ifc_entities` 把记录转换为领域实体；`relation_map` 提供引用查询；`model_rules` 生成单文件结构审计发现；`model_federation` 跨多个 IFC 文件聚合实体并检查跨文件 GlobalId 冲突，也负责解析专业模型清单和应用显式共享白名单；`report_view` 负责文本、JSON 和关系树输出。应用包只组合这些领域包，不把规则复制到 CLI 或浏览器层。
