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
var spaced* = false
var aotfilter* = false
var filts* = newSeq[string]()
proc list_dir*(path:string, level=0)

proc show_files(files:seq[QFile], path:string, level=0, last=false, batches:var int) =
  spaced = false
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
    let fmt = format_item(file, path, level, i, files.len, batches)
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
      if not last and not spaced: toke()

  dec(batches)

proc print_title*(title:string, n:int, level:int) =
  if conf().no_titles: return
  var brk = "\n"
  let c1 = get_ansi(conf().colors["titles"])
  let c2 = get_ansi(conf().colors["count"])
  let s = &"{brk}{c1}{title}{reset()} {c2}({n})"
  log(s)

proc list_dir*(path:string, level=0) =
  if level == 0: og_path = path
  var dirs: seq[QFile]
  var dirlinks: seq[QFile]
  var files: seq[QFile]
  var filelinks: seq[QFile]
  var exefiles: seq[QFile]
  var exefilelinks: seq[QFile]
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
  
  # Check files ahead of time if filtering a tree
  if do_filter and level == 0 and conf().tree:
    aotfilter = true

    for full_path in walkDirRec(path):
      let short_path = full_path.replace(og_path, "")

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
      for file in walkDir(path, relative=true):
        let full_path = path.joinPath(file.path)
        let short_path = full_path.replace(og_path, "")

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
          if conf().datesort or conf().dsize or conf().sizesort:
            let calc = calculate_dir(full_path)
            size = calc.size
            date = calc.date
          if conf().permissions:
            perms = posix_perms(info)
          let qf = QFile(kind:file.kind, path:file.path, size:size, date:date, perms:perms, exe:false)
          if file.kind == pcDir:
            dirs.add(qf)
          else:
            dirlinks.add(qf)
            
        # If file
        of pcFile, pcLinkToFile:
          var size: int64 = 0
          var date: int64 = 0
          var perms = ""
          let info = get_info(full_path)
          if conf().size or conf().sizesort or conf().datesort or conf().permissions:
            if conf().size or conf().sizesort:
              size = info.size
            if conf().datesort:
              date = info.lastWriteTime.toUnix()
            if conf().permissions:
              perms = posix_perms(info)
          let exe = info.permissions.contains(fpUserExec)
          let qf = QFile(kind:file.kind, path:file.path, size:size, date:date, perms:perms, exe:exe)
          if file.kind == pcFile:
            if exe: exefiles.add(qf)
            else: files.add(qf)
          else:
            if exe: exefilelinks.add(qf)
            else: filelinks.add(qf)
        
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
  
  var batches = 0
  
  proc do_dirs(last=false) =
    if not conf().just_files:
      if dirs.len > 0 or dirlinks.len > 0:
        print_title("Dircs", dirs.len, level)
        if level == 0 and first_print and not spaced:
          if conf().list: toke()
        show_files(dirs & dirlinks, path, level, last and dirlinks.len == 0, batches)
      
  proc do_files(last=false) =
    if not conf().just_dirs:  
      if files.len > 0 or filelinks.len > 0:
        print_title("Files", files.len, level)
        if level == 0 and first_print and not spaced:
          if conf().list: toke()
        show_files(files & filelinks, path, level, last and filelinks.len == 0, batches)
      
  proc do_exefiles(last=false) =
    if not conf().just_dirs:  
      if exefiles.len > 0 or exefilelinks.len > 0:
        print_title("Execs", exefiles.len, level)
        if level == 0 and first_print and not spaced:
          if conf().list: toke()
        show_files(exefiles & exefilelinks, path, level, last and exefilelinks.len == 0, batches)
      
  proc do_all(last=false) =
    if not conf().mix: sort_lists()
    var all = dirs & dirlinks & files & filelinks & exefiles & exefilelinks
    if conf().mix:
      show_files(all.sortedByIt(it.path.toLower()), path, level, last, batches)
    else:
      show_files(all, path, level, last, batches)
      
  proc do_all_reverse(last=false) =
    if not conf().mix: sort_lists()
    inc(batches)
    var all = files & filelinks & dirs & dirlinks & exefiles & exefilelinks
    if conf().mix:
      show_files(all.sortedByIt(it.path.toLower()), path, level, last, batches)
    else:
      show_files(all, path, level, last, batches)
      
  proc total_files(): int =
    dirs.len + dirlinks.len +
    files.len + filelinks.len

  proc no_items(): bool =
    total_files() == 0
      
  proc show_header() =
    let c1 = get_ansi(conf().colors["header"])
    let n1 = if conf().no_titles: "" else: "\n"
    let n2 = if conf().no_titles: "\n" else: ""
    log &"{n1}{c1}{path}\n{reset()}({total_files()}) ({posix_perms(info)}){n2}"
      
  if level == 0 and conf().header:
    show_header()
      
  if conf().fluid:
    inc(batches)
    if conf().reverse:
      do_all_reverse(level == 0)
    else: do_all(level == 0)
      
  else:
    sort_lists()

    if dirs.len > 0:
      inc(batches)
    if dirlinks.len > 0:
      inc(batches) 
    if files.len > 0:
      inc(batches)
    if filelinks.len > 0:
      inc(batches) 
    if exefiles.len > 0:
      inc(batches)
    if exefilelinks.len > 0:
      inc(batches) 

    if not conf().reverse:
      do_dirs(level == 0 and files.len == 0)
      do_files(level == 0)
      do_exefiles(level == 0)
    else:
      do_exefiles(level == 0 and dirs.len == 0)
      do_files(level == 0 and dirs.len == 0)
      do_dirs(level == 0)

  if level == 1:
    toke()
    spaced = true