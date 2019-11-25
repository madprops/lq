import utils
import config
import os
import strformat
import strutils
import algorithm
import terminal

proc show_files*(files:seq[tuple[kind: PathComponent, path: string]],
  color:string, prefix:string) =

  var slen = 0
  let termwidth = terminalWidth()
  let cs = ccolor(color)
  var prfx = if conf().prefix: prefix else: ""
  var sline = "\n  "

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

    let s = &"{cs}{prfx}{file.path}{get_ansi(ansi_reset)}{scount}"

    if not conf().list:
      let clen = file.path.len + prfx.len + scount.len + 4
      if slen + clen > termwidth:
        log sline
        sline = "\n  "
        slen = 0
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
        if conf().list: log ""
        show_files(dirs, "blue", "[D] ")
      if dirlinks.len > 0:
        print_title("Directory Links", dirlinks.len)
        if conf().list: log ""
        show_files(dirlinks, "cyan", "[D] ")

  
  proc do_files() =
    if not conf().just_dirs:
      if files.len > 0:
        print_title("Files", files.len)
        if conf().list: log ""
        show_files(files, "", "[F] ")
      if filelinks.len > 0:
        print_title("File Links", filelinks.len)
        if conf().list: log ""
        show_files(filelinks, "green", "[F] ")
    
  if not conf().reverse:
    do_dirs()
    do_files()
  else:
    do_files()
    do_dirs()
  
  log ""