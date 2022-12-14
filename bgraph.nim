# nimble install pixie
# nimble install argparse

# Graphing program parameters.
# Subdivision algorithm brought to you by Bunny https://github.com/Ebony-Ayers
# The x, X, y, Y, w, h, o, p parameters are fairly explanatory.
# So why do we care about a 'threshold' and 'maybeThreshold' and 'subdivisions'?
# And how the heck does resolution affect it?
# Off the bat: Higher the resolution, the more details you can trick a person into
# thinking exist on the picture. It also increases the time take to render the image.
# The threshold determines the overall accuracy of the image. The bulk of the pixels
# rendered will be caught by this threshold (i.e. abs(fn)<=threshold).
# The lower the threshold, the fewer pixels rendered. This can create a rather choppy
# effect. This is where maybeThreshold comes in: a value which is higher than threshold,
# but if it is met, it will subdivide the area around the pixel in question, and then
# do the standard threshold comparison. (Hence where subdivisions come in)
# This is the most time consuming part; the more subdivisions and higher the maybeThreshold,
# the more pixel checking you have to do.
# In general:
#   If you lower the threshold, up the subdivisions.
#   If you up the maybeThreshold, lower the subdivisions.
#   If you decrease the resolution, up the subdivisions or lower the maybeThreshold.
#   I think... X * resolution -> subdivisions / X
#   A difference of 10^2 or 10^3 between threshold and maybeThreshold should be sufficient.

import times, pixie, os, argparse, strformat
import bgraph / [constants, benchmark, generator, decorator]

export generator

var parser = newParser:
    option("-x", "--xmin", "Minimum x value to plot", some($X_MIN))
    option("-X", "--xmax", "Maximum x value to plot", some($X_MAX))
    option("-y", "--ymin", "Minimum y value to plot", some($Y_MIN))
    option("-Y", "--ymax", "Maximum y value to plot", some($Y_MAX))
    option("-t", "--threshold", "Threshold at which to flag a zero at immediately",
            some($THRESHOLD))
    option("-m", "--maybeThreshold", "Threshold at which to flag subdivision to search for potential zeroes",
            some($MAYBE_THRESHOLD))
    option("-s", "--subdivisions", "Number of subdivisions to do to find zeroes",
            some($SUBDIVISIONS))
    option("-w", "--width", "Width of the image to plot", some($WIDTH))
    option("-h", "--height", "Height of the image to plot", some($HEIGHT))
    option("-tc", "--threadCount", "Number of threads to use.", some($THREAD_COUNT))
    flag("-p", "--showProgress", false, "Show the progress of the generation")

    command("generate"):
        # TODO: Make these parents. We can have benchmark overrides to test w/ different values.
        option("-o", "--output", "File name of the output image", some("output.png"))
        flag("-O", "--openOutput", false, "Open the output file when complete")

        run:
            let o = GraphOpts(xMin: parseFloat(opts.parentOpts.xmin),
                                xMax: parseFloat(opts.parentOpts.xmax),
                                yMin: parseFloat(opts.parentOpts.ymin),
                                yMax: parseFloat(opts.parentOpts.ymax),
                                threshold: parseFloat(
                                        opts.parentOpts.threshold),
                                maybeThreshold: parseFloat(
                                        opts.parentOpts.maybeThreshold),
                                subdivisions: parseInt(
                                        opts.parentOpts.subdivisions),
                                width: parseInt(opts.parentOpts.width),
                                height: parseInt(opts.parentOpts.height),
                                showProgress: opts.parentOpts.showProgress,
                                threads: parseInt(opts.parentOpts.threadCount))

            let t0 = getTime()

            let image = case opts.parentOpts.threadCount
                of $0: generateImage(o)
                of $1: generateImage(o)
                else: generateImageThreaded(o)

            let delta = (getTime() - t0).inMilliseconds
            if not opts.parentOpts.showProgress:
                echo "Finished rendering image in ", delta, " ms."

            let data: DataOpts = DataOpts(
                showXAxis: true,
                showYAxis: true,
                showXGrid: true,
                showYGrid: true,
                showAttribution: true,
                xInc: 0.1,
                yInc: 0.1,
                fontFile: "bin/ComicCode-Medium.otf",
                axisColor: "#000000",
                axisWidth: 20,
                gridColor: "#000000",
                gridWidth: 1,
                author: "Ally",

            )
            # decorateGraph(data, o, image.unsafeAddr)

            image.writeFile(opts.output)
            if opts.openOutput:
                try:
                    discard execShellCmd(fmt"open {opts.output}")
                except:
                    echo "Couldn't open the output file, ",
                            getCurrentExceptionMsg()

    command("benchmark"):
        flag("-r", "--resolution")
        flag("-t", "--threads")

        run:
            let o = GraphOpts(xMin: parseFloat(opts.parentOpts.xmin),
                            xMax: parseFloat(opts.parentOpts.xmax),
                            yMin: parseFloat(opts.parentOpts.ymin),
                            yMax: parseFloat(opts.parentOpts.ymax),
                            threshold: parseFloat(opts.parentOpts.threshold),
                            maybeThreshold: parseFloat(
                                    opts.parentOpts.maybeThreshold),
                            subdivisions: parseInt(
                                    opts.parentOpts.subdivisions),
                            width: parseInt(opts.parentOpts.width),
                            height: parseInt(opts.parentOpts.height),
                            showProgress: opts.parentOpts.showProgress,
                            threads: parseInt(opts.parentOpts.threadCount))
            if opts.resolution:
                benchmarkGraphResolution(o)
            if opts.threads:
                benchmarkThreads(o)

parser.run(commandLineParams())
