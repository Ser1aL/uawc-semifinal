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
# }

class TorrentFile
  attr_reader :contents

  def initialize(*args)
    raise ArgumentError, 'No input specified' if !args || args.empty?
    if args.first[:raw_contents]
      @contents = args.first[:raw_contents].to_s.strip.bdecode
    elsif args.first[:filepath]
      @contents = File.open(args.first[:filepath], 'rb').read.strip.bdecode
    elsif args.first[:configuration]
      @contents = args.first[:configuration]
    else
      raise ArgumentError, "Incorrect arguments specified to build TorrentFile.
        Examples:
          TorrentFile.new(filepath: '/path/to/file'),
          TorrentFile.new(raw_contents: contents),
          TorrentFile.new(configuration: {})"
    end

    # TODO remove before release
    @contents['info']['pieces'] = 'CONCATENATEDPIECES'
  end

  def info
    @contents && @contents.is_a?(Hash) ? @contents['info'] : {}
  end

  def method_missing(method, *args, &block)
    begin
      @contents[method.to_s.gsub(/_/, ' ')] || @contents[method.to_s.gsub(/_/, '-')] || nil
    rescue
      nil
    end
    # rescue
    #   raise NoMethodError, "undefined method `#{method}' for #{self}"
    # end
  end
end