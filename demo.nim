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
import constants, benchmark, generator

var parser = newParser:
    command("generate"):
        # TODO: Make these parents. We can have benchmark overrides to test w/ different values.
        option("-x", "--xmin", "Minimum x value to plot", some($X_MIN))
        option("-X", "--xmax", "Maximum x value to plot", some($X_MAX))
        option("-y", "--ymin", "Minimum y value to plot", some($Y_MIN))
        option("-Y", "--ymax", "Maximum y value to plot", some($Y_MAX))
        option("-t", "--threshold", "Threshold at which to flag a zero at immediately", some($THRESHOLD))
        option("-m", "--maybeThreshold", "Threshold at which to flag subdivision to search for potential zeroes", some($MAYBE_THRESHOLD))
        option("-s", "--subdivisions", "Number of subdivisions to do to find zeroes", some($0))
        option("-w", "--width", "Width of the image to plot", some($1024))
        option("-h", "--height", "Height of the image to plot", some($1024))
        option("-o", "--output", "File name of the output image", some("output.png"))
        flag("-p", "--showProgress", false, "Show the progress of the generation")
        option("-tc", "--threadCount", "Number of threads to use.", some($1))

        run:
            let o = GraphOpts(xMin : parseFloat(opts.xmin),
                                xMax : parseFloat(opts.xmax),
                                yMin : parseFloat(opts.ymin),
                                yMax : parseFloat(opts.ymax),
                                threshold : parseFloat(opts.threshold),
                                maybeThreshold : parseFloat(opts.maybeThreshold),
                                subdivisions : parseInt(opts.subdivisions),
                                width : parseInt(opts.width),
                                height : parseInt(opts.height),
                                showProgress : opts.showProgress)

            let t0 = getTime()

            let image = case opts.threadCount
                of $0: generateImage(o)
                of $1: generateImage(o)
                else: generateImageThreaded(o, parseInt(opts.threadCount))

            let delta = (getTime() - t0).inMilliseconds
            if not opts.showProgress:
                echo "Finished rendering image in ", delta, " ms."

            image.writeFile(opts.output)
            discard execShellCmd(fmt"open {opts.output}")

    command("benchmark"):
        flag("-r", "--resolution")
        run:
            if opts.resolution:
                benchmarkGraphResolution()

parser.run(commandLineParams())