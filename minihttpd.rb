#!/usr/bin/ruby -w
#
#  minihttpd.rb [-r] [-p <port>] [-l] [<rootpath>]
#
#  Minimal HTTP server for testing web pages.
#
#  -h, --help       Show help message
#  -r, --remote     Bind to INADDR_ANY instead of localhost
#  -p, --port=PORT  Bind to this port (default is 8888)
#  -l, --multilang  Enable support for multiple languages (see below)
#
#  Multilang
#
#  URLs of the form http://something/<lang>/foo.html will be rewritten
#  to look for the file <rootpath>/foo.html.<lang>.
#

require 'webrick'
require 'optparse'

#-----------------------------------------------------------------------
class MultiLangFileHandler < WEBrick::HTTPServlet::FileHandler

    def initialize(server, path)
        languages = ['de', 'en']
        super(server, path, :AcceptableLanguages => languages, :FancyIndexing => true)
        @lang_re = Regexp.new("^/(#{languages.join('|')})(/.*)$")
    end

    def do_GET(request, response)
        rpath = request.path
        if m = @lang_re.match(request.path)
            request.path_info = m[2] + '.' + m[1]
        end

        super(request, response)
    end

end
#-----------------------------------------------------------------------

# defaults
bind_address = 'localhost'
bind_port = 8888
rootpath = '.'
multilang = false

OptionParser.new do |opts|
    opts.banner = 'Usage: minihttpd.rb [-r] [-p <port>] [<rootpath>]'

    opts.on('-h', '--help', 'Print this help message') do
        puts opts
        exit 0
    end

    opts.on('-r', '--remote', 'Bind to INADDR_ANY instead of localhost') do
        bind_address = '0.0.0.0'
    end

    opts.on('-p', '--port PORT', Integer, 'TCP port (default: 8888)') do |port|
        bind_port = port.to_i
    end

    opts.on('-l', '--multilang', 'Support for multiple languages') do
        multilang = true
    end

end.parse!

if ARGV.size == 1
    rootpath = ARGV[0]
elsif ARGV.size > 1
    STDERR.puts "Too many arguments"
    exit 1
end

puts "Binding path '#{rootpath}' to #{bind_address}:#{bind_port}"

serv = WEBrick::HTTPServer.new(:BindAddress => bind_address, :Port => bind_port)
if multilang
    serv.mount('/', MultiLangFileHandler, rootpath)
else
    serv.mount('/', WEBrick::HTTPServlet::FileHandler, rootpath, :FancyIndexing => true)
end

['TERM', 'INT'].each do |signal|
    trap(signal) { serv.shutdown }
end

serv.start

