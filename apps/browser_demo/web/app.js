const MAX_FILE_BYTES = 2 * 1024 * 1024;
const WASM_URL = new URL("../../../_build/wasm-gc/release/build/apps/browser_demo/wasm_api/wasm_api.wasm", import.meta.url);
const SAMPLE_URL = new URL("../../../examples/browser-review.ifc", import.meta.url);

const elements = {
  dropCard: document.querySelector("#drop-card"),
  fileInput: document.querySelector("#ifc-file"),
  fileStatus: document.querySelector("#file-status"),
  loadSample: document.querySelector("#load-sample"),
  engineDot: document.querySelector("#engine-dot"),
  engineStatus: document.querySelector("#engine-status"),
  results: document.querySelector("#results"),
  modelName: document.querySelector("#model-name"),
  modelLabel: document.querySelector("#model-label"),
  modelSize: document.querySelector("#model-size"),
  statEntities: document.querySelector("#stat-entities"),
  statTypes: document.querySelector("#stat-types"),
  statRefs: document.querySelector("#stat-refs"),
  statFindings: document.querySelector("#stat-findings"),
  treeList: document.querySelector("#tree-list"),
  findingList: document.querySelector("#finding-list"),
  findingCount: document.querySelector("#finding-count"),
  diagnosticList: document.querySelector("#diagnostic-list"),
  diagnosticCount: document.querySelector("#diagnostic-count"),
  sourcePanel: document.querySelector("#source-panel"),
  sourceExcerpt: document.querySelector("#source-excerpt"),
  sourceLocationLabel: document.querySelector("#source-location-label"),
};

let wasmApi = null;
let currentSource = "";

function setEngineState(message, state) {
  elements.engineStatus.textContent = message;
  elements.engineDot.classList.toggle("ready", state === "ready");
  elements.engineDot.classList.toggle("failed", state === "failed");
}

function setStatus(message, isError = false) {
  elements.fileStatus.textContent = message;
  elements.fileStatus.classList.toggle("error", isError);
}

function makeElement(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function formatBytes(bytes) {
  return bytes < 1024 ? `${bytes} B` : `${(bytes / 1024).toFixed(1)} KiB`;
}

async function loadWasm() {
  const response = await fetch(WASM_URL);
  if (!response.ok) throw new Error(`WASM 文件读取失败（HTTP ${response.status}）。`);
  const bytes = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {});
  const exports = instance.exports;
  const required = [
    "moonifc_reset_input",
    "moonifc_push_input_char",
    "moonifc_run_inspection",
    "moonifc_result_length",
    "moonifc_result_char",
  ];
  for (const name of required) {
    if (typeof exports[name] !== "function") throw new Error(`WASM 导出缺少 ${name}。`);
  }
  return exports;
}

function readWasmResult() {
  const resultLength = wasmApi.moonifc_result_length();
  const chunks = [];
  let chunk = [];
  for (let index = 0; index < resultLength; index += 1) {
    chunk.push(wasmApi.moonifc_result_char(index));
    if (chunk.length === 8192 || index === resultLength - 1) {
      chunks.push(String.fromCodePoint(...chunk));
      chunk = [];
    }
  }
  return chunks.join("");
}

function inspectSource(source) {
  wasmApi.moonifc_reset_input();
  for (const character of source) wasmApi.moonifc_push_input_char(character.codePointAt(0));
  wasmApi.moonifc_run_inspection();
  return JSON.parse(readWasmResult());
}

function clearNode(node) {
  while (node.firstChild) node.removeChild(node.firstChild);
}

function renderTree(tree, findings) {
  clearNode(elements.treeList);
  const lines = tree ? tree.split("\n").filter(Boolean) : [];
  if (lines.length === 0) {
    elements.treeList.append(makeElement("p", "empty-state", "没有可展示的空间层级节点。"));
    return;
  }
  const relatedIds = new Set(findings.map((finding) => finding.entity_id).filter((id) => id !== null));
  const visible = lines.slice(0, 600);
  for (const line of visible) {
    const depth = (line.match(/^ */)?.[0].length ?? 0) / 2;
    const label = line.trimStart();
    const id = Number(label.match(/^#(\d+)/)?.[1]);
    const row = makeElement("div", "tree-row", label);
    row.style.paddingLeft = `${7 + depth * 19}px`;
    if (relatedIds.has(id)) row.classList.add("is-related");
    if (Number.isFinite(id)) row.dataset.entityId = String(id);
    elements.treeList.append(row);
  }
  if (lines.length > visible.length) {
    elements.treeList.append(makeElement("p", "tree-overflow", `其余 ${lines.length - visible.length} 个节点未展开显示。`));
  }
}

function locationLabel(location) {
  if (!location) return "位置未知";
  return `第 ${location.line} 行 · 第 ${location.column} 列`;
}

function focusLocation(location, entityId) {
  if (location && currentSource) {
    const lines = currentSource.split(/\r?\n/);
    const lineNumber = Math.max(1, Math.min(location.line, lines.length));
    const start = Math.max(1, lineNumber - 3);
    const end = Math.min(lines.length, lineNumber + 3);
    clearNode(elements.sourceExcerpt);
    for (let current = start; current <= end; current += 1) {
      const row = makeElement("span", "source-line");
      if (current === lineNumber) row.classList.add("is-current");
      const number = makeElement("span", "source-line-number", String(current).padStart(4, "0"));
      row.append(number, document.createTextNode(lines[current - 1]));
      elements.sourceExcerpt.append(row);
    }
    elements.sourceLocationLabel.textContent = locationLabel(location);
    elements.sourcePanel.open = true;
    elements.sourcePanel.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }
  for (const row of elements.treeList.querySelectorAll(".tree-row")) {
    row.classList.toggle("is-related", entityId !== null && row.dataset.entityId === String(entityId));
  }
}

function renderFindings(findings) {
  clearNode(elements.findingList);
  const errors = findings.filter((finding) => finding.severity === "error").length;
  const warnings = findings.filter((finding) => finding.severity === "warning").length;
  elements.statFindings.textContent = `${errors} / ${warnings}`;
  elements.findingCount.textContent = `${findings.length} 条`;
  if (findings.length === 0) {
    elements.findingList.append(makeElement("p", "empty-state", "没有发现审计规则问题。"));
    return;
  }
  const visible = findings.slice(0, 100);
  for (const finding of visible) {
    const severity = finding.severity === "error" ? "error" : finding.severity === "warning" ? "warning" : "info";
    const card = makeElement("button", `finding-card severity-${severity}`);
    card.type = "button";
    const top = makeElement("span", "finding-top");
    top.append(
      makeElement("span", "severity-mark"),
      makeElement("span", "finding-code", finding.code),
      makeElement("span", "finding-location", locationLabel(finding.location)),
    );
    const message = makeElement("span", "finding-message", finding.message);
    const entity = finding.entity_id === null ? "整个模型" : `#${finding.entity_id}${finding.entity_type ? ` · ${finding.entity_type}` : ""}`;
    card.append(top, message, makeElement("span", "finding-entity", entity));
    card.addEventListener("click", () => focusLocation(finding.location, finding.entity_id));
    elements.findingList.append(card);
  }
  if (findings.length > visible.length) {
    elements.findingList.append(makeElement("p", "empty-state", `另有 ${findings.length - visible.length} 条发现未显示。`));
  }
}

function renderDiagnostics(diagnostics) {
  clearNode(elements.diagnosticList);
  elements.diagnosticCount.textContent = `${diagnostics.length} 条`;
  if (diagnostics.length === 0) {
    elements.diagnosticList.append(makeElement("p", "empty-state", "没有解析错误。"));
    return;
  }
  const visible = diagnostics.slice(0, 100);
  for (const diagnostic of visible) {
    const card = makeElement("button", "diagnostic-card");
    card.type = "button";
    const position = diagnostic.location ? `L${diagnostic.location.line}:C${diagnostic.location.column}` : "位置未知";
    card.append(
      makeElement("span", "diagnostic-marker", position),
      makeElement("span", "diagnostic-kind", diagnostic.kind),
      makeElement("span", "diagnostic-message", diagnostic.message),
    );
    card.addEventListener("click", () => focusLocation(diagnostic.location, null));
    elements.diagnosticList.append(card);
  }
  if (diagnostics.length > visible.length) {
    elements.diagnosticList.append(makeElement("p", "empty-state", `另有 ${diagnostics.length - visible.length} 条诊断未显示。`));
  }
}

function showResult(name, sizeLabel, source, result) {
  currentSource = source;
  const audit = result.audit;
  elements.results.hidden = false;
  elements.modelName.textContent = name;
  elements.modelLabel.textContent = "IFC STEP 单文件检查";
  elements.modelSize.textContent = sizeLabel;
  elements.statEntities.textContent = String(audit.entity_count);
  elements.statTypes.textContent = String(audit.type_count);
  elements.statRefs.textContent = String(audit.reference_count);
  renderTree(result.spatial_tree, audit.findings);
  renderFindings(audit.findings);
  renderDiagnostics(result.parse_errors);
}

async function reviewFile(file) {
  if (!wasmApi) {
    setStatus("WASM 检查引擎尚未就绪，请稍后再试。", true);
    return;
  }
  if (file.size > MAX_FILE_BYTES) {
    setStatus("文件超过 2 MiB 上限；当前浏览器版面向轻量结构检查。", true);
    return;
  }
  if (!file.name.toLowerCase().endsWith(".ifc")) {
    setStatus("请选择扩展名为 .ifc 的 STEP 文本文件。", true);
    return;
  }
  setStatus(`正在本地读取 ${file.name}…`);
  try {
    const source = await file.text();
    const result = inspectSource(source);
    showResult(file.name, formatBytes(file.size), source, result);
    setStatus("检查完成：文件只在本地浏览器中读取，没有上传。");
  } catch (error) {
    setStatus(`检查未完成：${error instanceof Error ? error.message : String(error)}`, true);
  }
}

async function loadSample() {
  if (!wasmApi) {
    setStatus("WASM 检查引擎尚未就绪，请稍后再试。", true);
    return;
  }
  elements.loadSample.disabled = true;
  setStatus("正在读取随项目提供的 IFC 样例…");
  try {
    const response = await fetch(SAMPLE_URL);
    if (!response.ok) throw new Error(`样例读取失败（HTTP ${response.status}）。`);
    const source = await response.text();
    const result = inspectSource(source);
    showResult("browser-review.ifc", "项目样例", source, result);
    setStatus("样例检查完成：空间树可展开阅读，审计发现可定位到源文件行。");
  } catch (error) {
    setStatus(`${error instanceof Error ? error.message : String(error)} 请确认已构建 WASM，并从仓库根目录启动本地 HTTP 服务。`, true);
  } finally {
    elements.loadSample.disabled = false;
  }
}

elements.fileInput.addEventListener("change", (event) => {
  const [file] = event.currentTarget.files ?? [];
  if (file) reviewFile(file);
  event.currentTarget.value = "";
});
elements.dropCard.addEventListener("click", (event) => {
  if (event.target.closest("label") || event.target.closest("input")) return;
  elements.fileInput.click();
});

for (const eventName of ["dragenter", "dragover"]) {
  elements.dropCard.addEventListener(eventName, (event) => {
    event.preventDefault();
    elements.dropCard.classList.add("is-over");
  });
}
for (const eventName of ["dragleave", "drop"]) {
  elements.dropCard.addEventListener(eventName, (event) => {
    event.preventDefault();
    elements.dropCard.classList.remove("is-over");
  });
}
elements.dropCard.addEventListener("drop", (event) => {
  const [file] = event.dataTransfer?.files ?? [];
  if (file) reviewFile(file);
});
elements.dropCard.addEventListener("keydown", (event) => {
  if (event.target !== elements.dropCard || !["Enter", " "].includes(event.key)) return;
  event.preventDefault();
  elements.fileInput.click();
});
elements.loadSample.addEventListener("click", loadSample);

try {
  wasmApi = await loadWasm();
  setEngineState("MoonBit WASM-GC 引擎就绪", "ready");
  setStatus("可以选择本地 IFC 文件，或载入项目样例开始检查。");
} catch (error) {
  setEngineState("WASM 引擎未加载", "failed");
  setStatus(`${error instanceof Error ? error.message : String(error)} 请先执行 moon build --target wasm-gc apps/browser_demo/wasm_api --release。`, true);
}
