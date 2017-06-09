
import pegs
import macros
from streams import Stream, readLine, atEnd
from structures import Calculation
from utils import associate
from nwzts import ZTSHeader, readZTS
from nwfreq import FreqHeader, readFreq


proc parseFile*(fd: Stream): seq[Calculation] =
  let ZTSCalc {.global.} = peg(ZTSHeader)
  let FreqCalc {.global.} = peg(FreqHeader)
  result = newSeq[Calculation]()
  while not fd.atEnd():
    let line = fd.readLine()
    associate(line, fd,
      ZTSCalc: readZTS,
      FreqCalc: readFreq)

