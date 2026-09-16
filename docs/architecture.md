# Architecture

`step_text` 负责无平台依赖的 STEP 文本扫描；`ifc_entities` 把记录转换为领域实体；`relation_map` 提供引用查询；`model_rules` 生成稳定排序的审计发现；`report_view` 负责文本、JSON 和关系树输出。应用包只组合这些领域包，不把规则复制到 CLI 或浏览器层。
