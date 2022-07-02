import std/[os, strformat, strutils, times, tables, sugar, sequtils]
import config
import utils

type QFile* = object
  kind*: PathComponent
  path*: string
  size*: int64
  date*: int64
  perms*: string
  exe*: bool

var
  # Used to create spaces on levels
  levspace* = "    "
  levspace_2* = "\\s\\s\\s\\s"
  levlines* = initTable[int, bool]()
  rightnow* = getTime().toUnix()

  # This stores file info to be recycled
  # instead of it getting fetched again
  info_cache = initTable[string, FileInfo]()

proc get_info*(path:string, canfail=false): FileInfo =
  try:
    if info_cache.hasKey(path):
      return info_cache[path]
    else:
      let info = getFileInfo(path)
      info_cache[path] = info
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
  let info = get_info(path)

  var
    size: int64 = 0
    date: int64 = 0
    path = fix_path_2(path)

  for file in walkDirRec(&"{path}"):
    let info2 = get_info(file)
    size += info2.size
    let d = info2.lastWriteTime.toUnix()
    if d > date:
      date = d
  
  date = max(date, info.lastWriteTime.toUnix())
  QFile(size:size, date:date)

proc format_perms*(perms:string): string = 
    &" ({perms})"

proc format_size*(size: int64): string =
  if size == 0: return " (Empty)"

  let
    fsize = float(size)
    divider: float64 = 1024.0
    kb: float64 = fsize / divider
    mb: float64 = kb / divider
    gb: float64 = mb / divider
    size = if gb >= 1.0: &"{gb.formatFloat(ffDecimal, 1)} GB"
      elif mb >= 1.0: &"{mb.formatFloat(ffDecimal, 1)} MB"
      elif kb >= 1.0: &"{int(kb)} KB"
      else: &"{int(fsize)} B"

  return &" ({size})"

proc format_date*(date:int64): string =
  let days = int( float( rightnow - date ) / 3600.0 / 24.0 )
  if days == 0:
    return " (Today)"
  if days < 365:
    if days == 1:
      return &" ({days} day)"
    else:
      return &" ({days} days)"
  else:
    let years = int( float(days) / 365.0 )
    if years == 1:
      return &" ({years} year)"
    else:
      return &" ({years} years)"

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

proc format_item*(file=QFile(), path="", level=0, index=0, len=0, last=false, label="", is_snippet=false): (string, int) =
  var
    scount = ""
    is_label = label != ""
    full_path = path.joinPath(file.path)

  if path != "" and conf().dircount:
    scount = case file.kind
    of pcDir, pcLinkToDir:
      var ni = 0
      for item in walkDir(full_path):
        inc(ni)
      &" ({ni})"
    else: ""

  var c1 = get_kind_color(file.kind)

  if is_snippet: c1 = get_ansi(conf().colors["snippets"])
  elif is_label: c1 = get_ansi(conf().colors["labels"])
  else:
    if file.kind == pcFile or file.kind == pcLinkToFile:
      if file.exe:
        if file.kind == pcFile:
          c1 = get_ansi(conf().colors["exefiles"])
        if file.kind == pcLinkToFile:
          c1 = get_ansi(conf().colors["exefilelinks"])

  var
    c2 = ""
    prefix = ""
    perms = ""
    pipe = ""
    levs = ""
  
  if path != "":
    c2 = get_ansi(conf().colors["details"])
    prefix = if conf().prefix: get_prefix(file) else: ""
    perms = if conf().permissions: format_perms(file.perms) else: ""
    levlines[level] = last and index == (len - 1)

  if conf().tree and level > 0:
    levs = get_ansi(conf().colors["pipes"])

    for lvl in 1..<level:
      if levlines[lvl]:
        levs.add(levspace)
      else:
        levs.add("│   ")
    
    if not is_snippet:
      pipe = if is_label: "└── "
      elif index == (len - 1):
        if last: "└── "
        else: "├── "
      else: "├── "
    else: pipe = ""

    levs.add(pipe)
    levs.add(reset())
  else:
    levs = get_level_space(level)

  let dosize = path != "" and (case file.kind
  of pcDir, pcLinkToDir:
    conf().dirsize
  of pcFile, pcLinkToFile:
    conf().size)

  let dodate = path != "" and (case file.kind
  of pcDir, pcLinkToDir:
    conf().dirdate
  of pcFile, pcLinkToFile:
    conf().date)
  
  let
    size = if dosize: format_size(file.size) else: ""
    date = if dodate: format_date(file.date) else: ""

  var path2 = if is_label: label

  elif conf().absolute: full_path else: file.path
  let clen = prefix.len + path2.len + size.len + date.len + scount.len + perms.len

  if conf().filter != "" and conf().colors["filtermatch"].filter(x => x.len > 0).len > 0:
    let i = path2.find(conf().filter)
    if i != -1:
      let cm = get_ansi(conf().colors["filtermatch"])
      path2 = &"{path2.substr(0, i - 1)}{cm}{path2.substr(i, i + conf().filter.len - 1)}" &
        &"{reset()}{path2.substr(i + conf().filter.len, path2.len - 1)}"
  
  let s = &"{levs}{c1}{c2}{prefix}{reset()}{c1}{path2}{reset()}{c2}{size}{date}{perms}{scount}{reset()}"
  return (s, clen)

proc show_label*(msg:string, level:int, is_snippet=false) =
  let msg2 = if is_snippet: &"  {msg}" else: msg
  log format_item(label=msg2, level=level, is_snippet=is_snippet)[0]

proc has_snippet*(file:QFile): bool =
  conf().snippets and (file.kind == pcFile or file.kind == pcLinkToFile)

proc show_snippet*(full_path:string, size:int64, level:int) =
  try:
    var len = conf().snippets_length
    if len == 0: len = 300
    let blen = min(size, max(512, len))
    if blen == 0: return
    let f = open(full_path)

    var bytes: seq[uint8]
    for x in 0..<blen:
      bytes.add(0)

    discard f.readBytes(bytes, 0, blen)
    f.close()

    # Check if it's a binary file
    for c in bytes:
      if c == 0: return
    
    let sample = cast[string](bytes).substr(0, len - 1)
    
    # Apply some filters
    let lines = sample.splitLines()
    .filter(line => line.strip() != "")
    
    # Print each line
    for line in lines:
      show_label(line, level, true)
  except:
    discard