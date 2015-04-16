require 'sinatra/base'
require 'sinatra/reloader'
require 'mail'
require 'pry'
require 'bencode'
require 'open-uri'
require 'haml'

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
        @error_message = 'File has been downloaded but is not a valid .torrent file'
      end
    else
      error_message = 'The link specified is not valid'
    end

    haml :index, layout: :'layouts/application', locals: {
      error_message: error_message, torrent_file: torrent_file
    }
  end

  post '/build_torrent' do
    binding.pry
  end
end
