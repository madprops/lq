import os
import nap
import parsetoml
import strformat

type Config* = ref object
  path*: string
  just_dirs*: bool
  just_files*: bool
  absolute*: bool
  no_colors*: bool
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

  # These get specified 
  # in the config file
  dirscolor*: int
  dirlinkscolor*: int
  filescolor*: int
  filelinkscolor*: int
  abccolor*: int
  titlescolor*: int
  headercolor*: int
  backgroundcolor*: int
  detailscolor*: int
  countcolor*: int
  labelscolor*: int

  # Auto generated
  bg_color_code*: string

var oconf*: Config
var first_print* = false

proc get_config*() =
  let path = use_arg(name="path", kind="argument", help="Path to a directory")
  let just_dirs = use_arg(name="dirs", kind="flag", help="Just show directories", alt="1")
  let just_files = use_arg(name="files", kind="flag", help="Just show files", alt="2")
  let absolute = use_arg(name="absolute", kind="flag", help="Use absolute paths", alt="a")
  let no_colors = use_arg(name="no-colors", kind="flag", help="Don't color paths", alt="X")
  let filter = use_arg(name="filter", kind="value", help="Filter the list.\nStart with re: to use regex.\nFor instance --filter=re:\\\\d+", alt="f")
  let prefix = use_arg(name="prefix", kind="flag", help="Use prefixes like '[F]'", alt="p")
  let list = use_arg(name="list", kind="flag", help="Show in a vertical list", alt="l")
  let dircount = use_arg(name="count", kind="flag", help="Count items inside directories", alt="c")
  let no_titles = use_arg(name="no-titles", kind="flag", help="Don't show titles like 'Files'", alt="o")
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
  
  # Presets
  let salad = use_arg(name="salad", kind="flag", help="Preset to mix all", alt="s")
  let blender = use_arg(name="blender", kind="flag", help="Preset to really mix all", alt="b")
  
  # Dev
  let dev = use_arg(name="dev", kind="flag", help="Used for development")

  add_header("List directories")
  parse_args()
  
  oconf = Config(
    path:path.value, 
    just_dirs:just_dirs.used, 
    just_files:just_files.used,
    absolute:absolute.used,
    no_colors:no_colors.used,
    filter:filter.value,
    dev:dev.used,
    list:list.used,
    prefix:prefix.used,
    dircount:dircount.used,
    no_titles:no_titles.used,
    reverse:reverse.used,
    fluid:fluid.used,
    mix:mix.used,
    abc:abc.used,
    size:size.used,
    sizesort:sizesort.used,
    datesort:datesort.used,
    header:header.used,
    permissions:permissions.used,
    dsize:dsize.used,
    tree:tree.used,
    exclude:exclude.values,
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
  
  # Check config file
  let tom = parsetoml.parseFile(getConfigDir().joinPath("lq/lq.conf"))
  let table = tom.getTable()
  let exs = table["exclude"]

  for i in 0..<exs.len:
    let e = exs[i].getStr()
    if not oconf.exclude.contains(e):
      oconf.exclude.add(e)
  
  let colors = table["colors"]

  try:
    let c = colors["dirs"]
    oconf.dirscolor = c.getInt()
  except:
    oconf.dirscolor = -1

  try:
    let c = colors["dirlinks"]
    oconf.dirlinkscolor = c.getInt()
  except:
    oconf.dirlinkscolor = -1

  try:
    let c = colors["files"]
    oconf.filescolor = c.getInt()
  except:
    oconf.filescolor = -1

  try:
    let c = colors["filelinks"]
    oconf.filelinkscolor = c.getInt()
  except:
    oconf.filelinkscolor = -1

  try:
    let c = colors["abc"]
    oconf.abccolor = c.getInt()
  except:
    oconf.abccolor = -1

  try:
    let c = colors["titles"]
    oconf.titlescolor = c.getInt()
  except:
    oconf.titlescolor = -1

  try:
    let c = colors["header"]
    oconf.headercolor = c.getInt()
  except:
    oconf.headercolor = -1

  try:
    let c = colors["lables"]
    oconf.labelscolor = c.getInt()
  except:
    oconf.labelscolor = -1

  try:
    let c = colors["background"]
    oconf.backgroundcolor = c.getInt()
    oconf.bg_color_code = &"\x1b[48;5;{c.getInt()}m"
  except:
    oconf.backgroundcolor = -1
    oconf.bg_color_code = ""

  try:
    let c = colors["details"]
    oconf.detailscolor = c.getInt()
  except:
    oconf.detailscolor = -1

  try:
    let c = colors["count"]
    oconf.countcolor = c.getInt()
  except:
    oconf.countcolor = -1

proc conf*(): Config =
  return oconf