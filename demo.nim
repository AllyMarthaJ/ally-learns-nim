# nimble install pixie
# nimble install argparse

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

            let image = generateImage(o)

            image.writeFile(opts.output)
            discard execShellCmd(fmt"open {opts.output}")

    command("benchmark"):
        flag("-r", "--resolution")
        run:
            if opts.resolution:
                benchmarkGraphResolution()

parser.run(commandLineParams())