# Package
version       = "0.0.11"
author        = "Brent Pedersen"
description   = "nim wrapper for miniz for zip functions"
license       = "MIT"

installExt = @["nim", "c", "h"]

#srcDir = "minizip"
skipDirs = @["tests"]

task test, "run the tests":
  exec "nim c  -d:useSysAssert -d:useGcAssert --lineDir:on --debuginfo --lineDir:on --debuginfo -r --threads:on tests/minizip_test.nim"

