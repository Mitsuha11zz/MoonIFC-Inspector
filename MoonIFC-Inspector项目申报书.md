# MoonIFC Inspector 项目申报书（修订版）

## 项目基本信息

- **项目名称：** MoonIFC Inspector——面向 OpenBIM 多专业交付的联邦审查与修订影响分析工具
- **项目方向：** MoonBit 新生态建设 / 开发者工具
- **项目类型：** 原创项目，非移植
- **申报人：** Mitsuha11zz
- **联系方式：** 936163794@qq.com
- **代码仓库：** <https://github.com/Mitsuha11zz/MoonIFC-Inspector>
- **MoonBit 模块：** `Mitsuha11zz/moonifc_inspector`
- **许可证：** Apache-2.0

## 项目简介

MoonIFC Inspector 面向建筑、结构等多个专业共同交付 IFC 模型的场景。它将多个模型视作一个交付批次：分别检查模型内部的引用与空间结构，再发现跨专业 GlobalId 冲突；对两个版本的交付清单，还能按构件 GlobalId 比较新增、删除和修改，并附带参数位置、空间路径、关系记录和关联模型，帮助审查者判断变化影响范围。

STEP 解析、空间索引和单模型规则是协同审查的底层能力，而非项目最终目标。项目不宣称完整支持 IFC/EXPRESS 标准；当前版本不解析几何，也不进行碰撞检测或形状等价判断。

## 当前已实现

- 解析受控范围内的 STEP 文本，识别实体、属性、引用及源文件位置，并收集解析诊断。
- 按实体编号和类型建立索引，支持查询实体的入向、出向引用及父子关系。
- 提供 `REF001`、`GID001`、`SPAT001`、`SPAT002`、`SPAT003` 单模型结构检查。
- 联邦审查一次运行每个模型的上述规则与跨文件 GlobalId 检查，支持专业清单、共享 ID 白名单，并输出统一文本或 JSON 审查结果。
- 对两个专业模型清单按模型名和构件 GlobalId 比较版本，忽略易变的 STEP 实体编号，报告参数位置、空间路径、关系上下文及关联模型。
- 输出文本、JSON、实体引用列表和空间层级树；CLI 可读取 IFC 文件并返回检查结果。
- 核心包可面向 `wasm`、`wasm-gc`、`js` 和 `native` 构建。

示例：

```bash
moon run apps/inspect_cli -- --spatial-tree examples/spatial-hierarchy.ifc
moon run apps/inspect_cli -- --json examples/broken-references.ifc
moon run apps/inspect_cli -- --federation-manifest examples/federation.manifest.json --json
moon run apps/inspect_cli -- --federation-diff examples/federation.manifest.json examples/federation-next.manifest.json --json
```

## 差异化定位与边界

Mooncakes 上已有 [`chiooo09/moonbit-ifc@0.1.3`](https://mooncakes.io/docs/chiooo09/moonbit-ifc)，公开 API 覆盖 IFC 模型、空间树、几何/网格、Schema 检查、查询、导出及模型差异/补丁等能力。项目不以“IFC 解析器更完整”或“检查规则更多”作为竞争点，也不宣称与其完全不重合。

本项目聚焦的使用任务不同：把来自多个专业、多个版本的 IFC 文件作为一个交付批次进行审查。当前实现将逐文件结构发现、跨文件共享标识策略和版本变化上下文汇总到统一流程中；其主要价值是模型交付协调与变化追溯，而不是通用 IFC 数据/几何处理。当前修订比较仍限于已识别构件子集，参数位置尚不等同于 EXPRESS 属性名，也不含几何差异。后续需要用公开样例对照测试验证这一工作流的实际收益。

## 后续计划

1. 扩展联邦版本比较的对象覆盖范围，并对照公开 IFC 样例验证重编号、重复标识和跨专业变更场景。
2. 为变化结果增加可交接的问题记录格式，先评估与 BIM 协同工具互通的最小字段集。
3. 继续完善大型模型性能、浏览器本地处理体验和报告可读性；几何计算不列入当前阶段。

## 验证情况

截至 2026-09-30，本地已通过 `moon fmt --check`、`moon check --target all --deny-warn`、`moon test --target all --deny-warn` 和四目标构建。测试结果：wasm 76 项、wasm-gc 80 项、js 76 项、native 76 项，均为 0 失败。联邦清单 CLI 已用仓库示例验证文本输出和单一 JSON 输出；示例数据包含两项空间归属 warning 和一项按白名单声明共享的 GlobalId。以上均为本地验证，不代表 GitHub Actions 当前状态。
