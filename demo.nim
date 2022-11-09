import times, pixie, os
import graphConstants, benchmark, graphImageGen

benchmarkGraphResolution()

let t0 = getTime()
let opts = GraphOpts(xMin : X_MIN,
                     xMax : X_MAX,
                     yMin : Y_MIN,
                     yMax : Y_MAX,
                     threshold : THRESHOLD,
                     maybeThreshold : MAYBE_THRESHOLD,
                     subdivisions : 0,
                     width : 1024,
                     height : 1024)

let image = generateImage(opts)
let delta = (getTime() - t0).inMilliseconds

echo "Wrote image in ", delta, " ms."

image.writeFile("output.png")
discard execShellCmd("open output.png")