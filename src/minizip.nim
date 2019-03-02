import ./miniz_sys
import strutils
import os

type Zip* = object
  c : mz_zip_archive

template check_mode(zip: Zip, mode: mz_zip_mode, operation: string) =
  if zip.c.addr.m_zip_mode != mode:
    raise newException(IOError, "must be opened in another mode to " & operation & " mode was:" & $zip.c.addr.m_zip_mode)

proc len*(zip: var Zip): int =
  return zip.c.addr.mz_zip_reader_get_num_files().int

proc open*(zip: var Zip, path: string, mode:FileMode=fmRead): bool {.discardable.} =
  #zip.c.m_pState = nil
  if mode == fmWrite:
    var err = zip.c.addr.mz_zip_writer_init_file(path, MZ_ZIP_FLAG_WRITE_ZIP64.mz_uint)
    if err != 1:
      stderr.write_line "minizip: error opening zip file " & $err
      return false
    return true
  elif mode == fmRead:
    return zip.c.addr.mz_zip_reader_init_file(path.cstring, 0) == 1
  else:
    quit "unsupported mode for zip"

proc add_file*(zip: var Zip, path: string, archivePath:string="") =
  check_mode(zip, MZ_ZIP_MODE_WRITING, "add_file")
  var comment:pointer
  if not fileExists(path):
    raise newException(ValueError, "no file found at:" & path)
  var arcPath = path.cstring
  if archivePath != "":
    arcPath = archivePath.cstring
  doAssert zip.c.addr.mz_zip_writer_add_file(archivePath, path.cstring, comment, 0, mz_uint(3'u8 or MZ_ZIP_FLAG_CASE_SENSITIVE.uint8 or MZ_ZIP_FLAG_WRITE_ZIP64.uint8)) == MZ_TRUE

proc close*(zip: var Zip) =
  if zip.c.addr.m_zip_mode == MZ_ZIP_MODE_WRITING:
    doAssert zip.c.addr.mz_zip_writer_finalize_archive() == MZ_TRUE
    doAssert zip.c.addr.mz_zip_writer_end() == MZ_TRUE
  elif zip.c.addr.m_zip_mode == MZ_ZIP_MODE_READING:
    doAssert zip.c.addr.mz_zip_reader_end() == MZ_TRUE

proc get_file_name(zip: var Zip, i:int): string {.inline.} =
  var size = zip.c.addr.mz_zip_reader_get_filename(i.mz_uint, result, 0)
  result = newString(size.int)
  doAssert zip.c.addr.mz_zip_reader_get_filename(i.mz_uint, result, size) == size
  # drop trailing byte.
  result = result[0..<result.high]

iterator pairs*(zip: var Zip): (int, string) =
  ## yield each path to each file in the archive
  for i in 0..<zip.len:
    if zip.c.addr.mz_zip_reader_is_file_a_directory(i.mz_uint) == MZ_TRUE: continue
    yield (i, zip.get_file_name(i))

proc extract_file*(zip: var Zip, path: string, destDir:string=""): string {.discardable.} =
  ## extract a single file at the given path from the zip archive and return the path to which it
  ## was extracted.
  var i = zip.c.addr.mz_zip_reader_locate_file(path, "", 0)
  if i != -1:
    var dest = destDir / zip.get_file_name(i)
    dest.parentDir.createDir()
    doAssert zip.c.addr.mz_zip_reader_extract_to_file(i.mz_uint, dest, MZ_ZIP_FLAG_CASE_SENSITIVE.mz_uint) == MZ_TRUE
    return $dest

  # didn't find exact match, check for suffix match.
  var foundi = -1
  for i, f in zip:
    if f.endsWith(path):
      if result.len != 0:
        # if here, we've already found one result that matches. so we have an error.
        raise newException(KeyError, path & " ambiguous in zip archive")
      result = $f
      found_i = i

  if result.len == 0:
    raise newException(KeyError, path & " not found in zip archive")

  if destDir != "":
    result = destDir / zip.get_file_name(found_i)
  result.parentDir.createDir()
  doAssert zip.c.addr.mz_zip_reader_extract_to_file(found_i.mz_uint, result, 0) == MZ_TRUE
  return result
