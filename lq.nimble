# Package

version       = "1.0.1"
author        = "madprops"
description   = "Directory listing tool"
license       = "GPL-2.0"
srcDir        = "src"
bin           = @["lq"]
skipExt       = @["nim"]


# Dependencies

requires "nim >= 1.0.0"
requires "nap >= 1.5.1"
requires "parsetoml >= 0.5.0"
