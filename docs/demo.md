# Demo

## CLI（可读取真实 `.ifc` 文件）

`apps/inspect_cli` 支持按文件路径审计，并可在三种视图间切换：

```text
moon run apps/inspect_cli                              # 审计内置示例模型
moon run apps/inspect_cli -- examples/tiny-building.ifc            # 文本视图（默认）
moon run apps/inspect_cli -- --json examples/broken-references.ifc # JSON 视图
moon run apps/inspect_cli -- --tree examples/tiny-building.ifc     # 引用列表视图
moon run apps/inspect_cli -- --help                    # 用法说明
```

`--` 之后的第一个非选项参数被视为文件路径，第二个非选项参数会报错。退出码：`0` 无发现，`1` 有发现，`2` 存在 STEP 解析诊断或文件读取错误。

审计报告之外，CLI 会单独输出 STEP 解析诊断（位置与说明）。审计规则本身不合并解析错误，两者分开呈现以免畸形输入被静默忽略。

文件读取由 `moonbitlang/x/fs` 提供，因此运行方式受目标限制：wasm-gc / wasm 下需经 `moonrun` 提供文件系统主机函数（`moon run` 即是），js 下依赖 `node:fs`。裸 `.wasm` 在浏览器中没有这些主机函数，读文件会失败。

## 浏览器 Demo（占位）

`apps/browser_demo` 是一个可编译到 WASM/JS 的最小入口，运行后输出 JSON 摘要。`apps/browser_demo/web/index.html` 提供无需前端依赖的演示页面，当前为文件选择占位实现，尚未接入 WASM 绑定与结果渲染。

浏览器端接入读文件时不能复用 `moonbitlang/x/fs`，需改用 Web API（`File` / `FileReader` 或 `fetch`）把文本交给解析器。
