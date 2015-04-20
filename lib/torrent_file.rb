class TorrentFile
  attr_reader :contents, :validation_errors

  include CommonValidations
  include TorrentFileValidations
  include Sanitizer

  STORE_DIR = 'public/torrents'

  # == Initialize Torrent File object
  #
  # The process of initialization can be done in one of 3 ways:
  #
  #   * raw_contents: the input is a bencoded string
  #   * filepath: the input is a file path
  #   * parameters: the input is a direct set of file contents
  #
  # In all ways the result is sanitized and later valided
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

    @contents = sanitize_file_contents(@contents) if @contents

    validate!
    base64_encode_pieces!
  end

  # == Validate
  #
  # Runs the chain of validations of already initialized internal attributes
  def validate!
    @validation_errors = {}

    # Main fields
    validate_presence_of('announce', @contents, @validation_errors)
    validate_url_of('announce', @contents, @validation_errors)
    validate_uniqueness_of('announce-list', @contents, @validation_errors)
    validate_array_of_strings_format_of('announce-list', @contents, @validation_errors)
    validate_announce_list('announce-list', @contents, @validation_errors)

    # Info block
    validate_presence_of('info', @contents, @validation_errors)
    validate_presence_of('name', @contents['info'], @validation_errors)
    validate_presence_of('piece length', @contents['info'], @validation_errors)
    validate_presence_of('pieces', @contents['info'], @validation_errors)
    validate_pieces_size('pieces', @contents['info'], @validation_errors)
    validate_length_and_pieces('length', @contents['info'], @validation_errors)
    validate_files_format('files', @contents['info'], @validation_errors)

    # Additional fields
    validate_urls_array_of('httpseeds', @contents, @validation_errors)
    validate_httpseeds('httpseeds', @contents, @validation_errors)
    validate_nodes('nodes', @contents, @validation_errors)
  end

  def email_file(path, recipient) #:nodoc:
    smtp_settings = {
      :address              => "smtp.gmail.com",
      :port                 => 587,
      :user_name            => "teachme.notifier@gmail.com",
      :password             => "teachme.notifier",
      :authentication       => "plain",
      :enable_starttls_auto => true
    }

    Mail.defaults do
      delivery_method :smtp, smtp_settings
    end

    begin
      Mail.deliver do
        to recipient
        from 'uawc-torrent-tool@uawc-torrent-tool.com'
        subject 'Your torrent file has successfully been generated'
        body 'Your torrent file has successfully been generated'
        attachments[File.basename(path)] = File.read(path)
      end
    rescue => exception
    end
  end

  def info #:nodoc:
    @contents && @contents.is_a?(Hash) && @contents['info'] ? @contents['info'] : {}
  end

  def base64_encode_pieces! #:nodoc:
    if @contents && @contents['info']
      @contents['info']['pieces'] = Base64.encode64(@contents['info']['pieces']).force_encoding('UTF-8')
    end
  end

  def base64_decode_pieces! #:nodoc:
    if @contents && @contents['info']
      @contents['info']['pieces'] = Base64.decode64(@contents['info']['pieces']).strip.force_encoding('UTF-8')
    end
  end

  def export #:nodoc:
    name_suffix = Digest::SHA1.hexdigest(Time.now.to_s)[0..6]
    filename = @contents['info']['name'] + name_suffix + '.torrent'
    base64_decode_pieces!
    path = File.expand_path(File.join(STORE_DIR, filename))
    File.open(path, 'w') { |file| file.puts @contents.bencode }

    path
  end

  def error_full_messages #:nodoc:
    @validation_errors.map do |attribute, validation_error|
      "#{attribute.to_s.capitalize} #{validation_error}"
    end
  end

  def method_missing(method, *args, &block)
    begin
      @contents[method.to_s.gsub(/_/, ' ')] || @contents[method.to_s.gsub(/_/, '-')] || nil
    rescue
      nil
    end
  end
end