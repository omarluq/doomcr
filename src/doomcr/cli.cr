require "./doom_keys"
require "./platform"
require "./native"

class Doomcr::CLI
  DEFAULT_WAD_CANDIDATES = [
    "wads/freedoom1.wad",
    "wads/freedoom2.wad",
    "DOOM2.WAD",
    "doom2.wad",
    "doom1.wad",
    "DOOM1.WAD",
    "doom.wad",
    "DOOM.WAD",
    "freedoom1.wad",
    "freedoom2.wad",
    "FREEDOOM1.WAD",
    "FREEDOOM2.WAD",
    "iwads/doom1.wad",
    "iwads/doom2.wad",
    "shareware/doom1.wad",
  ]

  class ArgvBuffer
    getter argc : Int32
    getter argv : Pointer(Pointer(UInt8))

    @argv_strings : Array(String)
    @argv_ptrs : Array(Pointer(UInt8))

    def initialize(argv : Array(String))
      @argv_strings = argv.map(&.dup)
      @argv_ptrs = @argv_strings.map(&.to_unsafe)
      @argc = @argv_ptrs.size.to_i32
      @argv = @argv_ptrs.to_unsafe
    end
  end

  def self.run(args = ARGV)
    args = resolve_iwad_args(args)

    puts "Controls: arrows move, space/fire, e/use, esc/menu, Ctrl+Q quit wrapper"

    platform = Doomcr::Platform.new
    Doomcr::Native.prepare(platform)

    argv = ArgvBuffer.new(["doomcr"] + args)
    Doomcr::Native.create(argv.argc, argv.argv)

    until platform.quit_requested?
      Doomcr::Native.tick
    end
  rescue error : File::Error
    if error.message.to_s.includes?("/dev/tty")
      STDERR.puts "doomcr requires an interactive TTY terminal."
      exit 1
    end
    raise error
  ensure
    platform.try(&.close)
  end

  private def self.resolve_iwad_args(args : Array(String)) : Array(String)
    if index = iwad_arg_index(args)
      if index + 1 >= args.size
        STDERR.puts "Missing IWAD value: pass a file path after `-iwad`."
        exit 1
      end

      iwad_path = args[index + 1]
      if File.file?(iwad_path)
        return args
      end

      print_iwad_error(iwad_path)
      exit 1
    end

    if wad = default_wad
      return args + ["-iwad", wad]
    end

    print_iwad_error(nil)
    exit 1
  end

  private def self.iwad_arg_index(args : Array(String)) : Int32?
    args.each_with_index do |arg, idx|
      return idx if arg == "-iwad"
    end
    nil
  end

  private def self.default_wad : String?
    if env_wad = ENV["DOOM_WAD"]?
      return env_wad if File.file?(env_wad)
    end

    DEFAULT_WAD_CANDIDATES.each do |path|
      return path if File.file?(path)
    end

    nil
  end

  private def self.print_iwad_error(iwad_path : String?)
    if iwad_path
      if iwad_path == "/path/to/doom1.wad"
        STDERR.puts "IWAD path is still the placeholder `/path/to/doom1.wad`."
      else
        STDERR.puts "IWAD file not found: #{iwad_path}"
      end
    else
      STDERR.puts "No IWAD found."
    end

    STDERR.puts "Run with a real IWAD path, for example:"
    STDERR.puts "  doomcr -iwad /absolute/path/to/doom1.wad"
    STDERR.puts "Or set:"
    STDERR.puts "  export DOOM_WAD=/absolute/path/to/doom1.wad"
    STDERR.puts "Quick search command:"
    STDERR.puts "  find ~ -type f \\( -iname 'doom1.wad' -o -iname 'doom2.wad' -o -iname 'freedoom*.wad' \\) 2>/dev/null | head"

    nearby = nearby_wads
    unless nearby.empty?
      STDERR.puts "WAD-like files near this project:"
      nearby.each { |path| STDERR.puts "  - #{path}" }
    end
  end

  private def self.nearby_wads : Array(String)
    dirs = [".", "wads", "iwads", "shareware"]
    found = [] of String

    dirs.each do |dir|
      next unless Dir.exists?(dir)

      found.concat(Dir.glob("#{dir}/*.wad"))
      found.concat(Dir.glob("#{dir}/*.WAD"))
    end

    found.uniq.sort!
  end
end
