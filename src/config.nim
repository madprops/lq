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

var oconf*: Config

proc get_config*() =
  let path = use_arg(name="path", kind="argument", help="Path to a directory")
  let just_dirs = use_arg(name="dirs", kind="flag", help="Just show directories")
  let just_files = use_arg(name="files", kind="flag", help="Just show files")
  let absolute = use_arg(name="absolute", kind="flag", help="Use absolute paths")
  let no_colors = use_arg(name="no-colors", kind="flag", help="Don't color paths")
  let filter = use_arg(name="filter", kind="value", help="Filter the list")
  let dev = use_arg(name="dev", kind="flag", help="Used for development")
  let prefix = use_arg(name="prefix", kind="flag", help="Use prefixes like '[F]'")
  let list = use_arg(name="list", kind="flag", help="Show in a vertical list")
  let dircount = use_arg(name="count", kind="flag", help="Count items inside directories")
  let no_titles = use_arg(name="no-titles", kind="flag", help="Don't show titles like 'Files'")
  let reverse = use_arg(name="reverse", kind="flag", help="Put files above directories")
  
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
  )

proc conf*(): Config =
  return oconf