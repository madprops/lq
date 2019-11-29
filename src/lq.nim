import utils
import config
import listprocs

when isMainModule:
  get_config()
  conf().path = fix_path(conf().path)
  list_dir(conf().path)