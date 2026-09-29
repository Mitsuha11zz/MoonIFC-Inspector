///|
/// 审计报告的呈现方式。
enum View {
  Text
  Json
  Tree
}

///|
/// 命令行用法说明。
fn usage() -> String {
  "MoonIFC Inspector - IFC STEP structural auditor\n\n" +
  "USAGE:\n" +
  "  moon run apps/inspect_cli -- [OPTIONS] [FILE.ifc]\n\n" +
  "OPTIONS:\n" +
  "  --text     print the text report (default)\n" +
  "  --json     print the JSON report\n" +
  "  --tree     print the entity reference list\n" +
  "  --help     print this message\n\n" +
  "Without FILE, a built-in sample model is audited.\n" +
  "Exit codes: 0 clean, 1 findings, 2 STEP parse diagnostics or read error."
}

///|
/// 解析视图参数；不是视图开关时返回 None。
fn parse_view(arg : String) -> View? {
  match arg {
    "--text" => Some(Text)
    "--json" => Some(Json)
    "--tree" => Some(Tree)
    _ => None
  }
}

///|
/// 编译期固定的内置示例模型：一处指向 `#99` 的悬空引用，用于演示 REF001。
fn sample() -> String {
  "ISO-10303-21;\nHEADER;\nENDSEC;\nDATA;\n#1=IFCPROJECT('P',());\n#2=IFCWALL('W',#99);\nENDSEC;\nEND-ISO-10303-21;"
}

///|
/// 按视图渲染报告；引用列表视图需要关系图，因此单独传入。
fn render(
  view : View,
  report : @model_rules.AuditReport,
  map : @relation_map.RelationMap,
) -> String {
  match view {
    Text => @report_view.text(report)
    Json => @report_view.json(report)
    Tree => @report_view.tree(map)
  }
}

///|
/// 解析并审计一段 IFC STEP 文本。返回退出码：0 无发现，1 有发现，2 存在解析诊断。
fn inspect(source : String, view : View) -> Int {
  let document = @step_text.parse(source)
  let map = @relation_map.build(@ifc_entities.build(document))
  let report = @model_rules.audit(map)
  println(render(view, report, map))
  // 审计报告不并入 STEP 解析诊断，此处单独呈现，避免畸形输入被静默忽略。
  let errors = document.errors()
  if errors.length() > 0 {
    println("")
    println("STEP parse diagnostics: " + errors.length().to_string())
    for error in errors {
      println("  " + error.location().to_string() + " " + error.message())
    }
    return 2
  }
  return if report.findings().length() > 0 { 1 } else { 0 }
}

///|
/// 读取 `.ifc` 文件；失败时返回可读的错误说明。
fn read_source(file : String) -> Result[String, String] {
  if !@fs.path_exists(file) {
    return Err("file not found: " + file)
  }
  let loaded : Result[String, String] = Ok(@fs.read_file_to_string(file)) catch {
    _ => Err("cannot read file: " + file)
  }
  loaded
}

///|
/// 读取并审计一个 `.ifc` 文件。返回退出码：0 无发现，1 有发现，2 解析诊断或读取错误。
fn inspect_file(file : String, view : View) -> Int {
  match read_source(file) {
    Ok(source) => inspect(source, view)
    Err(message) => {
      println("error: " + message)
      return 2
    }
  }
}

///|
/// 非 js 目标下 `@env.args()` 的首元素是可执行前缀，跳过它才是用户参数。
fn user_args(args : Array[String]) -> Array[String] {
  match args {
    [_, .. rest] => rest.to_owned()
    [] => []
  }
}

///|
fn main {
  let args = user_args(@env.args())
  let mut view : View = Text
  let mut path : String? = None
  let mut help = false
  for arg in args {
    match parse_view(arg) {
      Some(next) => view = next
      None =>
        match arg {
          "--help" => help = true
          _ =>
            if arg.has_prefix("--") {
              println("unknown option: " + arg)
              println("")
              help = true
            } else {
              match path {
                None => path = Some(arg)
                Some(_) => {
                  println("unexpected extra argument: " + arg)
                  println("")
                  help = true
                }
              }
            }
        }
    }
  }
  let code = if help {
    println(usage())
    0
  } else {
    match path {
      Some(file) => {
        println("file: " + file)
        inspect_file(file, view)
      }
      None => {
        println("sample model (built-in)")
        inspect(sample(), view)
      }
    }
  }
  if code != 0 {
    @sys.exit(code)
  }
}
