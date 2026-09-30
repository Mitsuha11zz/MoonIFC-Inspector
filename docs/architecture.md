# Architecture

`step_text` 负责无平台依赖的 STEP 文本扫描；`ifc_entities` 把记录转换为领域实体；`relation_map` 提供引用和空间层级查询；`model_rules` 生成单文件结构审计发现；`model_federation` 跨多个 IFC 文件检查 GlobalId 冲突、解析专业模型清单，并按清单模型名和构件 GlobalId 比较两个快照；修订比较忽略文件局部 STEP 编号，通过关系图补充空间路径与直接关系影响；`report_view` 负责文本、JSON 和关系树/差异报告输出。应用包只组合这些领域包，不把规则复制到 CLI 或浏览器层。
