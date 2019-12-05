import utils
import config
import listprocs

when isMainModule:
  # Config stuff
  get_config()

  # First line
  if conf().no_titles and conf().list and 
    not conf().abc: toke()
  
  # The meat
  list_dir(conf().path)
  if not spaced: toke()

  # Output to file if 
  # output is enabled
  if conf().output != "":
    writeFile(conf().output, all_output)