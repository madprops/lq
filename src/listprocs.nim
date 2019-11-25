import utils
import config
import os
import nre
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
  var xp = if conf().no_spacing: 1 else: 2
  let limit = if conf().no_spacing: termwidth else: (termwidth - 4)

  proc print_line() =
    log sline.strip(leading=false, trailing=true)
    sline = if conf().no_spacing: "" else: "\n  "
    slen = 0
  
  proc add_to_line(s:string, clen:int) =
    if conf().no_spacing:
      sline.add(&"{s} ")
    else:
      sline.add(&"{s}  ")
    slen += clen + xp

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
    # Formatted item
    let s = &"{color}{prefix}{file.path}{get_ansi(ansi_reset)}{scount}"

    if not conf().list:
      let clen = file.path.len + prefix.len + scount.len
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
    log sline

proc list_dir*() =
  conf().path = fix_path(conf().path)
  var dirs: seq[tuple[kind: PathComponent, path: string]]
  var dirlinks: seq[tuple[kind: PathComponent, path: string]]
  var filelinks: seq[tuple[kind: PathComponent, path: string]]
  var files: seq[tuple[kind: PathComponent, path: string]]
  let do_filter = conf().filter != ""
  let do_regex_filter = conf().filter.startsWith("re:")
  var filter = ""
  var res: Regex
  if do_regex_filter:
    res = re(conf().filter.replace(re"^re\:", ""))
  else: filter = conf().filter.toLower()
  
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
    of pcDir: 
      dirs.add(file)
    of pcLinkToDir: dirlinks.add(file)
    of pcLinkToFile: filelinks.add(file)
    of pcFile: files.add(file)
  
  proc sort_lists() =
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