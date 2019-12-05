import os
import nap
import parsetoml
import strutils
import terminal
import sugar
import sequtils

type Config* = ref object
  path*: string
  just_dirs*: bool
  just_files*: bool
  just_execs*: bool
  absolute*: bool
  filter*: string
  dev*: bool
  list*: bool
  prefix*: bool
  dircount*: bool
  no_titles*: bool
  reverse*: bool
  fluid*: bool
  mix*: bool
  abc*: bool
  size*: bool
  dsize*: bool
  sizesort*: bool
  datesort*: bool
  header*: bool
  permissions*: bool
  tree*: bool
  exclude*: seq[string]
  ignore_config*: bool
  max_width*: int
  output*: string
  ignore_dots*: bool

  # Set automatically
  piped*: bool

  # These get specified in the config file
  colors*: Table[string, seq[string]]

var oconf*: Config
var first_print* = false

proc check_config_file()
proc fix_path(path:string): string
proc fix_path_2(path:string): string

proc get_config*() =
  let path = use_arg(name="path", kind="argument", value="", help="Path to a directory")
  let just_dirs = use_arg(name="dirs", kind="flag", help="Just show directories", alt="1")
  let just_files = use_arg(name="files", kind="flag", help="Just show files", alt="2")
  let just_execs = use_arg(name="execs", kind="flag", help="Just show executables", alt="3")
  let absolute = use_arg(name="absolute", kind="flag", help="Use absolute paths", alt="a")
  let filter = use_arg(name="filter", kind="value", help="Filter the list.\nStart with re: to use regex.\nFor instance --filter=re:\\\\d+", alt="f")
  let prefix = use_arg(name="prefix", kind="flag", help="Use prefixes like '[F]'", alt="p")
  let list = use_arg(name="list", kind="flag", help="Show in a vertical list", alt="l")
  let dircount = use_arg(name="count", kind="flag", help="Count items inside directories", alt="c")
  let no_titles = use_arg(name="no-titles", kind="flag", help="Don't show titles like 'Files'", alt="x")
  let reverse = use_arg(name="reverse", kind="flag", help="Put files above directories", alt="r")
  let fluid = use_arg(name="fluid", kind="flag", help="Don't put linebreaks between sections", alt="u")
  let mix = use_arg(name="mix", kind="flag", help="Mix and sort everything", alt="m")
  let abc = use_arg(name="abc", kind="flag", help="Categorize by letters", alt="@")
  let size = use_arg(name="size", kind="flag", help="Show the size of files", alt="z")
  let dsize = use_arg(name="dsize", kind="flag", help="Show the size directories", alt="D")
  let sizesort = use_arg(name="sizesort", kind="flag", help="Sort by file size", alt="i")
  let datesort = use_arg(name="datesort", kind="flag", help="Sort by file modification date", alt="d")
  let header = use_arg(name="header", kind="flag", help="Show a header with some information", alt="h")
  let permissions = use_arg(name="permissions", kind="flag", help="Show posix permissions", alt="P")
  let tree = use_arg(name="tree", kind="flag", help="Show directories in a tree structure", alt="t")
  let exclude = use_arg(name="exclude", kind="value", multiple=true, help="Directories to exclude", alt="e")
  let max_width = use_arg(name="max-width", kind="value", help="Maximum horizontal size", alt="w")
  let ignore_config = use_arg(name="ignore-config", kind="flag", help="Don't read the config file", alt="!")
  let output = use_arg(name="output", kind="value", help="Path to a file to save the output", alt="o")
  let ignore_dots = use_arg(name="ignore-dots", kind="flag", help="Don't show dot dirs/files", alt="#")
  
  # Presets
  let salad = use_arg(name="salad", kind="flag", help="Preset to mix all", alt="s")
  let blender = use_arg(name="blender", kind="flag", help="Preset to really mix all", alt="b")
  
  # Dev
  let dev = use_arg(name="dev", kind="flag", help="Used for development")

  add_header("List directories")
  add_note("A config file should be in ~/.config/lq")
  add_note("Git Repo: https://github.com/madprops/lq")

  parse_args()

  oconf = Config(
    piped: not isatty(stdout),
    path: path.value,
    just_dirs: just_dirs.used, 
    just_files: just_files.used,
    just_execs: just_execs.used,
    absolute: absolute.used,
    filter: filter.value,
    dev: dev.used,
    list: list.used,
    prefix: prefix.used,
    dircount: dircount.used,
    no_titles: no_titles.used,
    reverse: reverse.used,
    fluid: fluid.used,
    mix: mix.used,
    abc: abc.used,
    size: size.used,
    sizesort: sizesort.used,
    datesort: datesort.used,
    header: header.used,
    permissions: permissions.used,
    dsize: dsize.used,
    tree: tree.used,
    exclude: exclude.values,
    ignore_config: ignore_config.used,
    max_width: max_width.getInt(0),
    output: output.value,
    ignore_dots: ignore_dots.used,
  )

  if salad.used:
    oconf.no_titles = true
    oconf.fluid = true
  
  elif blender.used:
    oconf.no_titles = true
    oconf.fluid = true
    oconf.mix = true
  
  if tree.used:
    oconf.list = true
    oconf.no_titles = true
    oconf.reverse = true
    oconf.abc = false
  
  check_config_file()

proc conf*(): Config =
  return oconf

proc check_config_file() =
  # Path
  oconf.path = fix_path(oconf.path)

  # Output
  if oconf.output != "":
    oconf.output = fix_path_2(oconf.output)
    if not dirExists(oconf.output.parentDir()):
      echo "Invalid output path."
      quit(0)  
  
  # Default colors
  oconf.colors = initTable[string, seq[string]]()
  oconf.colors["header"] = @["bright"]
  oconf.colors["titles"] = @["green", "bright"]
  oconf.colors["dirs"] = @["blue", "bright"]
  oconf.colors["dirlinks"] = @["cyan"]
  oconf.colors["files"] = @[""]
  oconf.colors["exefiles"] = @[""]
  oconf.colors["filelinks"] = @["green"]
  oconf.colors["exefilelinks"] = @["green"]
  oconf.colors["abc"] = @["yellow"]
  oconf.colors["labels"] = @[""]
  oconf.colors["filtermatch"] = @[""]
  oconf.colors["pipes"] = @["cyan", "dim"]
  oconf.colors["details"] = @["green", "dim"]
  
  # CONFIG FILE 
  if oconf.ignore_config: return
  
  # Read and parse the file
  let tom = parsetoml.parseFile(getConfigDir().joinPath("lq/lq.conf"))
  let table = tom.getTable()
  
  # Get excludes
  let exs = table["exclude"]
  for i in 0..<exs.len:
    let e = exs[i].getStr()
    if not oconf.exclude.contains(e):
      oconf.exclude.add(e)
  
  # Get colors
  let colors = table["colors"]
  for key in oconf.colors.keys:
    try:
      let c = colors[key]
      oconf.colors[key] = c.getStr().split(" ")
        .map(s => s.strip())
    except: discard

proc fix_path(path:string): string =
  var path = expandTilde(path)
  if not path.startsWith("/"):
    path = if oconf.dev:
      getCurrentDir().parentDir().joinPath(path)
      else: getCurrentDir().joinPath(path)
  normalizePath(path)
  return path

proc fix_path_2(path:string): string =
  var path = expandTilde(path)
  if not path.startsWith("/"):
    path = fix_path(oconf.path).joinPath(path)
  normalizePath(path)
  return path