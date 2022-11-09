# nimble install pixie
# nimble install argparse

import times, pixie, os, argparse, strformat
import constants, benchmark, generator

var parser = newParser:
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

    flag("-b", "--benchmark", help="Run benchmarks against this program.")

let arguments = parser.parse(commandLineParams())

benchmarkGraphResolution()

let t0 = getTime()
let opts = GraphOpts(xMin : parseFloat(arguments.xmin),
                     xMax : parseFloat(arguments.xmax),
                     yMin : parseFloat(arguments.ymin),
                     yMax : parseFloat(arguments.ymax),
                     threshold : parseFloat(arguments.threshold),
                     maybeThreshold : parseFloat(arguments.maybeThreshold),
                     subdivisions : parseInt(arguments.subdivisions),
                     width : parseInt(arguments.width),
                     height : parseInt(arguments.height))

let image = generateImage(opts)
let delta = (getTime() - t0).inMilliseconds

echo "Generated image in ", delta, " ms."

image.writeFile(arguments.output)
discard execShellCmd(fmt"open {arguments.output}")