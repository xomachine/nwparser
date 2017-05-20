
import pegs
import macros
from streams import Stream, readLine, atEnd
from structures import Calculation
from utils import associate
from nwzts import ZTSHeader, readZTS
from nwfreq import FreqHeader, readFreq

let ZTSCalc = peg(ZTSHeader)
let FreqCalc = peg(FreqHeader)

proc parseFile*(fd: Stream): seq[Calculation] =
  result = newSeq[Calculation]()
  while not fd.atEnd():
    let line = fd.readLine()
    associate(line, fd,
      ZTSCalc: readZTS,
      FreqCalc: readFreq)

