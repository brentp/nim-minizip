import ../minizip
import unittest
import strformat
import os
import times

const a_txt = "hello A from a.txt\n"
const b_txt = "hello B from b.txt\n"

proc make_zip() =
    var zip:Zip
    doAssert open(zip, "testing.zip", fmWrite)

    var tmp:File
    doAssert open(tmp, "a.txt", fmWrite)
    tmp.write(a_txt)
    tmp.close()
    doAssert open(tmp, "B.txt", fmWrite)
    tmp.write(b_txt)
    tmp.close()

    check zip.len == 0
    zip.add_file("a.txt", archivePath="ooo/a.txt")
    check zip.len == 1
    zip.add_file("B.txt", archivePath="ooo/B.txt")
    doAssert zip.len == 2

    removeFile("a.txt")
    removeFile("B.txt")

    zip.close()

suite "Zip Suite":
  test "that creating and a zip file works":
    var zip:Zip

    make_zip()

    check open(zip, "testing.zip", fmRead)
    check zip.len == 2

    expect KeyError:
      discard zip.extract_file("AA.txt")

    expect KeyError:
      # default is case sensitive.
      discard zip.extract_file("A.txt")

    check zip.extract_file("a.txt") == "ooo/a.txt"
    check fileExists("ooo/a.txt")
    check $("ooo/a.txt".readFile()) == a_txt

    check zip.extract_file("a.txt", destDir="ooo/ttt/") == "ooo/ttt/ooo/a.txt"
    check fileExists("ooo/ttt/ooo/a.txt")
    check $("ooo/ttt/ooo/a.txt".readFile()) == a_txt

    check zip.extract_file("B.txt", destDir="ooo/bbb/").readFile() == b_txt
    check fileExists("ooo/bbb/ooo/B.txt")

    removeDir("ooo")
    removeFile("testing.zip")


  test "that stream is ok":
    var zip:Zip

    make_zip()
    check open(zip, "testing.zip", fmRead)
    #var s = zip.extractFileToMemory("ooo/a.txt")
    #check s == a_txt
    #echo "|" & a_txt & "|"
    #echo "|" & s & "|"

  test "that buffer works":
    var zip:Zip
    doAssert open(zip, "testing.zip", fmWrite)

    var data = "asdfasdfasdfasdfasdf asdf asd fas dfasd fasdf asdf asdfasdf asdf asdf asdf asdf asdf asdf asdf asdf asdf asdf "
    data = data & data & data 
    data = data & data & data 
    data = data & data & data 
    data = data & data & data 
    data = data & data & data 
    data = data & data & data 
    data = data & data & data 

    var x:pointer
    var xlen = 0
    var n = 2000

    for i in 0..n:
      var apath = &"zipped/{i}.txt"
      doAssert zip.write_buffer(apath, data[0].addr.pointer, data.len, 1)

    zip.close()
    doAssert zip.open("testing.zip", fmRead)

    block:

      var s = newString(0)
      var t = cpuTime()

      for i in 0..n:
        var apath = &"zipped/{i}.txt"
        doAssert zip.read_buffer(apath, x.addr, xlen)
        doAssert xlen == data.len
        s.setLen(xlen)
        copyMem(s[0].addr.pointer, x, xlen)

        #doAssert s == data

      free(x)
      echo "buffer:", cpuTime() - t

    block:
      var t = cpuTime()
      var str = newSeq[char]()
      for i in 0..n:
        var apath = &"zipped/{i}.txt"
        doAssert zip.read_into(apath, str)

        doAssert str.len == data.len
        #doAssert str == data

      echo "seq:", cpuTime() - t

    block:
      var t = cpuTime()
      var str = newString(100)
      for i in 0..n:
        var apath = &"zipped/{i}.txt"
        doAssert zip.read_into(apath, str)

        doAssert str.len == data.len
        #doAssert str == data

      echo "string:", cpuTime() - t

    zip.close()


