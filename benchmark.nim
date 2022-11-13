import generator
import times, sugar, strformat, sequtils, stats, math

proc benchmarkGraphGen[T](name: string, testValues: seq[T], baseOpts: GraphOpts, optGenerator: (GraphOpts, T) -> GraphOpts) =
    echo fmt"Testing {name}"

    for i, variation in testValues:
        var times: array[0..9, int]

        let genResult = optGenerator(baseOpts, variation)

        for round in countup(0, 9):
            let t0 = getTime()

            if genResult.threads == 0 or genResult.threads == 1:
                discard generateImage(genResult)
            else:
                discard generateImageThreaded(genResult)

            let delta = getTime() - t0

            times[round] = delta.inMilliseconds.int

        let average = times.mean
        let stdDev = times.standardDeviationS

        echo &"\t #{i} {genResult}"
        echo &"\t -> yields average {average} ms with stdDev of {stdDev} ms."

proc resolutionGenerator(baseOpts: GraphOpts, iteration: int): GraphOpts =
    GraphOpts(
        xMin : baseOpts.xMin,
        xMax : baseOpts.xMax,
        yMin : baseOpts.yMin,
        yMax : baseOpts.yMax,
        threshold : baseOpts.threshold,
        maybeThreshold : baseOpts.maybeThreshold,
        subdivisions : baseOpts.subdivisions,
        threads : baseOpts.threads,
        showProgress : baseOpts.showProgress,
        width : 2^iteration,
        height : 2^iteration
    )

proc threadGenerator(baseOpts: GraphOpts, iteration: int): GraphOpts =
    GraphOpts(
        xMin : baseOpts.xMin,
        xMax : baseOpts.xMax,
        yMin : baseOpts.yMin,
        yMax : baseOpts.yMax,
        threshold : baseOpts.threshold,
        maybeThreshold : baseOpts.maybeThreshold,
        subdivisions : baseOpts.subdivisions,
        threads : 2^iteration,
        showProgress : baseOpts.showProgress,
        width : baseOpts.width,
        height : baseOpts.height
    )

proc benchmarkGraphResolution*(baseOpts: GraphOpts) =
    benchmarkGraphGen("Graph resolution", toSeq 0..12, baseOpts, resolutionGenerator)

proc benchmarkThreads*(baseOpts: GraphOpts) =
    benchmarkGraphGen("Thread count", toSeq 0..12, baseopts, threadGenerator)
