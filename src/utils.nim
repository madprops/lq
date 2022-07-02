import std/[os, terminal, strutils, strformat]
import config

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
  ansi_dim
  ansi_italic
  ansi_underscore
  ansi_blink
  ansi_blinkrapid
  ansi_reverse
  ansi_hidden
  ansi_strikethrough
  ansi_reset

var
  all_output* = ""
  spaced* = false

proc get_ansi*(kind:string): string =
  if conf().piped: return ""
  
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
  of "dim": ansiStyleCode(styleDim)
  of "italic": ansiStyleCode(styleItalic)
  of "underscore": ansiStyleCode(styleUnderscore)
  of "blink": ansiStyleCode(styleBlink)
  of "blinkrapid": ansiStyleCode(styleBlinkRapid)
  of "reverse": ansiStyleCode(styleReverse)
  of "hidden": ansiStyleCode(styleHidden)
  of "strikethrough": ansiStyleCode(styleStrikethrough)
  of "reset": ansiResetCode
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
  of ansi_dim: get_ansi("dim")
  of ansi_italic: get_ansi("italic")
  of ansi_underscore: get_ansi("underscore")
  of ansi_blink: get_ansi("blink")
  of ansi_blinkrapid: get_ansi("blinkrapid")
  of ansi_reverse: get_ansi("reverse")
  of ansi_hidden: get_ansi("hidden")
  of ansi_strikethrough: get_ansi("strikethrough")
  of ansi_reset: get_ansi("reset")

proc get_ansi*(list:seq[string]): string =
  var s = ""
  for item in list:
    let a = case item
    of "green": get_ansi("green")
    of "cyan": get_ansi("cyan")
    of "red": get_ansi("red")
    of "blue": get_ansi("blue")
    of "magenta": get_ansi("magenta")
    of "yellow": get_ansi("yellow")
    of "white": get_ansi("white")
    of "black": get_ansi("black")
    of "bright": get_ansi("bright")
    of "dim": get_ansi("dim")
    of "underscore": get_ansi("underscore")
    of "italic": get_ansi("italic")
    of "blink": get_ansi("blink")
    of "blinkrapid": get_ansi("blinkrapid")
    of "reverse": get_ansi("reverse")
    of "hidden": get_ansi("hidden")
    of "strikethrough": get_ansi("strikethrough")
    of "reset": get_ansi("reset")
    else: ""

    if a != "": s.add(a)
  
  return s

proc reset*(): string =
  get_ansi("reset")

proc log*(s:string, last=false, linebreak=true) =
  let
    line = &"{reset()}{s}"
    lbrk = if linebreak: "\n" else: ""
    line2 = &"{line}{lbrk}"

  stdout.write(line2)

  if conf().output != "":
    all_output.add(line2)

  spaced = s == "" or s.endsWith("\n")
  
proc toke*() =
  log ""
  spaced = true

proc fix_path*(path:string): string =
  var path = expandTilde(path)
  normalizePath(path)
  if not path.startsWith("/"):
    path = getCurrentDir().joinPath(path)
  return path

proc fix_path_2*(path:string): string =
  var path = expandTilde(path)
  normalizePath(path)
  if not path.startsWith("/"):
    path = fix_path(conf().path).joinPath(path)
  return path