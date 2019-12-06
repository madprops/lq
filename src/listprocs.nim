import utils
import listutils
import config
import os
import nre
import strformat
import strutils
import algorithm
import terminal
import times
import tables

var og_path* = ""
var aotfilter* = false
var filts* = newSeq[string]()
proc list_dir*(path:string, level=0)

proc show_files(files:seq[QFile], path:string, level=0, last=false) =
  var slen = 0
  var cfiles = 0
  let termwidth = terminalWidth()
  let defsline = if conf().list: "" else: "\n  "
  var sline = defsline
  var xp = 2
  var sp = ""
  for x in 0..(xp - 1):
    sp.add(" ")
  let limit = if conf().max_width > 0 and conf().max_width <= termwidth:
    (conf().max_width - 4) else: (termwidth - 4)
  let abc = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
  let use_abc = conf().abc and not conf().mix
  var abci = -1
  var arroba_placed = false

  proc space_item(s:string): string =
    return &"{s}{sp}"
  
  proc format_abc(letter:char): string =
    let c = get_ansi(conf().colors["abc"])
    &"{c}{$letter}{reset()}"
  
  proc check_last(): bool = 
    last and cfiles == files.len
  
  proc print_line() =
    let line = sline.strip(leading=false, trailing=true)
    log(line, check_last())
    sline = defsline
    slen = 0
  
  proc add_to_line(s:string, clen:int) =
    if use_abc and not conf().fluid and not conf().list:
      if sline == defsline:
        sline.add("   ")
        slen += 3

    sline.add(space_item(s))
    slen += clen + xp
    inc(cfiles)

    if conf().list: print_line()
  
  proc add_abc(letter:char, clen:int): bool =
    if conf().list:
      log &"\n{format_abc(letter)}"
    else:
      let cs = &"{format_abc(letter)}{sp}"
      if conf().fluid:
        if slen + clen + 3 > limit:
          print_line()
          return true
      sline.add(cs)
      slen += 3
    return false

  for i, file in files:
    let fmt = format_item(file, path, level, i, files.len, last)
    let s = fmt[0]
    let clen = fmt[1]

    if use_abc:
      let sc = file.path[0].toLowerAscii()
      let ib = abc.find(sc)

      # First @ lines
      if ib == -1:
        if not arroba_placed:
          arroba_placed = true
          if add_abc('@', clen): 
            continue
      else:
        # On letter change
        if ib != abci:
          abci = ib
          arroba_placed = false
          if not conf().fluid:
            if slen > 0:
              print_line()
          if add_abc(abc[ib], clen): 
            continue

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
    else:
      add_to_line(s, clen)
      if conf().tree:
        if file.kind == pcDir:
          list_dir(path.joinPath(file.path), level + 1)

  if slen > 0:
    print_line()
  
  if level == 0:
    if conf().no_titles and conf().list and not conf().abc:
      if not spaced: toke()

proc print_title*(title:string, n:int, level:int) =
  if conf().no_titles: return
  var brk = "\n"
  let c1 = get_ansi(conf().colors["titles"])
  let c2 = get_ansi(conf().colors["details"])
  let s = &"{brk}{c1}{title}{reset()} {c2}({n})"
  log(s)

proc list_dir*(path:string, level=0) =
  if level == 0: og_path = path
  var dirs: seq[QFile]
  var files: seq[QFile]
  var execs: seq[QFile]
  let do_filter = conf().filter != ""
  let do_regex_filter = conf().filter.startsWith("re:")
  var filter = ""
  var res: Regex
  if do_regex_filter:
    res = re(conf().filter.replace(re"^re\:", ""))
  else: filter = conf().filter.toLower()

  proc check_exclude(short_path:string): bool =
    for e in conf().exclude:
      let rs = re(&"{e}/.*")
      if short_path.find(rs).isSome:
        return true
    return false
  
  let info = get_info(path, level == 0)
  
  # Check files ahead of time if filtering a tree
  if do_filter and level == 0 and conf().tree:
    aotfilter = true

    for full_path in walkDirRec(path):
      let short_path = full_path.replace(&"{og_path}/", "")

      if conf().ignore_dots and short_path
      .extractFileName().startsWith("."):
        continue

      # Exclude
      if check_exclude(short_path):
        continue
      
      # Add to filts on matches
      if do_regex_filter:
        let m = short_path.find(res)
        if m.isSome:
          filts.add(short_path)
      else:
        if short_path.toLower().contains(filter):
          filts.add(short_path)

  if info.kind == pcFile or
  info.kind == pcLinkToFile:
    let size = info.size
    let date = info.lastWriteTime.toUnix()
    let perms = posix_perms(info)
    let qf = QFile(kind:info.kind, path:path, size:size, date:date, perms:perms)
    files.add(qf)
    conf().prefix = true
    conf().size = true
    conf().no_titles = true
    conf().permissions = true
  
  else: # If it's a directory check every file in it
    block filesblock: 
      for file in walkDir(path, relative=true):
        let full_path = path.joinPath(file.path)
        let short_path = full_path.replace(&"{og_path}/", "")

        if conf().ignore_dots and short_path
          .extractFileName().startsWith("."):
            continue

        if not aotfilter:
          if check_exclude(short_path):
            show_label("(Excluded)", level)
            break filesblock

        # Filter
        if aotfilter:
          var cont = true
          for filt in filts:
            let rs = re(&"{short_path}(/|$)")
            let m = filt.match(rs)
            if m.isSome:
              cont = false
              break
          if cont: continue
        else:
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
          let info = get_info(full_path)
          if conf().datesort or conf().dirsize or conf().sizesort or conf().dirdate:
            let calc = calculate_dir(full_path)
            size = calc.size
            date = calc.date
          if conf().permissions:
            perms = posix_perms(info)
          let qf = QFile(kind:file.kind, path:file.path, size:size, date:date, perms:perms, exe:false)
          dirs.add(qf)
            
        # If file
        of pcFile, pcLinkToFile:
          var size: int64 = 0
          var date: int64 = 0
          var perms = ""
          let info = get_info(full_path)
          if conf().size or conf().sizesort or conf().datesort or conf().permissions or conf().date:
            if conf().size or conf().sizesort:
              size = info.size
            if conf().datesort or conf().date:
              date = info.lastWriteTime.toUnix()
            if conf().permissions:
              perms = posix_perms(info)
          let exe = info.permissions.contains(fpUserExec)
          let qf = QFile(kind:file.kind, path:file.path, size:size, date:date, perms:perms, exe:exe)
          if exe: execs.add(qf)
          else: files.add(qf)
  
  proc sort_list(list: var seq[QFile]) =
    if conf().sizesort:
      list = list.sortedByIt(it.size)
      if not conf().reverse_sort:
        list.reverse()
    elif conf().datesort:
      list = list.sortedByIt(it.date)
      if not conf().reverse_sort:
        list.reverse()
    else:
      list = list.sortedByIt(it.path.toLower())
      if conf().reverse_sort:
        list.reverse()
        
  proc sort_lists() =
    sort_list(dirs)
    sort_list(files)
    sort_list(execs)
  
  proc do_dirs(last=false) =
    if not conf().just_files and not conf().just_execs:
      if dirs.len > 0:
        print_title("Dircs", dirs.len, level)
        if level == 0 and first_print and not spaced:
          if conf().list: toke()
        show_files(dirs, path, level, last)
      
  proc do_files(last=false) =
    if not conf().just_dirs and not conf().just_execs:
      if files.len > 0:
        print_title("Files", files.len, level)
        if level == 0 and first_print and not spaced:
          if conf().list: toke()
        show_files(files, path, level, last)
      
  proc do_execs(last=false) =
    if not conf().just_dirs and not conf().just_files: 
      if execs.len > 0:
        print_title("Execs", execs.len, level)
        if level == 0 and first_print and not spaced:
          if conf().list: toke()
        show_files(execs, path, level, last)
      
  proc do_all(last=false) =
    if not conf().mix: sort_lists()
    var all = dirs & files & execs
    if conf().mix:
      sort_list(all)
      show_files(all, path, level, last)
    else:
      show_files(all, path, level, last)
      
  proc do_all_reverse(last=false) =
    if not conf().mix: sort_lists()
    var all = files & dirs & execs
    if conf().mix:
      sort_list(all)
      show_files(all, path, level, last)
    else:
      show_files(all, path, level, last)
      
  proc total_files(): int =
    dirs.len + files.len + execs.len
      
  proc show_header() =
    let c1 = get_ansi(conf().colors["header"])
    let c2 = get_ansi(conf().colors["details"])
    let n1 = if conf().no_titles: "" else: "\n"
    let n2 = if conf().no_titles: "\n" else: ""
    log &"{n1}{c1}{path} {reset()}{c2}({posix_perms(info)}) ({total_files()}){n2}"
      
  if level == 0 and conf().header:
    show_header()
      
  if conf().fluid:
    if conf().reverse:
      do_all_reverse(true)
    else: do_all(true)
      
  else:
    sort_lists()
    if not conf().reverse:
      do_dirs(files.len == 0 and execs.len == 0)
      do_files(execs.len == 0)
      do_execs(true)
    else:
      do_execs(files.len == 0 and dirs.len == 0)
      do_files(dirs.len == 0)
      do_dirs(true)

  if level == 1:
    toke()
  elif level == 0:
    if not spaced:
      toke()