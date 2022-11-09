import generator, constants
import times, sugar, strformat, sequtils, stats, math

type
    GenResult = object
        prettyStr*: string
        opts*: GraphOpts

proc benchmarkGraphGen[T](testValues: seq[T], optGenerator: (T) -> GenResult) =
    for i, variation in testValues:
        var times: array[0..9, int]

        var prettyGen: string
        for round in countup(0, 9):
            let t0 = getTime()

            let genResult = optGenerator(variation)
            prettyGen = genResult.prettyStr

            discard generateImage(genResult.opts)

            let delta = getTime() - t0

            times[round] = delta.inMilliseconds.int

        let average = times.mean
        let stdDev = times.standardDeviationS

        echo fmt"#{i} {prettyGen} yields average {average} ms with stdDev of {stdDev} ms."


            # let opts = GraphOpts(xMin : X_MIN,
            #                     xMax : X_MAX,
            #                     yMin : Y_MIN,
            #                     yMax : Y_MAX,
            #                     threshold : THRESHOLD,
            #                     maybeThreshold : MAYBE_THRESHOLD,
            #                     subdivisions : 0,
            #                     width : 2^exponent,
            #                     height : 2^exponent)

proc resolutionGenerator(iteration: int): GenResult =
    GenResult(
        prettyStr : fmt"Resolution {2^iteration} x {2^iteration}",
        opts : GraphOpts(
            xMin : X_MIN,
            xMax : X_MAX,
            yMin : Y_MIN,
            yMax : Y_MAX,
            threshold : THRESHOLD,
            maybeThreshold : MAYBE_THRESHOLD,
            subdivisions : 0,
            width : 2^iteration,
            height : 2^iteration
        )
    )

proc benchmarkGraphResolution* =
    benchmarkGraphGen(toSeq 0..12, resolutionGenerator)