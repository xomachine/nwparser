
import pegs
import macros
from streams import Stream, readLine, atEnd
from structures import Calculation
from utils import associate
from nwzts import ZTS_header, readZTS

let ZTS_calc = peg(ZTS_header)

proc parseFile*(fd: Stream): seq[Calculation] =
  result = newSeq[Calculation]()
  while not fd.atEnd():
    let line = fd.readLine()
    associate(line, fd,
      ZTS_calc: readZTS)

