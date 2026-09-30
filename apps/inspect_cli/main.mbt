///|
/// 审计报告的呈现方式。
enum View {
  Text
  Json
  Tree
  SpatialTree
}

///|
/// 命令行用法说明。
fn usage() -> String {
  "MoonIFC Inspector - OpenBIM federation review\n\n" +
  "USAGE:\n" +
  "  moon run apps/inspect_cli -- [OPTIONS] [FILE.ifc]\n\n" +
  "OPTIONS:\n" +
  "  --text     print the text report (default)\n" +
  "  --json     print the JSON report\n" +
  "  --tree     print the entity reference list\n" +
  "  --spatial-tree  print the indented spatial hierarchy\n" +
  "  --federation  audit each model and check cross-file coordination\n" +
  "  --federation-manifest FILE  review discipline models and shared-ID policy\n" +
  "  --federation-diff OLD.json NEW.json  compare two federation revisions\n" +
  "  --help     print this message\n\n" +
  "Federation usage: moon run apps/inspect_cli -- --federation [--json] MODEL1.ifc MODEL2.ifc [...]\n" +
  "Manifest usage: moon run apps/inspect_cli -- --federation-manifest examples/federation.manifest.json [--json]\n" +
  "Revision usage: moon run apps/inspect_cli -- --federation-diff examples/federation.manifest.json examples/federation-next.manifest.json [--json]\n" +
  "Federation review runs per-model structural rules and cross-file GlobalId checks together.\n\n" +
  "Revision diff matches manifest model names and element GlobalIds; geometry is not compared.\n" +
  "Without FILE, a built-in sample model is audited.\n" +
  "Exit codes: audit 0 clean / 1 finding; revision diff 0 compared / 1 duplicate GlobalId within a model; 2 input error."
}

///|
/// 解析视图参数；不是视图开关时返回 None。
fn parse_view(arg : String) -> View? {
  match arg {
    "--text" => Some(Text)
    "--json" => Some(Json)
    "--tree" => Some(Tree)
    "--spatial-tree" => Some(SpatialTree)
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
    SpatialTree => @report_view.spatial_tree(map)
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
/// Audit each IFC source and shared GlobalIds across the federation.
fn inspect_federation(files : Array[String], view : View) -> Int {
  if !federation_view_supported(view) {
    return 2
  }
  let models : Array[@model_federation.ModelSource] = []
  let mut input_errors = 0
  for file in files {
    match read_source(file) {
      Ok(source) => {
        let document = @step_text.parse(source)
        let errors = document.errors()
        if errors.length() > 0 {
          input_errors += errors.length()
          println("STEP parse diagnostics in " + file + ":")
          for error in errors {
            println("  " + error.location().to_string() + " " + error.message())
          }
        }
        models.push(
          @model_federation.ModelSource::new(
            name=file,
            entities=@ifc_entities.build(document),
          ),
        )
      }
      Err(message) => {
        input_errors += 1
        println("error: " + message)
      }
    }
  }
  emit_federation_report(models, [], view, input_errors)
}

///|
fn federation_view_supported(view : View) -> Bool {
  match view {
    Text | Json => true
    Tree | SpatialTree => {
      println("error: federation mode supports only --text or --json")
      false
    }
  }
}

///|
fn emit_federation_report(
  models : Array[@model_federation.ModelSource],
  allowed_global_ids : Array[String],
  view : View,
  input_errors : Int,
) -> Int {
  let report = @model_federation.review_with_allowlist(
    models, allowed_global_ids,
  )
  let output = match view {
    Text => @report_view.federation_review_text(report)
    Json => @report_view.federation_review_json(report)
    Tree | SpatialTree => ""
  }
  println(output)
  if input_errors > 0 {
    2
  } else if report.has_findings() {
    1
  } else {
    0
  }
}

///|
/// Load and audit the discipline inputs named by a JSON federation manifest.
fn inspect_federation_manifest(file : String, view : View) -> Int {
  if !federation_view_supported(view) {
    return 2
  }
  match read_source(file) {
    Err(message) => {
      println("error: " + message)
      return 2
    }
    Ok(source) =>
      match @model_federation.parse_manifest(source) {
        Err(message) => {
          println("error: invalid federation manifest: " + message)
          return 2
        }
        Ok(manifest) => {
          let models : Array[@model_federation.ModelSource] = []
          let seen_paths : Map[String, Bool] = Map([])
          let mut input_errors = 0
          let manifest_dir : @path.Path = @path.Path(file).dirname()
          for model_entry in manifest.models() {
            let configured_path : @path.Path = @path.Path(model_entry.path())
            let resolved_path = if configured_path.is_absolute() {
              configured_path.normalize()
            } else {
              manifest_dir.join(configured_path).normalize()
            }
            let model_file = resolved_path.to_string()
            if seen_paths.contains(model_file) {
              input_errors += 1
              println("error: duplicate model file in manifest: " + model_file)
            } else {
              seen_paths[model_file] = true
              match read_source(model_file) {
                Err(message) => {
                  input_errors += 1
                  println("error: " + message)
                }
                Ok(model_source) => {
                  let document = @step_text.parse(model_source)
                  let errors = document.errors()
                  if errors.length() > 0 {
                    input_errors += errors.length()
                    println("STEP parse diagnostics in " + model_file + ":")
                    for error in errors {
                      println(
                        "  " +
                        error.location().to_string() +
                        " " +
                        error.message(),
                      )
                    }
                  }
                  models.push(
                    @model_federation.ModelSource::new(
                      name=model_entry.name(),
                      discipline=model_entry.discipline(),
                      entities=@ifc_entities.build(document),
                    ),
                  )
                }
              }
            }
          }
          emit_federation_report(
            models,
            manifest.allowed_shared_global_ids(),
            view,
            input_errors,
          )
        }
      }
  }
}

///|
/// Load all IFC models in one manifest; revision comparison fails closed on parse errors.
fn load_federation_revision(
  file : String,
) -> Result[Array[@model_federation.ModelSource], String] {
  let source = match read_source(file) {
    Err(message) => return Err(message)
    Ok(value) => value
  }
  let manifest = match @model_federation.parse_manifest(source) {
    Err(message) => return Err("invalid federation manifest: " + message)
    Ok(value) => value
  }
  let models : Array[@model_federation.ModelSource] = []
  let seen_paths : Map[String, Bool] = Map([])
  let manifest_dir : @path.Path = @path.Path(file).dirname()
  for entry in manifest.models() {
    let configured_path : @path.Path = @path.Path(entry.path())
    let resolved_path = if configured_path.is_absolute() {
      configured_path.normalize()
    } else {
      manifest_dir.join(configured_path).normalize()
    }
    let model_file = resolved_path.to_string()
    if seen_paths.contains(model_file) {
      return Err("duplicate model file in manifest: " + model_file)
    }
    seen_paths[model_file] = true
    let model_source = match read_source(model_file) {
      Err(message) => return Err(message)
      Ok(value) => value
    }
    let document = @step_text.parse(model_source)
    let parse_errors = document.errors()
    if parse_errors.length() > 0 {
      let details : Array[String] = []
      for parse_error in parse_errors {
        details.push(
          parse_error.location().to_string() + " " + parse_error.message(),
        )
      }
      return Err(
        "STEP parse diagnostics in " + model_file + ": " + details.join("; "),
      )
    }
    models.push(
      @model_federation.ModelSource::new(
        name=entry.name(),
        discipline=entry.discipline(),
        entities=@ifc_entities.build(document),
      ),
    )
  }
  Ok(models)
}

///|
/// Compare two manifest snapshots. Element changes are informational; ambiguous IDs need review.
fn inspect_federation_diff(
  before_file : String,
  after_file : String,
  view : View,
) -> Int {
  if !federation_view_supported(view) {
    return 2
  }
  let before = match load_federation_revision(before_file) {
    Err(message) => {
      println("error: baseline " + message)
      return 2
    }
    Ok(models) => models
  }
  let after = match load_federation_revision(after_file) {
    Err(message) => {
      println("error: current " + message)
      return 2
    }
    Ok(models) => models
  }
  let report = @model_federation.compare_revisions(before, after)
  let output = match view {
    Text => @report_view.federation_diff_text(report)
    Json => @report_view.federation_diff_json(report)
    Tree | SpatialTree => ""
  }
  println(output)
  if report.ambiguous_count() > 0 {
    1
  } else {
    0
  }
}

///|
/// Node 参数包含运行时路径和脚本路径，跳过两个前缀。
#cfg(target="js")
fn user_args(args : Array[String]) -> Array[String] {
  match args {
    [_, _, .. rest] => rest.to_owned()
    [] | [_] => []
  }
}

///|
/// 其他目标下首元素是可执行前缀。
#cfg(not(target="js"))
fn user_args(args : Array[String]) -> Array[String] {
  match args {
    [_, .. rest] => rest.to_owned()
    [] => []
  }
}

///|
struct Arguments {
  view : View
  federation : Bool
  federation_manifest : Bool
  federation_diff : Bool
  paths : Array[String]
  help : Bool
}

///|
fn parse_arguments(args : Array[String]) -> Arguments {
  let mut view : View = Text
  let mut federation = false
  let mut federation_manifest = false
  let mut federation_diff = false
  let paths : Array[String] = []
  let mut help = false
  for arg in args {
    match arg {
      "--federation" => federation = true
      "--federation-manifest" => federation_manifest = true
      "--federation-diff" => federation_diff = true
      _ =>
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
                  paths.push(arg)
                }
            }
        }
    }
  }
  { view, federation, federation_manifest, federation_diff, paths, help, }
}

///|
/// Keep duplicate path arguments from treating one file as two federation members.
fn unique_paths(paths : Array[String]) -> Array[String] {
  let unique : Array[String] = []
  for path in paths {
    if !unique.contains(path) {
      unique.push(path)
    }
  }
  unique
}

///|
fn main {
  let args = parse_arguments(user_args(@env.args()))
  let federation_paths = unique_paths(args.paths)
  let code = if args.help {
    println(usage())
    0
  } else if (args.federation && args.federation_manifest) ||
    (args.federation && args.federation_diff) ||
    (args.federation_manifest && args.federation_diff) {
    println("error: choose only one federation mode")
    2
  } else if args.federation_diff {
    if args.paths.length() != 2 {
      println(
        "error: --federation-diff requires baseline and current manifest files",
      )
      println(usage())
      2
    } else {
      inspect_federation_diff(args.paths[0], args.paths[1], args.view)
    }
  } else if args.federation_manifest {
    if args.paths.length() != 1 {
      println("error: --federation-manifest requires exactly one manifest file")
      println(usage())
      2
    } else {
      inspect_federation_manifest(args.paths[0], args.view)
    }
  } else if args.federation {
    if federation_paths.length() < 2 {
      println("error: --federation requires at least two IFC files")
      println(usage())
      2
    } else {
      inspect_federation(federation_paths, args.view)
    }
  } else if args.paths.length() > 1 {
    println("error: expected at most one IFC file outside federation mode")
    println(usage())
    2
  } else {
    match args.paths.get(0) {
      Some(file) => {
        println("file: " + file)
        inspect_file(file, args.view)
      }
      None => {
        println("sample model (built-in)")
        inspect(sample(), args.view)
      }
    }
  }
  if code != 0 {
    @sys.exit(code)
  }
}
