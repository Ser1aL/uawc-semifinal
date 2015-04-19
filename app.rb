require 'sinatra/base'
require 'sinatra/reloader'
require 'mail'
require 'pry'
require 'bencode'
require 'open-uri'
require 'haml'
require 'base64'

require_relative './lib/torrent_file'

class UAWCSemifinal < Sinatra::Base
  run! if app_file == $0

  configure do
    register Sinatra::Reloader
    set :server, :puma
    set :haml, { :format => :html5 }
  end

  get '/' do #:nodoc:
    haml :index, layout: :'layouts/application'
  end

  post '/upload_file' do
    # to give a small boost to the system
    content_type = params['torrent_file'][:type]
    unless content_type == 'application/octet-stream'
      error_message = 'The file you specified is not a valid torrent file'
    end

    begin
      torrent_file = TorrentFile.new(filepath: params['torrent_file'][:tempfile].path)
    rescue BEncode::DecodeError
      error_message = 'The file specified is not valid'
    end

    haml :index, layout: :'layouts/application', locals: {
      error_message: error_message, torrent_file: torrent_file
    }
  end

  post '/upload_by_link' do
    file_link = params['torrent_link']

    if params['torrent_link'] =~ URI.regexp
      begin
        contents = open(params['torrent_link']).read
        torrent_file = TorrentFile.new(raw_contents: contents)
      rescue => any_http_error
        error_message = 'Unable to download file. Is the link correct?'
      rescue BEncode::DecodeError
        error_message = 'File has been downloaded but is not a valid .torrent file'
      end
    else
      error_message = 'The link specified is not valid'
    end

    haml :index, layout: :'layouts/application', locals: {
      error_message: error_message, torrent_file: torrent_file
    }
  end

  post '/build_torrent' do
    # params transformations
    %w(announce-list nodes).each do |array_attribute|
      begin
        params['torrent_file'][array_attribute].reject!(&:empty?)
        params['torrent_file'][array_attribute].map! { |url_param| JSON.parse(url_param) }
      rescue JSON::ParserError
        error = "#{array_attribute} is invalid. Please, verify and re-submit"
      end
    end

    begin
      params['torrent_file']['info']['files'].map! do |file_hash|
        next if file_hash['length'].empty? || file_hash['path'].empty?
        file_hash['path'] = JSON.parse(file_hash['path'])
        file_hash['length'] = file_hash['length'].to_i
        file_hash
      end

      params['torrent_file']['info']['files'].compact!
    rescue JSON::ParserError
      error = "info/files attribute is invalid. Please, verify and re-submit"
    end

    params['torrent_file']['info']['length'] = params['torrent_file']['info']['length'].to_i

    params['torrent_file']['info'].reject! do |key, value|
      key == 'files' && value.empty? ||
      key == 'length' && value == 0
    end

    params['torrent_file']['creation date'] = params['torrent_file']['creation date'].to_i
    params['torrent_file']['info']['piece length'] = params['torrent_file']['info']['piece length'].to_i

    # restore pieces
    restored_pieces = Base64.decode64(params['torrent_file']['info']['pieces'])
    params['torrent_file']['info']['pieces'] = restored_pieces

    torrent_file = TorrentFile.new(parameters: params['torrent_file'])
    file_path = torrent_file.export

    send_file file_path, filename: File.basename(file_path), type: 'application/x-bittorrent'
  end
end
