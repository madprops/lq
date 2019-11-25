import utils
import config
import os
import strformat
import strutils
import algorithm
import terminal

proc get_color(kind:PathComponent): string =
  case kind
  of pcDir: get_ansi("blue")
  of pcLinkToDir: get_ansi("cyan")
  of pcFile: ""
  of pcLinkToFile: get_ansi("green")

proc get_prefix(kind:PathComponent): string =
  case kind
  of pcDir, pcLinkToDir: "[D] "
  of pcFile, pcLinkToFile: "[F] "

proc show_files*(files:seq[tuple[kind: PathComponent, path: string]]) =
  var slen = 0
  let termwidth = terminalWidth()
  var sline = if conf().no_spacing: "" else: "\n  "
  var xp = if conf().no_spacing: 2 else: 4

  for file in files:
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

    let color = get_color(file.kind)
    var prefix = if conf().prefix: get_prefix(file.kind) else: ""
    let s = &"{color}{prefix}{file.path}{get_ansi(ansi_reset)}{scount}"

    if not conf().list:
      let clen = file.path.len + prefix.len + scount.len + xp
      if slen + clen > termwidth:
        log sline
        sline = if conf().no_spacing: "" else: "\n  "
        slen = 0
      else:
        if conf().no_spacing:
          sline.add(&"{s} ")
        else:
          sline.add(&"{s}  ")
        slen += clen
    else: log s
      
  if slen > 0:
    log sline

proc list_dir*() =
  conf().path = fix_path(conf().path)
  var dirs: seq[tuple[kind: PathComponent, path: string]]
  var dirlinks: seq[tuple[kind: PathComponent, path: string]]
  var filelinks: seq[tuple[kind: PathComponent, path: string]]
  var files: seq[tuple[kind: PathComponent, path: string]]
  let do_filter = conf().filter != ""
  let filter = if do_filter: conf().filter.toLower() else: ""
  
  for file in walkDir(conf().path, relative=(not conf().absolute)):
    if do_filter:
      if not file.path.toLower().contains(filter):
        continue
    case file.kind
    of pcDir: 
      dirs.add(file)
    of pcLinkToDir: dirlinks.add(file)
    of pcLinkToFile: filelinks.add(file)
    of pcFile: files.add(file)
  
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
    var all = dirs & dirlinks & files & filelinks
    if conf().mix:
      show_files(all.sortedByIt(it.path.toLower()))
    else:
      show_files(all)
  
  proc do_all_reverse() =
    var all = files & filelinks & dirs & dirlinks
    if conf().mix:
      show_files(all.sortedByIt(it.path.toLower()))
    else:
      show_files(all)
  
  if conf().fluid:
    if conf().reverse:
      do_all_reverse()
    else: do_all()
  
  else:
    if not conf().reverse:
      do_dirs()
      do_files()
    else:
      do_files()
      do_dirs()
  
  if not conf().no_spacing: log ""