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
  ansi_white
  ansi_black
  ansi_bright
  ansi_underscore

proc reset*(): string =
  ansiResetCode

proc log*(s:string, last=false) =
  stdout.writeLine(&"{reset()}{s}")
  
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
  of "white": ansiForegroundColorCode(fgWhite)
  of "black": ansiForegroundColorCode(fgBlack)
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
  of ansi_white: get_ansi("white")
  of ansi_black: get_ansi("black")
  of ansi_bright: get_ansi("bright")
  of ansi_underscore: get_ansi("underscore")

proc get_8bit_fg_color*(n:int): string =
  &"\e[38;5;{n}m"

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