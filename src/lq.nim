import utils
import config
import listprocs

when isMainModule:
  # Config stuff
  get_config()
  conf().path = fix_path(conf().path)

  # First line
  if conf().no_titles and conf().list and 
    not conf().abc: toke()
  
  # The meat
  list_dir(conf().path)
  if not spaced: toke()