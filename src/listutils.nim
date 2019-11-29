import utils
import os
import strformat
import strutils

type QFile* = object
  kind*: PathComponent
  path*: string
  size*: int64
  date*: int64
  perms*: string

proc posix_perms*(info:FileInfo): string =
  result.add([pcFile: '-', 'l', pcDir: 'd', 'l'][info.kind])
  for i, fp in [fpUserRead, fpUserWrite, fpUserExec, fpGroupRead, fpGroupWrite,
    fpGroupExec, fpOthersRead, fpOthersWrite, fpOthersExec]:
      result.add(if fp in info.permissions: "rwx"[i mod 3] else: '-')

proc get_info*(path:string): FileInfo =
  try:
    var path = fix_path_2(path)
    return getFileInfo(path)
  except:
    return FileInfo()

proc calculate_dir_size*(path:string): int64 =
  var size: int64 = 0
  var path = fix_path_2(path)
  for file in walkDirRec(&"{path}"):
    let info = get_info(file)
    size += info.size
  return size

proc format_perms*(perms:string): string = 
    &" ({perms})"

proc format_size*(file:QFile): string =
  if file.size == 0: return ""
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

proc get_color*(kind:PathComponent): string =
  case kind
  of pcDir: get_ansi("blue")
  of pcLinkToDir: get_ansi("cyan")
  of pcFile: ""
  of pcLinkToFile: get_ansi("green")

proc get_prefix*(kind:PathComponent): string =
  case kind
  of pcDir: "[D] "
  of pcLinkToDir: "[d] "
  of pcFile: "[F] "
  of pcLinkToFile: "[f] "

proc get_level_space*(level:int): string =
  var levs = ""
  for x in 0..<level:
    levs.add("    ")
  return levs