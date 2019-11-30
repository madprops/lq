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

var spaced* = false

proc list_dir*(path:string, level=0)

proc show_files(files:seq[QFile], path:string, level=0, last=false) =
  spaced = false
  var slen = 0
  var cfiles = 0
  let termwidth = terminalWidth()
  var sline = "\n  "
  var xp = 2
  var sp = ""
  for x in 0..(xp - 1):
    sp.add(" ")
  let limit = (termwidth - 4)
  let abc = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
  let use_abc = conf().abc and not conf().mix
  var abci = -1
  var used_abci = -1
  var abc_started = false

  proc space_item(s:string): string =
    return &"{s}{sp}"
  
  proc format_abc(c:char): string =
    &"{get_ansi(get_ansi(conf().abccolor))}{$c}"
  
  proc check_last(): bool = 
    last and cfiles == files.len
  
  proc print_abc() =
    if abci != -1:
      if abci == used_abci:
        return
      else: used_abci = abci
    let c = if abci > -1:
      abc[abci]
    else: '@'

    let sp = "  "
    log(&"{sp}{format_abc(c)}")
  
  proc print_line() =
    if use_abc and abc_started and not conf().fluid:
      print_abc()

    log(sline.strip(leading=false, trailing=true), check_last())

    sline = "\n  "
    slen = 0
  
  proc add_to_line(s:string, clen:int) =
    sline.add(space_item(s))
    slen += clen + xp
    inc(cfiles)

  for file in files:
    let fmt = format_item(file, path, level)
    let s = fmt[0]
    let clen = fmt[1]

    if use_abc:
      let sc = file.path[0].toLowerAscii()
      let ib = abc.find(sc)
      if ib == -1:
        if not abc_started:
          toke()
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
            toke()

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
    else:
      inc(cfiles)
      log(s, check_last())
      if conf().tree:
        if file.kind == pcDir:
          list_dir(path.joinPath(file.path), level + 1)

  if slen > 0:
    print_line()

proc list_dir*(path:string, level=0) =
  var dirs: seq[QFile]
  var dirlinks: seq[QFile]
  var files: seq[QFile]
  var filelinks: seq[QFile]
  let do_filter = conf().filter != ""
  let do_regex_filter = conf().filter.startsWith("re:")
  var filter = ""
  var msg = ""
  var res: Regex
  if do_regex_filter:
    res = re(conf().filter.replace(re"^re\:", ""))
  else: filter = conf().filter.toLower()
  
  let info = getFileInfo(path)
  
  if info.kind == pcFile or
  info.kind == pcLinkToFile:
    let size = info.size
    let date = info.lastWriteTime.toUnix()
    let perms = posix_perms(info)
    let qf = QFile(kind:info.kind, path:path, size:size, date:date, perms:perms)
    if info.kind == pcFile:
      files.add(qf)
    else:
      filelinks.add(qf)
    conf().prefix = true
    conf().size = true
    conf().no_titles = true
    conf().permissions = true
  
  else: # If it's a directory check every file in it
    block filesblock: 
      for file in walkDir(path, relative=(not conf().absolute)):
        let fp = path.joinPath(file.path)

        for e in conf().exclude:
          let rs = re(&"/{e}(/|$)")
          if fp.find(rs).isSome and conf().path.find(rs).isNone:
            if level > 0:
              if level == 1:
                msg = "(Excluded)"
              break filesblock

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
          if conf().datesort or conf().dsize or conf().sizesort:
            let calc = calculate_dir(fp)
            size = calc.size
            date = calc.date
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
            let info = get_info(fp)
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
      dirs = dirs.sortedByIt(it.size)
      dirs.reverse()
      dirlinks = dirlinks.sortedByIt(it.size)
      dirlinks.reverse()
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
  
  proc do_dirs(last=false) =
    if not conf().just_files:
      if dirs.len > 0:
        print_title("Directories", dirs.len)
        if level == 0 and first_print and not spaced:
          if conf().list: toke()
        show_files(dirs, path, level, false)
      if dirlinks.len > 0:
        print_title("Directory Links", dirlinks.len)
        if level == 0 and first_print and not spaced:
          if conf().list: toke()
        show_files(dirlinks, path, level, last)
      
  proc do_files(last=false) =
    if not conf().just_dirs:
      if files.len > 0:
        print_title("Files", files.len)
        if level == 0 and first_print and not spaced:
          if conf().list: toke()
        show_files(files, path, level, false)
      if filelinks.len > 0:
        print_title("File Links", filelinks.len)
        if level == 0 and first_print and not spaced:
          if conf().list: toke()
        show_files(filelinks, path, level, last)
      
  proc do_all(last=false) =
    if not conf().mix: sort_lists()
    var all = dirs & dirlinks & files & filelinks
    if conf().mix:
      show_files(all.sortedByIt(it.path.toLower()), path, level, last)
    else:
      show_files(all, path, level, last)
      
  proc do_all_reverse(last=false) =
    if not conf().mix: sort_lists()
    var all = files & filelinks & dirs & dirlinks
    if conf().mix:
      show_files(all.sortedByIt(it.path.toLower()), path, level, last)
    else:
      show_files(all, path, level, last)
      
  proc total_files(): int =
    dirs.len + dirlinks.len +
    files.len + filelinks.len

  proc no_items(): bool =
    total_files() == 0
      
  proc show_header() =
    let c1 = get_ansi(conf().headercolor)
    log &"\n{get_ansi(ansi_bright)}{c1}{path}" &
      &" ({total_files()}) ({posix_perms(info)})"
      
  if conf().header:
    show_header()
      
  if conf().fluid:
    if conf().reverse:
      do_all_reverse(level == 0)
    else: do_all(level == 0)
      
  else:
    if level > 0 and no_items():
      if msg == "": msg = "(Empty)"
      let c1 = get_ansi(conf().headercolor)
      log(&"{get_level_space(level)}{c1}{msg}")
    else:
      sort_lists()
      if not conf().reverse:
        do_dirs()
        do_files(level == 0)
      else:
        do_files()
        do_dirs(level == 0)

  if level == 1:
    toke()
    spaced = true