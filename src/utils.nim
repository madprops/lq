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
  ansi_bright
  ansi_reset

proc get_ansi*(kind:string): string =
  case kind
  of "green": ansiForegroundColorCode(fgGreen)
  of "cyan": ansiForegroundColorCode(fgCyan)
  of "red": ansiForegroundColorCode(fgRed)
  of "blue": ansiForegroundColorCode(fgBlue)
  of "magenta": ansiForegroundColorCode(fgMagenta)
  of "bright": ansiStyleCode(styleBright)
  of "reset": ansiResetCode
  else: ""

proc get_ansi*(kind:AnsiKind): string =
  case kind
  of ansi_green: get_ansi("green")
  of ansi_cyan: get_ansi("cyan")
  of ansi_red: get_ansi("red")
  of ansi_blue: get_ansi("blue")
  of ansi_magenta: get_ansi("magenta")
  of ansi_bright: get_ansi("bright")
  of ansi_reset: get_ansi("reset")

proc log*(s:string) =
  echo s

proc ccolor*(color:string): string =
  if conf.no_colors: "" else: get_ansi(color)

proc ccolor*(color:AnsiKind): string =
  if conf.no_colors: "" else: get_ansi(color)

proc fix_path*(path:string): string =
  var path = expandTilde(path)
  normalizePath(path)
  if not path.startsWith("/"):
    path = if conf.dev:
      getCurrentDir().parentDir().joinPath(path)
      else: getCurrentDir().joinPath(path)
  return path

proc print_title*(title:string, n:int) =
  log(&"\n{get_ansi(ansi_magenta)}{get_ansi(ansi_bright)}{title}{get_ansi(ansi_reset)} ({n})")