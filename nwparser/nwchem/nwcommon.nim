
import pegs
import macros
from streams import Stream, readLine, atEnd
from structures import Calculation, CalcType
from utils import associate
from nwzts import ZTSHeader, readZTS
from nwfreq import FreqHeader, readFreq
from nwgeometry import findGeometry
from nwopt import OptHeader, readOpt


proc parseFile*(fd: Stream): seq[Calculation] =
  let ZTSCalc {.global.} = peg(ZTSHeader)
  let FreqCalc {.global.} = peg(FreqHeader)
  let OptCalc {.global.} = peg(OptHeader)
  result = newSeq[Calculation]()
  let initial = fd.findGeometry()
  while not fd.atEnd():
    let line = fd.readLine()
    associate(line, fd,
      ZTSCalc: readZTS,
      FreqCalc: readFreq,
      OptCalc: readOpt)
  for i in 0..<result.len:
    if result[i].kind != CalcType.MEP:
      result[i].initial = initial

