from rtdb.hdbm import load
from rtdb.rtdb import toRTDB, getKeyAs, `$`
from structures import Calculation, CalcType, Mode
from units import ReversedCM, Bohr
from streams import Stream
from sequtils import mapIt, filterIt, distribute

proc readDB*(fd: Stream): seq[Calculation] =
  let db = fd.load().toRTDB()
  result = newSeq[Calculation](1)
  let operation = getKeyAs[string](db, "task:operation")
  case operation
  of "freq":
    result[0].kind = CalcType.Frequency
    result[0].initial = db.readGeometry("geometry")
    let freqs = getKeyAs[float64](db, "vib:projected frequencies")
                  .mapIt(it.ReversedCM)
    let rank = freqs.len
    let intensities = getKeyAs[float64](db, "vib:projected intensities")
    let displsPerFreq = getKeyAs[float64](db, "mc_data:eigenvectors")
                          .distribute(rank)
    result[0].modes = newSeq[Mode](rank)
    assert rank mod 3 == 0
    let ndispls = rank div 3
    for i in 0..<rank:
      let displsPerFrame = displsPerFreq[i].distribute(ndispls)
      var displacements = newSeq[array[3, Bohr]](ndispls)
      for j in 0..<displsPerFrame.len:
        for k in 0..2:
          displacements[j][k] = displsPerFrame[j][k].Bohr
      result[0].modes[i] = (frequency: freqs[i], intensity: intensities[i],
                            displacements: displacements)
  of "neb", "string":
    result[0].kind = CalcType.MEP
    discard # TODO
  else:
    quit("Unsupported operation: " & operation)

