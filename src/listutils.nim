import config
import utils
import os
import strformat
import strutils
import times
import tables

type QFile* = object
  kind*: PathComponent
  path*: string
  size*: int64
  date*: int64
  perms*: string

# This stores file info to be recycled
# instead of it getting fetched again
var info_cache = initTable[string, FileInfo]()

proc get_info*(path:string): FileInfo =
  try:
    if info_cache.hasKey(path):
      return info_cache[path]
    else:
      let info = getFileInfo(path)
      info_cache.add(path, info)
      return info
  except:
    return FileInfo()

proc posix_perms*(info:FileInfo): string =
  result.add([pcFile: '-', 'l', pcDir: 'd', 'l'][info.kind])
  for i, fp in [fpUserRead, fpUserWrite, fpUserExec, fpGroupRead, fpGroupWrite,
    fpGroupExec, fpOthersRead, fpOthersWrite, fpOthersExec]:
      result.add(if fp in info.permissions: "rwx"[i mod 3] else: '-')    

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

proc get_kind_color*(kind:PathComponent): string =
  case kind
  of pcDir: 
    get_ansi(conf().dirscolor)
  of pcLinkToDir: 
    get_ansi(conf().dirlinkscolor)
  of pcFile:
    get_ansi(conf().filescolor)
  of pcLinkToFile:
    get_ansi(conf().filelinkscolor)

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

proc print_title*(title:string, n:int, level:int) =
  if conf().no_titles: return
  var brk = "\n"
  let c1 = get_ansi(conf().titlescolor)
  let c2 = get_ansi(conf().countcolor)
  log(&"{brk}{c1}{title}{reset()} {c2}({n})")

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

  let c1 = get_kind_color(file.kind)
  let c2 = get_ansi(conf().countcolor)
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
  let pth = if conf().absolute and level == 0: path.joinPath(file.path) else: file.path
  return (&"{c1}{levs}{prefix}{pth}{size}{perms}{c2}{scount}", clen)