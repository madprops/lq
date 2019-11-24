import config
import listprocs

when isMainModule:
  get_config()
  list_dir(conf.path)