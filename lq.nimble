# Package

version       = "3.0.0"
author        = "madprops"
description   = "Directory listing tool"
license       = "GPL-2.0"
srcDir        = "src"
bin           = @["lq"]
skipExt       = @["nim"]


# Dependencies

requires "nim >= 1.0.0"
requires "nap >= 3.0.0"