import generator, constants
import times, sugar, strformat, sequtils, stats, math

type
    GenResult = object
        prettyStr*: string
        opts*: GraphOpts
        threads*: int

proc benchmarkGraphGen[T](testValues: seq[T], optGenerator: (T) -> GenResult) =
    for i, variation in testValues:
        var times: array[0..9, int]

        var prettyGen: string
        for round in countup(0, 9):
            let t0 = getTime()

            let genResult = optGenerator(variation)
            prettyGen = genResult.prettyStr

            discard generateImageThreaded(genResult.opts, genResult.threads)

            let delta = getTime() - t0

            times[round] = delta.inMilliseconds.int

        let average = times.mean
        let stdDev = times.standardDeviationS

        echo fmt"#{i} {prettyGen} yields average {average} ms with stdDev of {stdDev} ms."

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
        ),
        threads : 1
    )

proc threadGenerator(iteration: int): GenResult =
    GenResult(
        prettyStr : fmt"{2^iteration} threads",
        opts : GraphOpts(
            xMin : X_MIN,
            xMax : X_MAX,
            yMin : Y_MIN,
            yMax : Y_MAX,
            threshold : 0.000001,
            maybeThreshold : 0.001,
            subdivisions : 80,
            width : 4096,
            height : 4096
        ),
        threads : 2^iteration
    )

proc benchmarkGraphResolution* =
    benchmarkGraphGen(toSeq 0..12, resolutionGenerator)

proc benchmarkThreads* =
    benchmarkGraphGen(toSeq 0..12, threadGenerator)
