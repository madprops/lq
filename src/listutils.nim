import config
import utils
import os
import strformat
import strutils
import times
import tables
import sugar
import sequtils

type QFile* = object
  kind*: PathComponent
  path*: string
  size*: int64
  date*: int64
  perms*: string
  exe*: bool

# Used to create spaces on levels
var levspace* = "    "
var levspace_2* = "\\s\\s\\s\\s"
var levlines* = initTable[int, bool]()
var rightnow* = getTime().toUnix()

# This stores file info to be recycled
# instead of it getting fetched again
var info_cache = initTable[string, FileInfo]()

proc get_info*(path:string, canfail=false): FileInfo =
  try:
    if info_cache.hasKey(path):
      return info_cache[path]
    else:
      let info = getFileInfo(path)
      info_cache.add(path, info)
      return info
  except:
    if canfail:
      log(&"Error: Can't read '{path}'")
      quit(0)
    else:
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

proc format_size*(size: int64): string =
  let fsize = float(size)
  let divider: float64 = 1024.0
  let kb: float64 = fsize / divider
  let mb: float64 = kb / divider
  let gb: float64 = mb / divider
  let size = if gb >= 1.0: &"{gb.formatFloat(ffDecimal, 1)} GB"
    elif mb >= 1.0: &"{mb.formatFloat(ffDecimal, 1)} MB"
    elif kb >= 1.0: &"{int(kb)} KB"
    else: &"{int(fsize)} B"
  return &" ({size})"

proc format_date*(date:int64): string =
  let days = int( float( rightnow - date ) / 3600.0 / 24.0 )
  if days == 0:
    return " (Today)"
  if days == 1:
    return &" ({days} day)"
  else:
    return &" ({days} days)"

proc get_kind_color*(kind:PathComponent): string =
  case kind
  of pcDir: 
    get_ansi(conf().colors["dirs"])
  of pcLinkToDir: 
    get_ansi(conf().colors["dirlinks"])
  of pcFile:
    get_ansi(conf().colors["files"])
  of pcLinkToFile:
    get_ansi(conf().colors["filelinks"])

proc get_prefix*(file:QFile): string =
  case file.kind
  of pcDir: "[D] "
  of pcLinkToDir: "[d] "
  of pcFile: 
    if file.exe: "[E] " else: "[F] "
  of pcLinkToFile: 
    if file.exe: "[e] " else: "[f] "

proc get_level_space*(level:int): string =
  var levs = ""
  for x in 0..<level:
    levs.add(levspace)
  return levs

proc format_item*(file=QFile(), path="", level=0, index=0, len=0, last=false, label=""): (string, int) =
  var scount = ""
  var is_label = label != ""
  var full_path = path.joinPath(file.path)

  if not is_label and conf().dircount:
    scount = case file.kind
    of pcDir, pcLinkToDir:
      var ni = 0
      for item in walkDir(full_path):
        inc(ni)
      &" ({ni})"
    else: ""

  var c1 = get_kind_color(file.kind)
  
  if is_label: c1 = get_ansi(conf().colors["labels"]) else:
    if file.kind == pcFile or file.kind == pcLinkToFile:
      if file.exe:
        if file.kind == pcFile:
          c1 = get_ansi(conf().colors["exefiles"])
        if file.kind == pcLinkToFile:
          c1 = get_ansi(conf().colors["exefilelinks"])

  var c2 = ""
  var prefix = ""
  var perms = ""
  
  if not is_label:
    c2 = get_ansi(conf().colors["details"])
    prefix = if conf().prefix: get_prefix(file) else: ""
    perms = if conf().permissions: format_perms(file.perms) else: ""
    levlines[level] = last and index == (len - 1)

  var levs = ""

  if conf().tree and level > 0:
    levs = get_ansi(conf().colors["pipes"])

    for lvl in 1..<level:
      if levlines[lvl]:
        levs.add(levspace)
      else:
        levs.add("│   ")

    let icon = if is_label: "└── "
    elif index == (len - 1):
      if last: "└── "
      else: "├── "
    else: "├── "

    levs.add(icon)
    levs.add(reset())
  else:
    levs = get_level_space(level)

  let dosize = case file.kind
  of pcDir, pcLinkToDir:
    conf().dirsize
  of pcFile, pcLinkToFile:
    conf().size

  let dodate = case file.kind
  of pcDir, pcLinkToDir:
    conf().dirdate
  of pcFile, pcLinkToFile:
    conf().date
        
  let size = if dosize: format_size(file.size) else: ""
  let date = if dodate: format_date(file.date) else: ""
  var pth = if is_label: label
  elif conf().absolute: full_path else: file.path
  let clen = prefix.len + pth.len + size.len + date.len + scount.len + perms.len

  if conf().filter != "" and conf().colors["filtermatch"].filter(x => x.len > 0).len > 0:
    let lc = pth.toLower()
    let f = conf().filter.toLower()
    let i = lc.find(f)
    if i != -1:
      let cm = get_ansi(conf().colors["filtermatch"])
      pth = &"{pth.substr(0, i - 1)}{cm}{pth.substr(i, i + f.len - 1)}" &
        &"{reset()}{pth.substr(i + f.len, pth.len - 1)}"
  
  let s = &"{levs}{c1}{c2}{prefix}{reset()}{c1}{pth}{reset()}{c2}{size}{date}{perms}{scount}{reset()}"
  return (s, clen)

proc show_label*(msg:string, level:int) =
  log format_item(label=msg, level=level)[0]