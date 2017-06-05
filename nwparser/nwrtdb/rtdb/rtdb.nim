from strutils import startsWith, `%`, join
from sequtils import mapIt
from tables import Table
from tables import initTable, pairs, rightSize, `[]`, `[]=`, len, contains
from nesm import serializable
from hdbm import HDBM

const info_header = "!rtdb!"
const MT_BASE = 1000

serializable:
  static:
    type DataType* = enum
      Undefined
      Char = MT_BASE
      Integer
      LongInteger
      Float
      Double
      LongDouble
      SPComplex
      DPComplex
      LongDPComplex
      FortByte
      FortInteger
      FortLogical
      FortReal
      FortDP
      FortSPComplex
      FortDPComplex
    type InfoStruct = object
      ma_type: uint32
      #spacer: array[2, byte]
      nelements: uint32
      date: array[26, char]

type
  UndefinedDataError = object of Exception
  Element* = object
    nelements*: Natural
    kind*: DataType
    last_changed*: string
    data: seq[byte]
  RTDB* = Table[string, Element]

proc toRTDB*(hdbm: HDBM): RTDB =
  result = initTable[string, Element](rightSize(hdbm.len div 2))
  for k, v in hdbm.pairs():
    if k.startsWith(info_header):
      #echo "Encountered info section: " & k
      #echo $v.active
      let info = InfoStruct.deserialize(v.data)
      #echo "Data: " & $info
      let realKey = k[info_header.len..^1]
      if realKey notin result:
        result[realKey] = Element(nelements: 0, last_changed: "",
                                  kind: Undefined, data: @[])
      result[realKey].nelements = info.nelements
      result[realKey].kind = DataType(info.ma_type)
      #result[realKey].last_changed = newString(info.date.len)
      result[realKey].last_changed = $cast[cstring](info.date[0].unsafeAddr)
      #copyMem(result[realKey].last_changed[0].addr, info.date[0].unsafeAddr,
      #        info.date.len - 1)
    else:
      if k notin result:
        result[k] = Element(nelements: 0, last_changed: "",
                            kind: Undefined, data: @[])
      result[k].data = v.data

proc getKeyAs*[T](self: RTDB, key: string): seq[T] | string =
  let element = self[key]
  when T is string:
    result = newString(element.nelements)
  else:
    assert((element.data.len == T.sizeof * element.nelements),
           "Size of data is not equals size of type expected")
    result = newSeq[T](element.nelements)
  for i in 0..<element.nelements:
    copyMem(result[i].addr, element.data[i*T.sizeof].unsafeAddr, T.sizeof)

proc stringify[T](a: seq[byte], maxnum: Natural): string =
  result = ""
  for i in 0..<maxnum:
    result.add($(cast[ptr T](a[i*sizeof(T)].unsafeAddr)[]) & ", ")

proc `$`*(e: Element): string =
  let last = min(e.nelements, 5)
  #assert(e.data.len mod e.nelements == 0, "Kind: $1, len: $2, nelem: $3" %
  #       [$e.kind, $e.data.len, $e.nelements])
  if e.nelements == 0:
    "Empty"
  else:
    let esize = e.data.len div e.nelements
    case e.kind:
    of Char:
      $cast[cstring](e.data[0].unsafeAddr)
    of Double, FortDP, LongDouble:
      assert(float64.sizeof == esize, "Kind: $1, size: $2" % [$e.kind, $esize])
      stringify[float64](e.data, last)
    of Integer, LongInteger, FortInteger:
      assert(int64.sizeof == esize, "Kind: $1, size: $2" % [$e.kind, $esize])
      stringify[int64](e.data, last)
    of FortReal, Float:
      assert(float32.sizeof == esize, "Kind: $1, size: $2" % [$e.kind, $esize])
      stringify[float32](e.data, last)
    of FortLogical:
      stringify[bool](e.data, last)
    of FortByte:
      cast[cstring](e.data[0].unsafeAddr).repr
    else:
      "Undefined"

