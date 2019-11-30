import config
import utils
import os
import strformat
import strutils
import times

type QFile* = object
  kind*: PathComponent
  path*: string
  size*: int64
  date*: int64
  perms*: string

proc posix_perms*(info:FileInfo): string =
  result.add([pcFile: '-', 'l', pcDir: 'd', 'l'][info.kind])
  for i, fp in [fpUserRead, fpUserWrite, fpUserExec, fpGroupRead, fpGroupWrite,
    fpGroupExec, fpOthersRead, fpOthersWrite, fpOthersExec]:
      result.add(if fp in info.permissions: "rwx"[i mod 3] else: '-')

proc get_info*(path:string): FileInfo =
  try:
    return getFileInfo(path)
  except:
    return FileInfo()

proc calculate_dir*(path:string): QFile =
  var size: int64 = 0
  var date: int64 = 0
  var path = fix_path_2(path)
  for file in walkDirRec(&"{path}"):
    let info = get_info(file)
    size += info.size
    let d = info.lastWriteTime.toUnix()
    if d > date:
      date = d
  
  QFile(size:size, date:date)

proc format_perms*(perms:string): string = 
    &" ({perms})"

proc format_size*(file:QFile): string =
  if file.size == 0: return ""
  let fsize = float(file.size)
  let divider: float64 = 1024.0
  let kb: float64 = fsize / divider
  let mb: float64 = kb / divider
  let gb: float64 = mb / divider
  let size = if gb >= 1.0: &"{gb.formatFloat(ffDecimal, 1)} GB"
    elif mb >= 1.0: &"{mb.formatFloat(ffDecimal, 1)} MB"
    elif kb >= 1.0: &"{int(kb)} KB"
    else: &"{int(fsize)} B"
  return &" ({size})"

proc get_fg_color*(kind:PathComponent): string =
  case kind
  of pcDir: 
    let n = conf().dirscolor
    if n == -1: get_ansi("blue")
    else: get_8bit_fg_color(n)
  of pcLinkToDir: 
    let n = conf().dirlinkscolor
    if n == -1: get_ansi("cyan")
    else: get_8bit_fg_color(n)
  of pcFile:
    let n = conf().filescolor
    if n == -1: get_ansi("white")
    else: get_8bit_fg_color(n)
  of pcLinkToFile:
    let n = conf().filelinkscolor
    if n == -1: get_ansi("green")
    else: get_8bit_fg_color(n)

proc get_titles_color*(): string =
  let n = conf().titlescolor
  if n == -1: get_ansi("magenta")
  else: get_8bit_fg_color(n)

proc get_details_color*(): string =
  let n = conf().detailscolor
  if n == -1: ""
  else: get_8bit_fg_color(n)

proc get_labels_color*(): string =
  let n = conf().labelscolor
  if n == -1: get_ansi("white")
  else: get_8bit_fg_color(n)

proc get_count_color*(): string =
  let n = conf().countcolor
  if n == -1: get_ansi("white")
  else: get_8bit_fg_color(n)

proc get_header_color*(): string =
  let n = conf().headercolor
  if n == -1: get_ansi("white")
  else: get_8bit_fg_color(n)

proc get_prefix*(kind:PathComponent): string =
  case kind
  of pcDir: "[D] "
  of pcLinkToDir: "[d] "
  of pcFile: "[F] "
  of pcLinkToFile: "[f] "

proc get_level_space*(level:int): string =
  var levs = ""
  for x in 0..<level:
    levs.add("    ")
  return levs

proc print_title*(title:string, n:int) =
  if conf().no_titles: return
  var brk = "\n"
  let tcolor = get_titles_color()
  let scolor = get_count_color()
  log(&"{brk}{tcolor}{get_ansi(ansi_bright)}{title}{rstyle()} {scolor}({n}){rstyle()}")

proc format_item*(file:QFile, path:string, level:int): (string, int) =
  var scount = ""
  if conf().dircount:
    scount = case file.kind
    of pcDir, pcLinkToDir:
      var p = file.path
      if not file.path.startsWith("/"):
        p = path.joinPath(file.path)
      var ni = 0
      for item in walkDir(p):
        inc(ni)
      &" ({ni})"
    else: ""

  let color = if conf().no_colors: "" else: get_fg_color(file.kind)
  let dcolor = get_details_color()
  let scolor = get_count_color()
  let prefix = if conf().prefix: get_prefix(file.kind) else: ""
  let perms = if conf().permissions: format_perms(file.perms) else: ""
  let levs = get_level_space(level)
    
  let dosize = case file.kind
  of pcDir, pcLinkToDir:
    conf().dsize
  of pcFile, pcLinkToFile:
    conf().size
        
  let size = if dosize: format_size(file) else: ""
  let clen = prefix.len + file.path.len + size.len + scount.len + perms.len
  return (&"{color}{levs}{prefix}{file.path}{dcolor}{size}{perms}{scolor}{scount}", clen)