import nap

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
  no_spacing*: bool
  fluid*: bool
  mix*: bool
  abc*: bool
  size*: bool
  sizesort*: bool
  datesort*: bool
  header*: bool
  permissions*: bool

var oconf*: Config

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
  let no_spacing = use_arg(name="no-spacing", kind="flag", help="Make it less comfy", alt="x")
  let fluid = use_arg(name="fluid", kind="flag", help="Don't put linebreaks between sections", alt="u")
  let mix = use_arg(name="mix", kind="flag", help="Mix and sort everything", alt="m")
  let abc = use_arg(name="abc", kind="flag", help="Categorize by letters", alt="@")
  let size = use_arg(name="size", kind="flag", help="Show the size of files", alt="z")
  let sizesort = use_arg(name="sizesort", kind="flag", help="Sort by file size", alt="i")
  let datesort = use_arg(name="datesort", kind="flag", help="Sort by file modification date", alt="d")
  let header = use_arg(name="header", kind="flag", help="Show a header with some information", alt="h")
  let permissions = use_arg(name="permissions", kind="flag", help="Show posix permissions", alt="P")
  
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
    no_spacing:no_spacing.used,
    fluid:fluid.used,
    mix:mix.used,
    abc:abc.used,
    size:size.used,
    sizesort:sizesort.used,
    datesort:datesort.used,
    header:header.used,
    permissions:permissions.used
  )

  if salad.used:
    oconf.no_titles = true
    oconf.fluid = true
  
  elif blender.used:
    oconf.no_titles = true
    oconf.fluid = true
    oconf.mix = true

proc conf*(): Config =
  return oconf