import utils
import config
import listprocs

when isMainModule:
  get_config()
  conf().path = fix_path(conf().path)
  if conf().no_titles and conf().list: toke()
  list_dir(conf().path)
  if not spaced: 
    toke()