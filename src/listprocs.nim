import std/[os, nre, strformat, strutils, algorithm, terminal, times, tables]
import config
import listutils
import utils

var
 og_path* = ""
 aotfilter* = false
 filts*: Table[string, bool]
 title_printed_len* = 0
 listed = false
 first_line = false

proc list_dir*(path:string, level=0)

var
  space_level = 2
  space = ""

for x in 0..<space_level:
  space.add(" ")

proc get_defsline(): string =
  return if first_line:
    if listed: "" else: "\n  "
  else:
    if listed: "" else: "  "  

proc show_files(files:seq[QFile], path:string, level=0, last=false) =
  var
    slen = 0
    cfiles = 0
  
  let termwidth = terminalWidth()
  var sline = ""

  if title_printed_len == 0:
    sline = get_defsline()
  else:
    sline = "  "
    slen = title_printed_len
    title_printed_len = 0

  let limit = if conf().max_width > 0 and conf().max_width <= termwidth:
    (conf().max_width - 4) else: (termwidth - 4)

  var
    current_file = QFile()
    current_index = 0

  proc space_item(s:string): string =
    return &"{s}{space}"
  
  proc check_last(): bool = 
    last and cfiles == files.len
  
  proc print_line() =
    let line = sline.strip(leading=false, trailing=true)
    log(line, check_last())
    first_line = true  
    sline = get_defsline()
    slen = 0
    if has_snippet(current_file):
      let lvl = if conf().tree: level + 1 else: level
      show_snippet(path.joinPath(current_file.path), current_file.size, lvl)
  
  proc add_to_line(s:string, clen:int) =
    sline.add(space_item(s))
    slen += clen + space_level
    inc(cfiles) 

    if listed: print_line()

  for i, file in files:
    current_index = i
    current_file = file

    let 
      fmt = format_item(file, path, level, i, files.len, last)
      s = fmt[0]
      clen = fmt[1]

    if not listed:
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
    else:
      add_to_line(s, clen)
      if conf().tree:
        if file.kind == pcDir:
          list_dir(path.joinPath(file.path), level + 1)

  if slen > 0:
    print_line()

proc list_dir*(path:string, level=0) =
  var path = path
  if level == 0: og_path = path

  var
    dirs: seq[QFile]
    files: seq[QFile]
    execs: seq[QFile]
  
  let
    do_filter = conf().filter != ""
    do_regex_filter = conf().filter.startsWith("re:")
  
  var
    filter = ""
    res: Regex

  if do_regex_filter:
    res = re(conf().filter.replace(re"^re\:", ""))
  else: filter = conf().filter
  let do_calculate_dirs = conf().dirdatesort or conf().dirsize or 
    conf().dirsizesort or conf().dirdate
  let info = get_info(path, level == 0)

  proc check_exclude(short_path:string): bool =
    for e in conf().exclude:
      if short_path.contains(&"{e}{os.DirSep}"):
        return true
    return false
  
  proc add_filt(short_path:string) =
    var sp = short_path
    filts[sp] = true
    while sp != "":
      sp = sp.splitPath[0]
      filts[sp] = true
  
  proc process_file(fpath:string): bool =
    let
      full_path = path.joinPath(fpath)
      short_path = full_path.replace(&"{og_path}{os.DirSep}", "")
      info = get_info(full_path)
  
    if conf().no_hidden and short_path
      .extractFileName().startsWith("."):
        return false
  
    if not aotfilter:
      if check_exclude(short_path):
        show_label("(Excluded)", level)
        return true
  
    # Filter
    if aotfilter:
      if not filts.hasKey(short_path):
        return false
    else:
      if do_filter:
        if do_regex_filter:
          let m = fpath.find(res)
          if m.isNone: return false
        else:
          if not fpath.contains(filter):
            return false
      
    # Add to proper list
    case info.kind
      
    # If directory
    of pcDir, pcLinkToDir:
      if conf().just_files or conf().just_execs: return false

      var
         size: int64 = 0
         date: int64 = 0
         perms = ""

      if do_calculate_dirs:
        let calc = calculate_dir(full_path)
        size = calc.size
        date = calc.date
      if conf().permissions:
        perms = posix_perms(info)
      if conf().datesort2:
        date = info.lastWriteTime.toUnix()
      if conf().sizesort2:
        size = info.size
      let qf = QFile(kind:info.kind, path:fpath, size:size, date:date, perms:perms, exe:false)
      dirs.add(qf)
              
    # If file
    of pcFile, pcLinkToFile:
      var
        size = info.size
        date: int64 = 0
        perms = ""

      if conf().size or conf().sizesort or conf().datesort or conf().permissions or conf().date:
        if conf().datesort or conf().date:
          date = info.lastWriteTime.toUnix()
        if conf().permissions:
          perms = posix_perms(info)
      
      let
        exe = info.permissions.contains(fpUserExec)
        qf = QFile(kind:info.kind, path:fpath, size:size, date:date, perms:perms, exe:exe)

      if conf().just_dirs: return false
      if conf().just_files and exe: return false
      if conf().just_execs and not exe: return false

      if exe:
        if conf().mix_files: files.add(qf)
        else: execs.add(qf)
      else: files.add(qf)
    
    return false
  
  proc sort_list(list: var seq[QFile]) =
    if list.len == 0: return
    let kind = list[0].kind
    
    if conf().sizesort and
      (kind == pcFile or kind == pcLinkToFile) or
      ((kind == pcDir or kind == pcLinkToDir) and (conf().dirsizesort or conf().sizesort2)):
        list = list.sortedByIt(it.size)
        if not conf().reverse:
          list.reverse()

    elif conf().datesort and
      (kind == pcFile or kind == pcLinkToFile) or
      ((kind == pcDir or kind == pcLinkToDir) and (conf().dirdatesort or conf().datesort2)):
        list = list.sortedByIt(it.date)
        if not conf().reverse:
          list.reverse()

    else:
      list = list.sortedByIt(it.path.toLowerAscii)
      if conf().reverse:
        list.reverse()
        
  proc sort_lists() =
    sort_list(dirs)
    sort_list(files)
    sort_list(execs)
      
  proc do_all(last=false) =
    if not conf().mix: sort_lists()
    var all = dirs & files & execs
    if conf().mix:
      sort_list(all)
      show_files(all, path, level, last)
    else:
      show_files(all, path, level, last)
      
  proc total_files(): int =
    dirs.len + files.len + execs.len
  
  # # # - M A I N - # # #

  listed = conf().list or conf().tree or conf().snippets

  # Check files ahead of time if filtering a tree
  if do_filter and level == 0 and conf().tree:
    aotfilter = true

    for full_path in walkDirRec(path, yieldFilter={pcFile, pcLinkToFile, pcDir, pcLinkToDir}):
      let short_path = full_path.replace(&"{og_path}/", "")

      if conf().no_hidden and short_path
      .extractFileName().startsWith("."):
        continue

      # Exclude
      if check_exclude(short_path):
        continue
      
      # Add to filts on matches
      if do_regex_filter:
        let m = short_path.find(res)
        if m.isSome:
          add_filt(short_path)
      else:
        if short_path.contains(filter):
          add_filt(short_path)
    
    if filts.len == 0:
      quit(0)    

  if info.kind == pcFile or
  info.kind == pcLinkToFile:
    conf().prefix = true
    conf().permissions = true
    conf().size = true
    conf().date = true
    let split = path.splitPath()
    og_path = split[0]
    path = split[0]
    discard process_file(split[1])
  
  else: # If it's a directory check every file in it
    block filesblock: 
      for file in walkDir(path, relative=true):
        if process_file(file.path): break filesblock    
  
  if level == 0 and total_files() == 0:
    quit(0)
  
  # Only tree mode gets spaced

  do_all(true)