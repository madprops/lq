import std/[os, strutils, sugar, sequtils, strformat, posix]
import pkg/parsetoml
import nap

let version = "3.0.0"

type Config* = ref object
  path*: string
  absolute*: bool
  filter*: string
  list*: bool
  prefix*: bool
  dircount*: bool
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
  reverse*: bool
  snippets*: bool
  snippets_length*: int
  mix_files*: bool
  
  # Set automatically
  piped*: bool

  # These get specified in the config file
  colors*: Table[string, seq[string]]

var
  oconf*: Config
  first_print* = false

proc check_config_file()
proc fix_path(path:string): string
proc fix_path_2(path:string): string

proc get_config*() =
  let
    path = add_arg(name="path", kind="argument", value="", help="Path to a directory")
    absolute = add_arg(name="absolute", kind="flag", help="Use absolute paths", alt="a")
    filter = add_arg(name="filter", kind="value", help="Filter the list.\nStart with re: to use regex.\nFor instance --filter=re:\\\\d+", alt="f")
    prefix = add_arg(name="prefix", kind="flag", help="Use prefixes like '[F]'", alt="p")
    list = add_arg(name="list", kind="flag", help="Show in a vertical list", alt="l")
    dircount = add_arg(name="count", kind="flag", help="Count items inside directories", alt="c")
    mix = add_arg(name="mix", kind="flag", help="Mix and sort everything", alt="m")
    abc = add_arg(name="abc", kind="flag", help="Categorize by letters", alt="@")
    size = add_arg(name="size", kind="flag", help="Show the size of files", alt="z")
    dirsize = add_arg(name="dirsize", kind="flag", help="Show the size of directories", alt="Z")
    date = add_arg(name="date", kind="flag", help="Show the last modification date on files", alt="k")
    dirdate = add_arg(name="dirdate", kind="flag", help="Show the last modification date on directories", alt="K")
    sizesort = add_arg(name="sizesort", kind="flag", help="Sort files by size. Repeat, like '-ii', to semi-sort directories too", alt="i")
    dirsizesort = add_arg(name="dirsizesort", kind="flag", help="Sort directories by size", alt="I")
    datesort = add_arg(name="datesort", kind="flag", help="Sort files by modification date. Repeat, like '-dd', to semi-sort directories too", alt="d")
    dirdatesort = add_arg(name="dirdatesort", kind="flag", help="Sort directories by modification date", alt="D")
    header = add_arg(name="header", kind="flag", help="Show a header with some information", alt="h")
    permissions = add_arg(name="permissions", kind="flag", help="Show posix permissions", alt="P")
    tree = add_arg(name="tree", kind="flag", help="Show directories in a tree structure", alt="t")
    exclude = add_arg(name="exclude", kind="value", multiple=true, help="Directories to exclude", alt="e")
    max_width = add_arg(name="max-width", kind="value", value="0", help="Maximum horizontal size", alt="w")
    ignore_config = add_arg(name="ignore-config", kind="flag", help="Don't read the config file", alt="!")
    output = add_arg(name="output", kind="value", help="Path to a file to save the output", alt="o")
    ignore_dots = add_arg(name="ignore-dots", kind="flag", help="Don't show dot dirs/files", alt="#")
    reverse = add_arg(name="reverse-sort", kind="flag", help="Reverse sorting", alt="r")
    snippets = add_arg(name="snippets", kind="flag", help="Show text file snippets", alt="s")
    snippets_length = add_arg(name="snippets-length", kind="value", value="0", help="Max length of snippets", alt="n")
    mix_files = add_arg(name="mix-files", kind="flag", help="Mix files and executables", alt="M")
  
    # Presets
    info = add_arg(name="info", kind="flag", help="Preset to show some information", alt="?")
    allsizesort = add_arg(name="allsizesort", kind="flag", help="Sort files and directories by size", alt="9")
    alldatesort = add_arg(name="alldatesort", kind="flag", help="Sort files and directories by date", alt="0")

  add_header("List directories")
  add_header(&"Version: {version}")
  add_note("A config file should be in ~/.config/lq")
  add_note("Git Repo: https://github.com/madprops/lq")

  parse_args()

  var st: posix.Stat
  discard posix.fstat(0, st)

  oconf = Config(
    piped: st.st_mode.S_ISFIFO(),
    path: path.value,
    absolute: absolute.used,
    filter: filter.value,
    list: list.used,
    prefix: prefix.used,
    dircount: dircount.used,
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
    max_width: max_width.getInt(),
    output: output.value,
    ignore_dots: ignore_dots.used,
    reverse: reverse.used,
    snippets: snippets.used,
    snippets_length: snippets_length.getInt(),
    mix_files: mix_files.used,
  )
  
  if tree.used:
    oconf.list = true
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
  var
    tom: TomlValueRef
    table: TomlTableRef

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
    path = getCurrentDir().joinPath(path)
  normalizePath(path)
  return path

proc fix_path_2(path:string): string =
  var path = expandTilde(path)
  if not path.startsWith("/"):
    path = fix_path(oconf.path).joinPath(path)
  normalizePath(path)
  return path