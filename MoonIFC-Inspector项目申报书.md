# MoonIFC Inspector 项目申报书（初审版）

## 项目基本信息

- **项目名称：** MoonIFC Inspector——IFC 建筑模型结构检查工具
- **项目方向：** MoonBit 新生态建设 / 开发者工具
- **项目类型：** 原创项目，非移植
- **申报人：** Mitsuha11zz
- **联系方式：** 936163794@qq.com
- **代码仓库：** <https://github.com/Mitsuha11zz/MoonIFC-Inspector>
- **MoonBit 模块：** `Mitsuha11zz/moonifc_inspector`
- **许可证：** Apache-2.0

## 项目简介

MoonIFC Inspector 使用 MoonBit 解析 IFC STEP 文本，建立实体引用与空间层级索引，并检查常见的模型结构问题。它希望为 BIM 模型交付、IFC 导出器回归测试和查看器开发提供轻量、可复用的检查能力。

项目聚焦文本结构、实体引用和空间关系，不宣称完整支持 IFC/EXPRESS 标准，也不包含几何计算或三维渲染。

## 当前已实现

- 解析受控范围内的 STEP 文本，识别实体、属性、引用及源文件位置，并收集解析诊断。
- 按实体编号和类型建立索引，支持查询实体的入向、出向引用及父子关系。
- 提供 `REF001` 悬空引用、`GID001` 重复 GlobalId、`SPAT001` 空间归属检查。
- 联合检查多个专业 IFC 文件，以 `FED001` 提示复核跨文件重复的构件 GlobalId，并保留两侧的文件名、实体编号、类型和源位置。
- 输出文本、JSON、实体引用列表和空间层级树；CLI 可读取 IFC 文件并返回检查结果。
- 核心包可面向 `wasm`、`wasm-gc`、`js` 和 `native` 构建。

示例：

```bash
moon run apps/inspect_cli -- spatial-tree examples/tiny-building.ifc
moon run apps/inspect_cli -- audit examples/tiny-building.ifc --format json
```

## 现有项目检索与重合风险

Mooncakes 已有 [`chiooo09/moonbit-ifc@0.1.3`](https://mooncakes.io/docs/chiooo09/moonbit-ifc)。其公开 API 已涉及 STEP 值与实体模型、源位置、空间层级、诊断/校验，也覆盖几何、属性、查询与导出等方向。因此，MoonIFC Inspector 的基础解析和结构检查与其存在明显题材及功能重合。本项目新增了显式的多文件联合检查流程，但这只是当前的差异化尝试，尚未完成同样例对比，也不能据此宣称整个题材不重合或能力优于现有方案。

## 后续计划

1. 将浏览器端示例完善为可加载 IFC 文件并查看结构树、统计与诊断的 WASM Demo。
2. 根据实际样例逐步扩充 STEP/IFC 支持范围，并补充异常输入与大型模型测试。
3. 对照公开样例评估规则覆盖度，完善使用文档和检查结果说明。

## 验证情况

截至 2026-09-29，本地已通过格式检查、四目标检查与构建；测试在 `wasm`、`wasm-gc`、`js`、`native` 上各通过 38 项。以上为本地验证结果，不代表 GitHub Actions 当前状态。
