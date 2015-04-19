# announce => 'string url'
# announce-list => ['string url', 'string'] url
# nodes => [                             # can replace announce + announce-list
#   ['string of IP/Hostname', integer of port]
#   ['string of IP/Hostname', integer of port]
#   ...
# ]
# comment => 'custom string'
# 'created by' => 'name of tool'
# 'creation date' => integer of unix epoch
# encoding => 'UTF-8'
# httpseeds => ['string url', 'string url']
# publisher => 'string of publisher'
# publisher-url => 'string url'
# private => 1 or 0
# info => {
#   length => integer of file size,
#   name => 'string filename or directory name'
#   files => [
#     { length => integer of size, path => ['string of path'] }
#     { length => integer of size, path => ['string of path'] }
#     ...
#   ]
#   'piece length' => integer of piece length,
#   pieces => 'concatenated string'      # (ceil(length / piece length) * 160 = 414080 bits)
#   'root hash': 'string of hash'        # Merkle(hash) tree
#   'file-duration' => [integer] 2555
#   'file-media' => [integer] 0
# }

class TorrentFile
  attr_reader :contents

  STORE_DIR = 'public/torrents'

  def initialize(*args)
    raise ArgumentError, 'No input specified' if !args || args.empty?

    if args.first[:raw_contents]
      @contents = args.first[:raw_contents].to_s.strip.bdecode
    elsif args.first[:filepath]
      @contents = File.open(args.first[:filepath], 'rb').read.strip.bdecode
    elsif args.first[:parameters]
      @contents = args.first[:parameters]
    else
      raise ArgumentError, "Incorrect arguments specified to build TorrentFile.
        Examples:
          TorrentFile.new(filepath: '/path/to/file'),
          TorrentFile.new(raw_contents: contents),
          TorrentFile.new(parameters: {})"
    end

    validate!

    # TODO remove before release
    if @contents
      @contents['info']['pieces'] = Base64.encode64(@contents['info']['pieces']).force_encoding('UTF-8')
    end
  end

  def info
    @contents && @contents.is_a?(Hash) ? @contents['info'] : {}
  end

  def validate!
    return if valid?

    # validate if announce-list is an array of single-string-element arrays

    # validate if httpseeds is an array of string

    # validate if nodes is an array of 2-element arrays
  end

  def valid?
    @valid
  end

  def export
    @contents['info']['pieces'] = Base64.decode64(@contents['info']['pieces']).strip if @contents
    path = File.expand_path(File.join(STORE_DIR, @contents['info']['name'] + '.torrent'))
    File.open(path, 'w') { |file| file.puts @contents.bencode }

    path
  end

  # silently return nothing if argument doesn't exist in the @contents hash
  def method_missing(method, *args, &block)
    begin
      @contents[method.to_s.gsub(/_/, ' ')] || @contents[method.to_s.gsub(/_/, '-')] || nil
    rescue
      nil
    end
  end
end