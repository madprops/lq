import utils
import config
import os
import nre
import strformat
import strutils
import algorithm
import terminal
import times

type QFile = object
  kind: PathComponent
  path: string
  size: int64
  date: int64
  perms: string

proc posix_perms(info:FileInfo): string =
  result.add([pcFile: '-', 'l', pcDir: 'd', 'l'][info.kind])
  for i, fp in [fpUserRead, fpUserWrite, fpUserExec, fpGroupRead, fpGroupWrite,
    fpGroupExec, fpOthersRead, fpOthersWrite, fpOthersExec]:
      result.add(if fp in info.permissions: "rwx"[i mod 3] else: '-')

proc get_info(path:string): FileInfo =
  try:
    var path = fix_path_2(path)
    return getFileInfo(path)
  except:
    return FileInfo()

proc format_perms(perms:string): string = 
    &" ({perms})"

proc format_file_size(file:QFile): string =
  case file.kind
  of pcFile, pcLinkToFile:
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
  else: return ""

proc get_color(kind:PathComponent): string =
  case kind
  of pcDir: get_ansi("blue")
  of pcLinkToDir: get_ansi("cyan")
  of pcFile: ""
  of pcLinkToFile: get_ansi("green")

proc get_prefix(kind:PathComponent): string =
  case kind
  of pcDir: "[D] "
  of pcLinkToDir: "[d] "
  of pcFile: "[F] "
  of pcLinkToFile: "[f] "

proc show_files*(files:seq[QFile]) =
  var slen = 0
  let termwidth = terminalWidth()
  var sline = if conf().no_spacing: "" else: "\n  "
  var xp = if conf().no_spacing: 1 else: 2
  var sp = ""
  for x in 0..(xp - 1):
    sp.add(" ")
  let limit = if conf().no_spacing: termwidth else: (termwidth - 4)
  let abc = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
  let use_abc = conf().abc and not conf().mix
  var abci = -1
  var used_abci = -1
  var abc_started = false

  proc format_item(file:QFile): (string, int) =
    var scount = ""
    if conf().dircount:
      scount = case file.kind
      of pcDir, pcLinkToDir:
        var p = file.path
        if not file.path.startsWith("/"):
          p = conf().path.joinPath(file.path)
        var ni = 0
        for item in walkDir(p):
          inc(ni)
        &" ({ni})"
      else: ""

    let color = if conf().no_colors: "" else: get_color(file.kind)
    var prefix = if conf().prefix: get_prefix(file.kind) else: ""
    var size = if conf().size: format_file_size(file) else: ""
    var perms = if conf().permissions: format_perms(file.perms) else: ""
    
    let clen = prefix.len + file.path.len + size.len + scount.len + perms.len
    return (&"{color}{prefix}{file.path}{size}{perms}{get_ansi(ansi_reset)}{scount}", clen)

  proc space_item(s:string): string =
    return &"{s}{sp}"
  
  proc format_abc(c:char): string =
    &"{get_ansi(ansi_yellow)}{$c}{get_ansi(ansi_reset)}"
  
  proc print_abc() =
    if abci != -1:
      if abci == used_abci:
        return
      else: used_abci = abci
    let c = if abci > -1:
      abc[abci]
    else: '@'

    let sp = if conf().no_spacing: ""
      else: "  "

    log &"{sp}{format_abc(c)}"
  
  proc print_line() =
    if use_abc and abc_started and not conf().fluid:
      print_abc()

    log sline.strip(leading=false, trailing=true)
    sline = if conf().no_spacing: "" else: "\n  "
    slen = 0
  
  proc add_to_line(s:string, clen:int) =
    sline.add(space_item(s))
    slen += clen + xp

  for file in files:
    let fmt = format_item(file)
    let s = fmt[0]
    let clen = fmt[1]

    if use_abc:
      let sc = file.path[0].toLowerAscii()
      let ib = abc.find(sc)
      if ib == -1:
        if not abc_started:
          if not conf().no_spacing: log ""
          abc_started = true
      else:
        if ib != abci:
          # On letter change
          abc_started = true
          
          if conf().fluid:
            let cs = &"{$format_abc(abc[ib])}{sp}"
            sline.add(cs)
            slen += cs.len
          else:
            if slen > 0:
              print_line()
            if not conf().no_spacing:
              log ""

          abci = ib

    if not conf().list:
      let tots = slen + clen
      # Add to line
      if tots <= limit:
        add_to_line(s, clen)
      if tots == limit:
        print_line()
      # Line overflow
      elif tots > limit:
        print_line()
        add_to_line(s, clen)
    # List item
    else: log s
      
  if slen > 0:
    print_line()

proc list_dir*() =
  conf().path = fix_path(conf().path)
  var dirs: seq[QFile]
  var dirlinks: seq[QFile]
  var files: seq[QFile]
  var filelinks: seq[QFile]
  let do_filter = conf().filter != ""
  let do_regex_filter = conf().filter.startsWith("re:")
  var filter = ""
  var res: Regex
  if do_regex_filter:
    res = re(conf().filter.replace(re"^re\:", ""))
  else: filter = conf().filter.toLower()

  let info = getFileInfo(conf().path)

  if info.kind == pcFile or
  info.kind == pcLinkToFile:
    let size = info.size
    let date = info.lastWriteTime.toUnix()
    let perms = posix_perms(info)
    let qf = QFile(kind:info.kind, path:conf().path, size:size, date:date, perms:perms)
    if info.kind == pcFile:
      files.add(qf)
    else:
      filelinks.add(qf)
    conf().prefix = true
    conf().size = true
    conf().no_titles = true
    conf().permissions = true

  else: # If it's a directory check every file in it
    for file in walkDir(conf().path, relative=(not conf().absolute)):
      # Filter
      if do_filter:
        if do_regex_filter:
          let m = file.path.find(res)
          if m.isNone: continue
        else:
          if not file.path.toLower().contains(filter):
            continue

      # Add to proper list
      case file.kind

      # If directory
      of pcDir, pcLinkToDir:
        var size: int64 = 0
        var date: int64 = 0
        var perms = ""
        if conf().datesort or conf().permissions:
          let info = get_info(file.path)
          if conf().datesort:
            date = info.lastWriteTime.toUnix()
          if conf().permissions:
            perms = posix_perms(info)
        let qf = QFile(kind:file.kind, path:file.path, size:size, date:date, perms:perms)
        if file.kind == pcDir:
          dirs.add(qf)
        else:
          dirlinks.add(qf)
      
      # If file
      of pcFile, pcLinkToFile:
        var size: int64 = 0
        var date: int64 = 0
        var perms = ""
        if conf().size or conf().sizesort or conf().datesort or conf().permissions:
          let info = get_info(file.path)
          if conf().size or conf().sizesort:
            size = info.size
          if conf().datesort:
            date = info.lastWriteTime.toUnix()
          if conf().permissions:
            perms = posix_perms(info)
        let qf = QFile(kind:file.kind, path:file.path, size:size, date:date, perms:perms)
        if file.kind == pcFile:
          files.add(qf)
        else:
          filelinks.add(qf)
  
  proc sort_lists() =
    if conf().sizesort:
      dirs = dirs.sortedByIt(it.path.toLower())
      dirlinks = dirlinks.sortedByIt(it.path.toLower())
      files = files.sortedByIt(it.size)
      files.reverse()
      filelinks = filelinks.sortedByIt(it.size)
      filelinks.reverse()
    elif conf().datesort:
      dirs = dirs.sortedByIt(it.date)
      dirs.reverse()
      dirlinks = dirlinks.sortedByIt(it.date)
      dirlinks.reverse()
      files = files.sortedByIt(it.date)
      files.reverse()
      filelinks = filelinks.sortedByIt(it.date)
      filelinks.reverse()
    else:
      dirs = dirs.sortedByIt(it.path.toLower())
      dirlinks = dirlinks.sortedByIt(it.path.toLower())
      files = files.sortedByIt(it.path.toLower())
      filelinks = filelinks.sortedByIt(it.path.toLower())

  proc do_dirs() =
    if not conf().just_files:
      if dirs.len > 0:
        print_title("Directories", dirs.len)
        if conf().list and not conf().no_spacing: log ""
        show_files(dirs)
      if dirlinks.len > 0:
        print_title("Directory Links", dirlinks.len)
        if conf().list and not conf().no_spacing: log ""
        show_files(dirlinks)
  
  proc do_files() =
    if not conf().just_dirs:
      if files.len > 0:
        print_title("Files", files.len)
        if conf().list and not conf().no_spacing: log ""
        show_files(files)
      if filelinks.len > 0:
        print_title("File Links", filelinks.len)
        if conf().list and not conf().no_spacing: log ""
        show_files(filelinks)
  
  proc do_all() =
    if not conf().mix: sort_lists()
    var all = dirs & dirlinks & files & filelinks
    if conf().mix:
      show_files(all.sortedByIt(it.path.toLower()))
    else:
      show_files(all)
  
  proc do_all_reverse() =
    if not conf().mix: sort_lists()
    var all = files & filelinks & dirs & dirlinks
    if conf().mix:
      show_files(all.sortedByIt(it.path.toLower()))
    else:
      show_files(all)
  
  proc total_files(): int =
    dirs.len + dirlinks.len +
    files.len + filelinks.len
  
  proc show_header() =
    echo &"\n{get_ansi(ansi_bright)}{conf().path}",
      &" ({total_files()}) ({posix_perms(info)}){get_ansi(ansi_reset)}"
  
  if conf().header:
    show_header()
  
  if conf().fluid:
    if conf().reverse:
      do_all_reverse()
    else: do_all()
  
  else:
    sort_lists()
    if not conf().reverse:
      do_dirs()
      do_files()
    else:
      do_files()
      do_dirs()
  
  if not conf().no_spacing: log ""