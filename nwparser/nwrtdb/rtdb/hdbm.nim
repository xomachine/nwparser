from nesm import serializable
from streams import Stream, atEnd
from tables import Table, initTable, `[]`, `[]=`
const cookie* = "hdbm v1.0"

serializable:
  type
    FileEntry* = object
      key_size: int32
      val_size: int32
      active*: bool
      padding: array[3, byte]
      key*: string {size: {}.key_size - 1}
      endkey: byte
      val*: seq[byte] {size: {}.val_size}# required a feature
    Header* = tuple
      cookie: string {size: cookie.len}
      endcookie: byte

type
  NotADBError* = object of Exception
  Entry* = object
    data*: seq[byte]
    active*: bool
  HDBM* = Table[string, Entry]

proc load*(input: Stream): HDBM =
  let head = Header.deserialize(input)
  if head.cookie != cookie:
    raise newException(NotADBError, "The file is not a database!")
  result = initTable[string, Entry]()
  while not input.atEnd:
    let fentry = FileEntry.deserialize(input)
    if fentry.active:
      let entry = Entry(data: fentry.val, active: fentry.active)
      result[fentry.key] = entry

