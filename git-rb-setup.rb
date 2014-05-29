#!/usr/bin/env ruby

def die(*args)
  fmt = args.shift
  $stderr.printf("fatal: %s\n" % fmt, *args)
  exit 128
end

def sha1_to_hex(sha1)
  sha1.unpack('H*').first
end

class CommandError < RuntimeError

  def initialize(command)
     @command = command
  end

  def to_s
    Array(@command).join(' ').inspect
  end

end

def run(cmd, *args)
  system(*cmd, *args)
  raise CommandError.new(cmd) unless $?.success?
end

class String
  def skip_prefix(prefix)
    return self[prefix.length..-1]
  end
end

class ParseOpt
  attr_writer :usage

  class Option
    attr_reader :short, :long, :help

    def initialize(short, long, help, &block)
      @block = block
      @short = short
      @long = long
      @help = help
    end

    def call(v)
      @block.call(v)
    end
  end

  def initialize
    @list = {}
  end

  def on(short = nil, long = nil, help: nil, &block)
    opt = Option.new(short, long, help, &block)
    @list[short] = opt if short
    @list[long] = opt if long
  end

  def parse
    if ARGV.member?('-h') or ARGV.member?('--help')
      usage
      exit 0
    end
    seen_dash = false
    ARGV.delete_if do |cur|
      opt = val = nil
      next false if cur[0] != '-' or seen_dash
      case cur
      when '--'
        seen_dash = true
        next true
      when /^--no-(.+)$/
        opt = @list[$1]
        val = false
      when /^-([^-])(.+)?$/, /^--(.+?)(?:=(.+))?$/
        opt = @list[$1]
        val = $2 || true
      end
      if opt
        opt.call(val)
        true
      else
        usage
        exit 1
      end
    end
  end

  def usage
    def fmt(prefix, str)
      return str ? prefix + str : nil
    end
    puts 'usage: %s' % @usage
    @list.values.uniq.each do |opt|
      s = '    '
      s << ''
      s << [fmt('-', opt.short), fmt('--', opt.long)].compact.join(', ')
      s << ''
      s << '%*s%s' % [26 - s.size, '', opt.help] if opt.help
      puts s
    end
  end

end
