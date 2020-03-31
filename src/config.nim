import os
import nap
import parsetoml
import strutils
import terminal
import sugar
import sequtils
import strformat

let version = "2.0.0"

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
  fluid2*: bool
  mix*: bool
  abc*: bool
  size*: bool
  date*: bool
  dirdate*: bool
  dirsize*: bool
  sizesort*: bool
  sizesort2*: bool
  dirsizesort*: bool
  datesort*: bool
  datesort2*: bool
  dirdatesort*: bool
  header*: bool
  permissions*: bool
  tree*: bool
  exclude*: seq[string]
  ignore_config*: bool
  max_width*: int
  output*: string
  ignore_dots*: bool
  reverse_sort*: bool
  snippets*: bool
  snippets_length*: int
  mix_files*: bool
  
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
  let fluid2 = use_arg(name="fluid2", kind="flag", help="Don't put linebreaks between sections but keep titles", alt="U")
  let mix = use_arg(name="mix", kind="flag", help="Mix and sort everything", alt="m")
  let abc = use_arg(name="abc", kind="flag", help="Categorize by letters", alt="@")
  let size = use_arg(name="size", kind="flag", help="Show the size of files", alt="z")
  let dirsize = use_arg(name="dirsize", kind="flag", help="Show the size of directories", alt="Z")
  let date = use_arg(name="date", kind="flag", help="Show the last modification date on files", alt="k")
  let dirdate = use_arg(name="dirdate", kind="flag", help="Show the last modification date on directories", alt="K")
  let sizesort = use_arg(name="sizesort", kind="flag", help="Sort files by size. Repeat, like '-ii', to semi-sort directories too", alt="i")
  let dirsizesort = use_arg(name="dirsizesort", kind="flag", help="Sort directories by size", alt="I")
  let datesort = use_arg(name="datesort", kind="flag", help="Sort files by modification date. Repeat, like '-dd', to semi-sort directories too", alt="d")
  let dirdatesort = use_arg(name="dirdatesort", kind="flag", help="Sort directories by modification date", alt="D")
  let header = use_arg(name="header", kind="flag", help="Show a header with some information", alt="h")
  let permissions = use_arg(name="permissions", kind="flag", help="Show posix permissions", alt="P")
  let tree = use_arg(name="tree", kind="flag", help="Show directories in a tree structure", alt="t")
  let exclude = use_arg(name="exclude", kind="value", multiple=true, help="Directories to exclude", alt="e")
  let max_width = use_arg(name="max-width", kind="value", help="Maximum horizontal size", alt="w")
  let ignore_config = use_arg(name="ignore-config", kind="flag", help="Don't read the config file", alt="!")
  let output = use_arg(name="output", kind="value", help="Path to a file to save the output", alt="o")
  let ignore_dots = use_arg(name="ignore-dots", kind="flag", help="Don't show dot dirs/files", alt="#")
  let reverse_sort = use_arg(name="reverse-sort", kind="flag", help="Reverse sorting", alt="R")
  let snippets = use_arg(name="snippets", kind="flag", help="Show text file snippets", alt="s")
  let snippets_length = use_arg(name="snippets-length", kind="value", help="Max length of snippets", alt="n")
  let mix_files = use_arg(name="mix-files", kind="flag", help="Mix files and executables", alt="M")
  
  # Presets
  let info = use_arg(name="info", kind="flag", help="Preset to show some information", alt="?")
  let allsizesort = use_arg(name="allsizesort", kind="flag", help="Sort files and directories by size", alt="9")
  let alldatesort = use_arg(name="alldatesort", kind="flag", help="Sort files and directories by date", alt="0")
  
  # Dev
  let dev = use_arg(name="dev", kind="flag", help="Used for development")

  add_header("List directories")
  add_header(&"Version: {version}")
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
    fluid2: fluid2.used,
    mix: mix.used,
    abc: abc.used,
    size: size.used,
    dirsize: dirsize.used,
    date: date.used,
    dirdate: dirdate.used,
    sizesort: sizesort.used,
    dirsizesort: dirsizesort.used,
    datesort: datesort.used,
    dirdatesort: dirdatesort.used,
    header: header.used,
    permissions: permissions.used,
    tree: tree.used,
    exclude: exclude.values,
    ignore_config: ignore_config.used,
    max_width: max_width.getInt(0),
    output: output.value,
    ignore_dots: ignore_dots.used,
    reverse_sort: reverse_sort.used,
    snippets: snippets.used,
    snippets_length: snippets_length.getInt(0),
    mix_files: mix_files.used,
  )
  
  if tree.used:
    oconf.list = true
    oconf.no_titles = true
    oconf.reverse = true
    oconf.abc = false
  
  if info.used:
    oconf.size = true
    oconf.dirsize = true
    oconf.date = true
    oconf.dirdate = true
  
  if allsizesort.used:
    oconf.sizesort = true
    oconf.dirsizesort = true
    
  if alldatesort.used:
    oconf.datesort = true
    oconf.dirdatesort = true
  
  if snippets.used:
    oconf.list = true
  
  oconf.sizesort2 = sizesort.used and sizesort.count >= 2
  oconf.datesort2 = datesort.used and datesort.count >= 2
  
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
  oconf.colors["dirs"] = @["blue"]
  oconf.colors["dirlinks"] = @["blue", "underscore"]
  oconf.colors["files"] = @[""]
  oconf.colors["filelinks"] = @["underscore"]
  oconf.colors["exefiles"] = @["bright"]
  oconf.colors["exefilelinks"] = @["bright", "underscore"]
  oconf.colors["abc"] = @["yellow"]
  oconf.colors["labels"] = @[""]
  oconf.colors["filtermatch"] = @[""]
  oconf.colors["pipes"] = @["cyan", "dim"]
  oconf.colors["details"] = @["cyan", "dim"]
  oconf.colors["snippets"] = @["green"]
  
  # CONFIG FILE 
  if oconf.ignore_config: return
  
  # Read and parse the file
  var tom: TomlValueRef
  var table: TomlTableRef

  try:
    tom = parsetoml.parseFile(getConfigDir().joinPath("lq/lq.conf"))
    table = tom.getTable()
  except: return

  # Get excludes
  try:
    let exs = table["exclude"]
    for i in 0..<exs.len:
      let e = exs[i].getStr()
      if not oconf.exclude.contains(e):
        oconf.exclude.add(e)
  except: discard
  
  # Other settings

  try:
    if oconf.max_width == 0:
      oconf.max_width = table["max-width"].getInt()
  except: discard

  try:
    if oconf.snippets_length == 0:
      oconf.snippets_length = table["snippets-length"].getInt()
  except: discard

  try:    
    if not oconf.no_titles:
      oconf.no_titles = table["no-titles"].getBool()
  except: discard

  try:
    if not oconf.header:
      oconf.header = table["header"].getBool()
  except: discard

  try:
    if not oconf.absolute:
      oconf.absolute = table["absolute"].getBool()
  except: discard

  try:
    if not oconf.mix_files:
      oconf.mix_files = table["mix-files"].getBool()
  except: discard
  
  # Get colors
  try:
    let colors = table["colors"]
    for key in oconf.colors.keys:
      try:
        let c = colors[key]
        oconf.colors[key] = c.getStr().split(" ")
          .map(s => s.strip())
      except: discard
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