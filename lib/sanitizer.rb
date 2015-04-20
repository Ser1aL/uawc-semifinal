module Sanitizer

  # == Sanitize form arguments
  #
  # Sanitize form method is implemented with an idea to transform
  # the input to the consumable format.
  # Executed on the highest level
  #
  # announce-list and nodes are received as json encoded attributes.
  # Doing JSON.parse from them creates a valida ruby object.
  # Rejects also the empty attributes and transform integer values to
  # the correct format
  def sanitize_form(params)
    # clean up and restore announce-list and node list from forms
    %w(announce-list nodes).each do |array_attribute|
      begin
        params[array_attribute].reject!(&:empty?)
        params[array_attribute].map! { |url_param| JSON.parse(url_param) }
      rescue JSON::ParserError
        @sanitization_error = "#{array_attribute} is invalid. Please, verify and re-submit"
      end
    end

    # clean up and restore file objects from forms
    begin
      params['info']['files'].map! do |file_hash|
        next if file_hash['length'].empty? || file_hash['path'].empty?
        file_hash['path'] = JSON.parse(file_hash['path'])

        # Sometimes people make file names ASCII-8BIT encoded. Bad. Really.
        # This is not the way torrent files should be built. We should likely
        # ignore the files like these and return and error but let's
        # be kind and try to resolve them
        file_hash['path'].map! { |path| path.force_encoding('UTF-8') }

        file_hash['length'] = file_hash['length'].to_i
        file_hash
      end

      params['info']['files'].compact!
    rescue JSON::ParserError
      @sanitization_error = "info/files attribute is invalid. Please, verify and re-submit"
    end

    # sanitize and remove empty objects
    params['info'].reject! do |key, value|
      key == 'files' && value.empty? ||
      key == 'length' && value == 0
    end

    # convert int attributes from string to numbers
    params['info']['length'] = params['info']['length'].to_i
    params['creation date'] = params['creation date'].to_i
    params['info']['piece length'] = params['info']['piece length'].to_i

    # restore pieces from the form
    params['info']['pieces'] = Base64.decode64(params['info']['pieces'])

    params
  end

  # == Sanitize file contents
  #
  # Sanitize the contents of the received files.
  # Executed inside TorrentFile object
  def sanitize_file_contents(contents)
    # clean up empty seeds
    if contents['httpseeds'] && contents['httpseeds'].is_a?(Array) && !contents['httpseeds'].empty?
      contents['httpseeds'].map! do |httpseed|
        httpseed if httpseed && !httpseed.empty?
      end.compact!
    end

    # force name encoding
    if contents && contents['info'] && contents['info']['name']
      contents['info']['name'].force_encoding('UTF-8')
    end

    # force file names encoding
    if contents && contents['info'] && contents['info']['files']
      contents['info']['files'].each do |file|
        file['path'].each do |path|
          path.force_encoding('UTF-8')
        end
      end
    end

    contents
  end

end