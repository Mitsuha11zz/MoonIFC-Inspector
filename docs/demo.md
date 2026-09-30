# Demo

## CLI（可读取真实 `.ifc` 文件）

`apps/inspect_cli` 支持按文件路径审计，并可在三种视图间切换：

```text
moon run apps/inspect_cli                              # 审计内置示例模型
moon run apps/inspect_cli -- examples/tiny-building.ifc            # 文本视图（默认）
moon run apps/inspect_cli -- --json examples/broken-references.ifc # JSON 视图
moon run apps/inspect_cli -- --tree examples/tiny-building.ifc     # 引用列表视图
moon run apps/inspect_cli -- --federation-diff examples/federation.manifest.json examples/federation-next.manifest.json
moon run apps/inspect_cli -- --federation-diff examples/federation.manifest.json examples/federation-next.manifest.json --json
moon run apps/inspect_cli -- --help                    # 用法说明
```

`--` 之后的第一个非选项参数被视为文件路径，第二个非选项参数会报错。退出码：`0` 无发现，`1` 有发现，`2` 存在 STEP 解析诊断或文件读取错误。

审计报告之外，CLI 会单独输出 STEP 解析诊断（位置与说明）。审计规则本身不合并解析错误，两者分开呈现以免畸形输入被静默忽略。

联邦修订差异模式读取两份 JSON 清单，按模型名和构件 GlobalId 比较，并展示 STEP 参数位置变化、空间父级路径、直接引用关系和共享模型提示。差异本身是信息性输出并返回 `0`；同一专业模型内重复 GlobalId 会以 `ambiguous` 结果报告并返回 `1`；清单、文件读取或 STEP 解析错误返回 `2`。示例模型在修订版中改了墙名、加入入口门，并把墙放入楼层，便于观察变化及影响路径。

文件读取由 `moonbitlang/x/fs` 提供，因此运行方式受目标限制：wasm-gc / wasm 下需经 `moonrun` 提供文件系统主机函数（`moon run` 即是），js 下依赖 `node:fs`。裸 `.wasm` 在浏览器中没有这些主机函数，读文件会失败。

## 浏览器 Demo

浏览器版已接入 `wasm-gc` 检查引擎。页面可以拖放或选择单个 `.ifc` 文件，展示实体/类型/引用统计、空间层级、审计发现和 STEP 解析诊断。点击发现会打开源文件上下文并高亮对应行，同时标出相关实体。提供一份包含完整空间结构、悬空引用和语法错误的项目样例。

检查全部在浏览器本地完成：页面使用 `File.text()` 读取所选文件，再通过数值字符桥传给 MoonBit WASM；不会上传模型。为避免浏览器端长时间同步处理，单文件上限为 2 MiB。该演示不进行几何渲染，也不证明完整 IFC 标准合规性。

在仓库根目录构建 WASM 并启动静态服务器：

```text
moon build --target wasm-gc apps/browser_demo/wasm_api --release --deny-warn
python -m http.server 8000
```

然后打开 `http://localhost:8000/apps/browser_demo/web/`。如果打开页面提示 WASM 文件缺失，请先完成构建；不要直接用 `file://` 打开，因为浏览器会限制本地文件加载。

`moon run apps/browser_demo` 仍是命令行 JSON 演示入口；浏览器页面与跨目标演示入口分开，避免把浏览器文件 API 引入核心包。
