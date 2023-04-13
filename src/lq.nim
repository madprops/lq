import utils
import config
import listprocs

when isMainModule:
  get_config()  
  toke()
  list_dir(conf().path)
  toke()

  # Output to file if 
  # output is enabled
  if conf().output != "":
    writeFile(conf().output, all_output)