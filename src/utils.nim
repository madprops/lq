import config
import os
import terminal
import strutils
import strformat

type AnsiKind* = enum
  ansi_green
  ansi_cyan
  ansi_red
  ansi_blue
  ansi_magenta
  ansi_yellow
  ansi_bright
  ansi_underscore

var termwidth = terminalWidth()

proc rstyle*(): string =
  "\e[22m"

proc write_reset*() =
  stdout.write(ansiResetCode)

proc write_bg*() =
  stdout.write(conf().bg_color_code)

proc log*(s:string, last=false) =
  if first_print:
    stdout.write("\n")
  else: first_print = true
  let rs = if last:
    &"\n{ansiResetCode}"
  else: ""
  stdout.write(&"{s}{rs}")
  
proc toke*() =
  log ""

proc get_ansi*(kind:string): string =
  case kind
  of "green": ansiForegroundColorCode(fgGreen)
  of "cyan": ansiForegroundColorCode(fgCyan)
  of "red": ansiForegroundColorCode(fgRed)
  of "blue": ansiForegroundColorCode(fgBlue)
  of "magenta": ansiForegroundColorCode(fgMagenta)
  of "yellow": ansiForegroundColorCode(fgYellow)
  of "bright": ansiStyleCode(styleBright)
  of "underscore": ansiStyleCode(styleUnderscore)
  else: ""

proc get_ansi*(kind:AnsiKind): string =
  case kind
  of ansi_green: get_ansi("green")
  of ansi_cyan: get_ansi("cyan")
  of ansi_red: get_ansi("red")
  of ansi_blue: get_ansi("blue")
  of ansi_magenta: get_ansi("magenta")
  of ansi_yellow: get_ansi("yellow")
  of ansi_bright: get_ansi("bright")
  of ansi_underscore: get_ansi("underscore")

proc get_8bit_fg_color*(n:int): string =
  &"\e[38;5;{n}m"

proc ccolor*(color:string): string =
  if conf().no_colors: "" else: get_ansi(color)

proc ccolor*(color:AnsiKind): string =
  if conf().no_colors: "" else: get_ansi(color)

proc fix_path*(path:string): string =
  var path = expandTilde(path)
  normalizePath(path)
  if not path.startsWith("/"):
    path = if conf().dev:
      getCurrentDir().parentDir().joinPath(path)
      else: getCurrentDir().joinPath(path)
  return path

proc fix_path_2*(path:string): string =
  var path = expandTilde(path)
  normalizePath(path)
  if not path.startsWith("/"):
    path = fix_path(conf().path).joinPath(path)
  return path