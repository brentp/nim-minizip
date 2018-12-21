{.compile: "miniz.c".}

type
  mz_uint8* = cuchar
  mz_int16* = cshort
  mz_uint16* = cushort
  mz_uint32* = cuint
  mz_uint* = cuint
  mz_int64* = int64
  mz_uint64* = uint64
  mz_bool* = cint

const
  MZ_FALSE* = (0)
  MZ_TRUE* = (1)

type
  mz_file_read_func* = proc (pOpaque: pointer; file_ofs: mz_uint64; pBuf: pointer;
                          n: csize): csize
  mz_file_write_func* = proc (pOpaque: pointer; file_ofs: mz_uint64; pBuf: pointer;
                           n: csize): csize
  mz_file_needs_keepalive* = proc (pOpaque: pointer): mz_bool
  mz_zip_internal_state_tag* {.bycopy.} = object

  mz_zip_internal_state* = mz_zip_internal_state_tag
  mz_zip_mode* = enum
    MZ_ZIP_MODE_INVALID = 0, MZ_ZIP_MODE_READING = 1, MZ_ZIP_MODE_WRITING = 2,
    MZ_ZIP_MODE_WRITING_HAS_BEEN_FINALIZED = 3
  mz_zip_flags* = enum
    MZ_ZIP_FLAG_CASE_SENSITIVE = 0x00000100, MZ_ZIP_FLAG_IGNORE_PATH = 0x00000200,
    MZ_ZIP_FLAG_COMPRESSED_DATA = 0x00000400,
    MZ_ZIP_FLAG_DO_NOT_SORT_CENTRAL_DIRECTORY = 0x00000800, MZ_ZIP_FLAG_VALIDATE_LOCATE_FILE_FLAG = 0x00001000, ##  if enabled, mz_zip_reader_locate_file() will be called on each file as its validated to ensure the func finds the file in the central dir (intended for testing)
    MZ_ZIP_FLAG_VALIDATE_HEADERS_ONLY = 0x00002000, ##  validate the local headers, but don't decompress the entire file and check the crc32
    MZ_ZIP_FLAG_WRITE_ZIP64 = 0x00004000, ##  always use the zip64 file format, instead of the original zip file format with automatic switch to zip64. Use as flags parameter with mz_zip_writer_init*_v2
    MZ_ZIP_FLAG_WRITE_ALLOW_READING = 0x00008000,
    MZ_ZIP_FLAG_ASCII_FILENAME = 0x00010000
  mz_zip_type* = enum
    MZ_ZIP_TYPE_INVALID = 0, MZ_ZIP_TYPE_USER, MZ_ZIP_TYPE_MEMORY, MZ_ZIP_TYPE_HEAP,
    MZ_ZIP_TYPE_FILE, MZ_ZIP_TYPE_CFILE, MZ_ZIP_TOTAL_TYPES

##  miniz error codes. Be sure to update mz_zip_get_error_string() if you add or modify this enum.

type
  mz_zip_error* = enum
    MZ_ZIP_NO_ERROR = 0, MZ_ZIP_UNDEFINED_ERROR, MZ_ZIP_TOO_MANY_FILES,
    MZ_ZIP_FILE_TOO_LARGE, MZ_ZIP_UNSUPPORTED_METHOD,
    MZ_ZIP_UNSUPPORTED_ENCRYPTION, MZ_ZIP_UNSUPPORTED_FEATURE,
    MZ_ZIP_FAILED_FINDING_CENTRAL_DIR, MZ_ZIP_NOT_AN_ARCHIVE,
    MZ_ZIP_INVALID_HEADER_OR_CORRUPTED, MZ_ZIP_UNSUPPORTED_MULTIDISK,
    MZ_ZIP_DECOMPRESSION_FAILED, MZ_ZIP_COMPRESSION_FAILED,
    MZ_ZIP_UNEXPECTED_DECOMPRESSED_SIZE, MZ_ZIP_CRC_CHECK_FAILED,
    MZ_ZIP_UNSUPPORTED_CDIR_SIZE, MZ_ZIP_ALLOC_FAILED, MZ_ZIP_FILE_OPEN_FAILED,
    MZ_ZIP_FILE_CREATE_FAILED, MZ_ZIP_FILE_WRITE_FAILED, MZ_ZIP_FILE_READ_FAILED,
    MZ_ZIP_FILE_CLOSE_FAILED, MZ_ZIP_FILE_SEEK_FAILED, MZ_ZIP_FILE_STAT_FAILED,
    MZ_ZIP_INVALID_PARAMETER, MZ_ZIP_INVALID_FILENAME, MZ_ZIP_BUF_TOO_SMALL,
    MZ_ZIP_INTERNAL_ERROR, MZ_ZIP_FILE_NOT_FOUND, MZ_ZIP_ARCHIVE_TOO_LARGE,
    MZ_ZIP_VALIDATION_FAILED, MZ_ZIP_WRITE_CALLBACK_FAILED, MZ_ZIP_TOTAL_ERRORS



##  Heap allocation callbacks.
## Note that mz_alloc_func parameter types purpsosely differ from zlib's: items/size is size_t, not unsigned long.

type
  mz_alloc_func* = proc (opaque: pointer; items: csize; size: csize): pointer #{.cdecl.}
  mz_free_func* = proc (opaque: pointer; address: pointer) #{.cdecl.}
  mz_realloc_func* = proc (opaque: pointer; address: pointer; items: csize; size: csize): pointer #{.cdecl.}
  mz_zip_archive* {.bycopy.} = object
    m_archive_size*: mz_uint64
    m_central_directory_file_ofs*: mz_uint64 ##  We only support up to UINT32_MAX files in zip64 mode.
    m_total_files*: mz_uint32
    m_zip_mode*: mz_zip_mode
    m_zip_type*: mz_zip_type
    m_last_error*: mz_zip_error
    m_file_offset_alignment*: mz_uint64
    m_pAlloc*: mz_alloc_func
    m_pFree*: mz_free_func
    m_pRealloc*: mz_realloc_func
    m_pAlloc_opaque*: pointer
    m_pRead*: mz_file_read_func
    m_pWrite*: mz_file_write_func
    m_pNeeds_keepalive*: mz_file_needs_keepalive
    m_pIO_opaque*: pointer
    m_pState*: ptr mz_zip_internal_state

proc mz_zip_get_error_string*(mz_err: mz_zip_error): cstring {.cdecl, importc.}
proc mz_zip_get_last_error*(pZip: ptr mz_zip_archive): mz_zip_error {.cdecl, importc.}

proc mz_zip_reader_locate_file*(pZip: ptr mz_zip_archive; pName: cstring;
                               pComment: cstring; flags: mz_uint): cint {.cdecl, importc.}
proc mz_zip_reader_init_file*(pZip: ptr mz_zip_archive; pFilename: cstring;
                             flags: mz_uint32): mz_bool {.cdecl, importc.}
##  The FILE will NOT be closed when mz_zip_reader_end() is called.
##  Ends archive reading, freeing all allocations, and closing the input archive file if mz_zip_reader_init_file() was used.

proc mz_zip_reader_end*(pZip: ptr mz_zip_archive): mz_bool {.cdecl, importc.}
proc mz_zip_get_mode*(pZip: ptr mz_zip_archive): mz_zip_mode {.cdecl, importc.}
proc mz_zip_reader_get_num_files*(pZip: ptr mz_zip_archive): mz_uint {.cdecl, importc.}
proc mz_zip_reader_is_file_a_directory*(pZip: ptr mz_zip_archive;
                                       file_index: mz_uint): mz_bool {.cdecl, importc.}
proc mz_zip_reader_get_filename*(pZip: ptr mz_zip_archive; file_index: mz_uint;
                                pFilename: cstring; filename_buf_size: mz_uint): mz_uint {.
    cdecl, importc.}
proc mz_zip_reader_extract_to_file*(pZip: ptr mz_zip_archive; file_index: mz_uint;
                                   pDst_filename: cstring; flags: mz_uint): mz_bool {.
    cdecl, importc.}
##  Universal end function - calls either mz_zip_reader_end() or mz_zip_writer_end().

proc mz_zip_writer_init_file*(pZip: ptr mz_zip_archive; pFilename: cstring;
                             size_to_reserve_at_beginning: mz_uint64): mz_bool {.
    cdecl, importc.}
##  For archives opened using mz_zip_reader_init_file, pFilename must be the archive's filename so it can be reopened for writing. If the file can't be reopened, mz_zip_reader_end() will be called.

proc mz_zip_writer_add_file*(pZip: ptr mz_zip_archive; pArchive_name: cstring;
                            pSrc_filename: cstring; pComment: pointer;
                            comment_size: mz_uint16; level_and_flags: mz_uint): mz_bool {.
    cdecl, importc.}
proc mz_zip_writer_finalize_archive*(pZip: ptr mz_zip_archive): mz_bool {.cdecl, importc.}
proc mz_zip_writer_end*(pZip: ptr mz_zip_archive): mz_bool {.cdecl, importc.}
