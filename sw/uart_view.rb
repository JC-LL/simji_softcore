require "gnuplot"

samples=IO.readlines("samples.txt").map(&:to_i)
puts "got #{samples.size} samples"

Gnuplot.open do |gp|
  Gnuplot::Plot.new(gp) do |plot|

    plot.title  "Values from UART"
    plot.xlabel "x"
    plot.ylabel "sin(x)"

    x = (0..samples.size-1).to_a.map(&:to_f)
    y = samples

    plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
      ds.with = "linespoints"
      ds.notitle
    end

  end
end
