import times, math, strutils, sequtils, strformat, pixie, os, sugar, graphImageGen

const X_MIN: float = -1
const X_MAX: float = 1
const Y_MIN: float = -1
const Y_MAX: float = 1

const THRESHOLD: float = 10.float.pow(-4)
const MAYBE_THRESHOLD: float = 10.float.pow(-1)

proc testFunctionImage =
    for exponent in countup(0, 15):
        var times: array[0..9, int64]

        for round in countup(0, 9):
            let t0 = getTime()

            let opts = GraphOpts(xMin : X_MIN,
                                xMax : X_MAX,
                                yMin : Y_MIN,
                                yMax : Y_MAX,
                                threshold : THRESHOLD,
                                maybeThreshold : MAYBE_THRESHOLD,
                                subdivisions : 0,
                                width : 2^exponent,
                                height : 2^exponent)
            discard generateImage(opts)

            let delta = getTime() - t0

            times[round] = delta.inMilliseconds

        let average = times.foldl(a + b, 0.int64).float / 10.0

        # echo 2^exponent, " -- ", "times: ", msg, "ms : ", average, "ms average"
        echo fmt"{2^exponent}x{2^exponent} yields average {average} ms."

testFunctionImage()
# let t0 = getTime()
# let opts = GraphOpts(xMin : X_MIN,
#                      xMax : X_MAX,
#                      yMin : Y_MIN,
#                      yMax : Y_MAX,
#                      threshold : THRESHOLD,
#                      maybeThreshold : MAYBE_THRESHOLD,
#                      subdivisions : 0,
#                      width : 1024,
#                      height : 1024)

# let image = generateImage(opts)
# let delta = (getTime() - t0).inMilliseconds

# echo "Wrote image in ", delta, " ms."

# image.writeFile("output.png")
# discard execShellCmd("open output.png")