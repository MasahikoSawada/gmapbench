require 'date'

HOME = "/home/masahiko/pgsql"
TASKFILE = "#{HOME}/status/TASK"
TASKDONEFILE = "#{TASKFILE}.done"
STATUSFILE = "#{HOME}/status/STATUS"

module Status
  NONE = 0
  READY = 1
  RESTORE = 2
  RESTORE_DONE = 3
  BENCH = 4
  BENCH_DONE = 5
  PUSH = 6
  FAILED = 10
end

STATUS_NAME = {
  Status::NONE => "none",
  Status::READY => "ready",
  Status::RESTORE => "restore",
  Status::RESTORE_DONE => "restore done",
  Status::BENCH => "bench",
  Status::BENCH_DONE => "bench done",
  Status::PUSH => "push",
  Status::FAILED => "failed",
}

def status_text(status)
  STATUS_NAME[status]
end

def update_statusfile
  File.open(STATUSFILE, "w") do |file|
    $tasks.each do |task|
      stext = status_text(task.status)
      file.puts("#{task.taskname} : #{stext} : begin = #{task.start_time} : end = #{task.end_time} : last_change = #{task.last_status_change}")
    end
  end
end

class Task
  def initialize(taskname)
    @taskname = taskname
    @settings = {}
    @start_time = nil
    @end_time = nil
    @status = Status::NONE
    @last_status_change = nil
  end

  # Sanify parameter check
  def check_param
    if @settings.has_key?("base") and
        @settings.has_key?("restore") and
        @settings.has_key?("command") and
        @settings.has_key?("target") then
      return true
    end
    return false
  end

  # Update itself status and update STATUS file
  def update_status(status)
    @status = status
    @last_status_change = Time.now
    update_statusfile
  end

  # Restore!!
  def do_restore(base, target)
    puts "do restore #{base}, #{target}"
  end

  # Do benchmarking!!!!
  def dobench
    if !self.check_param then
      puts "argument error for task \"#{@taskname}\""
      update_status(Status::FAILED)
      return
    end

    # Passed sanity check. Okay, begin bench
    update_status(Status::READY)
    @start_time = Time.now

    # To abbreviate often-used variables
    base = @settings["base"]
    target = @settings["target"]
    
    if @settings["restore"] == "true" then
      update_status(Status::RESTORE)
      do_restore(base, target)
      update_status(Status::RESTORE_DONE)
    end

    #system("source ~/.bash_profile; use #{base}; stop #{target}")
    update_status(Status::BENCH)
    system("source ~/.bash_profile; #{@settings["command"]}")
    update_status(Status::BENCH_DONE)
    @end_time = Time.now
  end

  attr_accessor :taskname, :settings, :status, :start_time, :end_time, :last_status_change
end

## 0. Prepare
# Remove STATUS file
File.unlink(STATUSFILE) if File.exist?(STATUSFILE)

# git pull and update binary
system("git pull win master")
system("sh scripts/update_source.sh")

# Distributed conf file
system("sh /home/masahiko/pgsql/bench/conf/distribute.sh")

## 1. Parse TASKFILE
$tasks = []
task = nil
task_name = nil
File.open(TASKFILE) do |file|
  file.each_line do |line|

    next if line =~ /$^/

    if line =~ /\[.*\]/ then
      # Register previous task
      if !task.nil? then
        $tasks << task
      end

      task_name = line.split(/\[|\]/)[1]
      task = Task.new(task_name)
      next
    end

    if !task.nil? then
      splitted_line = line.split("=")
      key = splitted_line[0].strip
      value = splitted_line[1].strip.delete("\"")
      task.settings[key] = value
    end
  end
end

if !task.nil? then
  $tasks << task
end

## 2. Do bench
$tasks.each do |task|
  task.dobench
end

# Rename to .done file
File.rename(TASKFILE, TASKDONEFILE) if File.exist?(TASKFILE)
system("git add #{TASKDONEFILE}")
system("git commit -am \"TEST DONE\"")
system("git push win master")
