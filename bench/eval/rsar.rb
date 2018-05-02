require 'csv'
require 'gnuplot'

MODE_NONE = 0
MODE_CPU = 1
MODE_DISKB = 2

class Sar
  def setGraphCommonSetting(plot, name)
    plot.title "#{name}"
    plot.style "data lines"
    plot.terminal "png size 1500, 1000"
    plot.xdata "time"
    plot.timefmt "'%H:%M:%S'"
    plot.format "x '%H:%M:%S'"
    #plot.xtics 10
    plot.grid
    plot.output "#{name}.png"
    plot.multiplot
  end

  def push_value(type, value)
    eval "@#{type} << value"
  end
end

class PgBench < Sar
  def initialize
    @time = []
    @tps = []
    @latency = []
  end
  attr_accessor :time, :tps, :latency

  def gen_graph
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|

        setGraphCommonSetting(plot, "pgbench")
        plot.xlabel "Time"
        plot.ylabel "TPS"
        plot.y2label "Latency (ms)"
        plot.set "y2tics"
        plot.style "data lines"

        plot.data << Gnuplot::DataSet.new([@time, @tps, @latency]) do |ds|
          ds.using = "1:2"
          ds.title = "tps"
        end
        plot.data << Gnuplot::DataSet.new([@time, @tps, @latency]) do |ds|
          ds.using = "1:3 axis x1y2"
          ds.title = "latency avg"
        end
      end
    end
  end
end

class Pg < Sar
  def initialize
    @time = []
    @live_tup = []
    @dead_tup = []
    @dead_tup_ratio = []
    @relsize = []
  end
  attr_accessor :time, :live_tup, :dead_tup, :dead_tup_ratio, :relsize
  
  def gen_graph
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|

        setGraphCommonSetting(plot, "pg-tup")
        plot.xlabel "Time"
        plot.ylabel "# of tuples"
        plot.y2label "Dead Tuple Ratio (%)"
        #plot.y2range "[0:100]"
        plot.set "y2tics"
        plot.style "data lines"

        plot.data << Gnuplot::DataSet.new([@time, @dead_tup, @dead_tup_ratio]) do |ds|
          ds.using = "1:2"
          ds.title = "n_dead_tup"
        end
        plot.data << Gnuplot::DataSet.new([@time, @dead_tup, @dead_tup_ratio]) do |ds|
          ds.using = "1:3 axis x1y2"
          ds.title = "n_dead_tup ratio"
        end
      end
    end
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|

        setGraphCommonSetting(plot, "pg-rel")
        plot.xlabel "Time"
        plot.ylabel "Relation Size (MB)"
        plot.style "data lines"

        plot.data << Gnuplot::DataSet.new([@time, @relsize]) do |ds|
          ds.using = "1:2"
          ds.title = "Relation Size"
        end
      end
    end
  end
end

class DiskB < Sar
  def initialize
    @time = []
    @tps = []
    @rtps = []
    @wtps = []
    @bread = []
    @bwrtn = []
  end

  def gen_graph
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|

        setGraphCommonSetting(plot, "disk")

        plot.xlabel "Time"
        plot.ylabel "Usage"

        plot.data << Gnuplot::DataSet.new([@time, @rtps]) do |ds|
          ds.using = "1:2"
          ds.title = "rtps"
        end
        plot.data << Gnuplot::DataSet.new([@time, @wtps]) do |ds|
          ds.using = "1:2"
          ds.title = "wtps"
        end
      end
    end
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|

        setGraphCommonSetting(plot, "disk-block")

        plot.xlabel "Time"
        plot.ylabel "Usage"

        plot.data << Gnuplot::DataSet.new([@time, @bread]) do |ds|
          ds.using = "1:2"
          ds.title = "bread/s"
        end
        plot.data << Gnuplot::DataSet.new([@time, @bwrtn]) do |ds|
          ds.using = "1:2"
          ds.title = "bwrtn/s"
        end
      end
    end
  end

  attr_accessor :time, :tps, :rtps, :wtps, :bread, :bwrtn
end

class Cpu < Sar
  def initialize
    @time = []
    @usr = []
    @sys = []
    @iowait = []
    @idle = []
  end

  def gen_graph
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|

        setGraphCommonSetting(plot, "cpu")
        plot.xlabel "Time"
        plot.ylabel "Usage"

        plot.style "data lines"

        plot.data << Gnuplot::DataSet.new([@time, @usr]) do |ds|
          ds.using = "1:2"
          ds.title = "usr"
        end
        plot.data << Gnuplot::DataSet.new([@time, @sys]) do |ds|
          ds.using = "1:2"
          ds.title = "sys"
        end
        plot.data << Gnuplot::DataSet.new([@time, @iowait]) do |ds|
          ds.using = "1:2"
          ds.title = "iowait"
        end
      end
    end
  end

  attr_accessor :time, :usr, :sys, :iowait, :idle
end

cpu_header = "CPU      %usr     %nice      %sys   %iowait    %steal      %irq     %soft    %guest    %gnice     %idl"
diskb_header = "tps      rtps      wtps   bread/s   bwrtn/s"
pg_header = "time,relname,n_live_tup,n_dead_tup,dead_tuple_ratio,relsize,relsize_pretty,vacuum_count,autovacuum_count"
cpu_header_found = false

cpu = Cpu.new
diskb = DiskB.new
pg = Pg.new
pgbench = PgBench.new

puts "start reading #{ARGV[0]}.."
lineno = 0
mode = MODE_NONE
File.open(ARGV[0]) do |file|
  file.each_line do |line|

    lineno = lineno + 1
    if lineno % 100000 == 0 then
      puts "read #{lineno}.."
    end

    if  mode == MODE_CPU then
      # Skip indivisual cpu stats
      next if line !~ /all/

      # End of cpu stats
      if line =~ /Average/ then
        mode = MODE_NONE
        next
      end

      cpu_array = line.split(" ")
      cpu.push_value("time", cpu_array[0])
      cpu.push_value("usr", cpu_array[3])
      cpu.push_value("sys", cpu_array[5])
      cpu.push_value("iowait", cpu_array[6])
      cpu.push_value("idle", cpu_array[12])
      next
    end

    if mode == MODE_DISKB then

      if line =~ /Average/ then
        mode = MODE_NONE
        next
      end

      disk_array = line.split(" ")
      diskb.push_value("time", disk_array[0])
      diskb.push_value("tps", disk_array[2])
      diskb.push_value("rtps", disk_array[3])
      diskb.push_value("wtps", disk_array[4])
      diskb.push_value("bread", disk_array[5])
      diskb.push_value("bwrtn", disk_array[6])
      next
    end

    case line
      when /#{cpu_header}/ then
      	mode = MODE_CPU
      when /#{diskb_header}/ then
      	mode = MODE_DISKB
      else
      	mode = MODE_NONE
    end
  end
end
puts "completed to parse #{ARGV[0]}."

# Postgres monitoring file
puts "start reading #{ARGV[1]}.."
lineno = 0
File.open(ARGV[1]) do |file|
  file.each_line do |line|

    lineno = lineno + 1
    if lineno % 100000 == 0 then
      puts "read #{lineno}.."
    end

    # skip header line
    next if line =~ /#{pg_header}/

    pg_array = line.split(",")
    pg.push_value("time", pg_array[0])
    pg.push_value("live_tup", pg_array[2])
    pg.push_value("dead_tup", pg_array[3])
    pg.push_value("dead_tup_ratio", pg_array[4])
    pg.push_value("relsize", pg_array[5])
  end
end

puts "completed to parse #{ARGV[1]}."

# Pgbench file
lineno = 0
File.open(ARGV[2]) do |file|
  file.each_line do |line|

    lineno = lineno + 1
    if lineno % 100000 == 0 then
      puts "read #{lineno}.."
    end

    pgbench_array = line.split(" ")
    
    datetime = Time.at(pgbench_array[0].to_i).strftime("%H:%M:%S")
    tps = pgbench_array[1]
    latency = (pgbench_array[2]).to_f / tps.to_f
    
    pgbench.push_value("time", datetime.to_s)
    pgbench.push_value("tps", tps.to_s)
    pgbench.push_value("latency", latency.to_s)
  end
end

cpu.gen_graph
diskb.gen_graph
pg.gen_graph
pgbench.gen_graph
puts "done."


