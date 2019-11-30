import utils
import config
import listprocs

when isMainModule:
  get_config()
  conf().path = fix_path(conf().path)
  write_bg()
  fill()
  list_dir(conf().path)
  if not spaced: 
    toke()