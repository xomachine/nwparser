from rtdb.hdbm import load
from rtdb.rtdb import toRTDB, getKeyAs, `$`
from dbgeometry import readGeometry
from structures import Calculation, CalcType, Mode, PESPoint
from units import ReversedCM, Bohr
from streams import Stream
from strutils import repeat
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
    let nbeads = getKeyAs[int64](db, operation & ":nbeads")[0]
    result[0].path = newSeq[PESPoint](nbeads)
    for i in 1..nbeads:
      let istr = $i
      let beadname = "bead_" & "0".repeat(6-istr.len) & istr & ":geom"
      result[0].path[i-1] =
        PESPoint(geometry: db.readGeometry(beadname), energy: 0.0.Hartree)
  else:
    quit("Unsupported operation: " & operation)

