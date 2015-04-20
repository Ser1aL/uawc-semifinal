require 'sinatra/base'
require 'sinatra/reloader'
require 'mail'
require 'pry'
require 'ipaddress'
require 'bencode'
require 'open-uri'
require 'haml'
require 'base64'

require_relative './lib/sanitizer'
require_relative './lib/common_validations'
require_relative './lib/torrent_file_validations'
require_relative './lib/torrent_file'

class UAWCSemifinal < Sinatra::Base #:nodoc:
  include Sanitizer

  run! if app_file == $0

  configure do #:nodoc:
    register Sinatra::Reloader
    set :server, :puma
    set :haml, { :format => :html5 }
  end

  get '/' do #:nodoc:
    haml :index, layout: :'layouts/application'
  end

  # == Upload file action
  #
  # Users land here when submit their file into the system.
  # The action initiates the file by temporary path and
  # renders the edit tab
  post '/upload_file' do
    begin
      torrent_file = TorrentFile.new(filepath: params['torrent_file'][:tempfile].path)
    rescue BEncode::DecodeError
      error_message = 'The file specified is not valid'
    end

    haml :index, layout: :'layouts/application', locals: {
      error_message: error_message, torrent_file: torrent_file
    }
  end

  # == Submit link action
  #
  # Users come here when submit the remote link.
  # The action initiates remote connection, downloads the file,
  # builds the TorrentFile object and renders the edit tab.
  post '/upload_by_link' do
    file_link = params['torrent_link']

    if params['torrent_link'] =~ URI.regexp
      begin
        contents = open(params['torrent_link']).read
        torrent_file = TorrentFile.new(raw_contents: contents)
      rescue BEncode::DecodeError
        error_message = 'File has been downloaded but is not a valid .torrent file'
      rescue => any_http_error
        error_message = 'Unable to download the file. Is the link correct?'
      end
    else
      error_message = 'The link specified is not valid'
    end

    haml :index, layout: :'layouts/application', locals: {
      error_message: error_message, torrent_file: torrent_file
    }
  end

  # == Process paste action
  #
  # Users land here when submit the direct bit-torrent code.
  # The action builds the TorrentFile object and renders edit view
  post '/process_paste' do
    begin
      torrent_file = TorrentFile.new(raw_contents: params['pasted_contents'])
      error_messages = torrent_file.error_full_messages.join("\n")
    rescue BEncode::DecodeError
      error_messages = 'The input specified is not a valid bit-torrent encoded string'
    end

    haml :index, layout: :'layouts/application', locals: {
      error_message: error_messages, torrent_file: torrent_file
    }
  end

  # == Build torrent action
  #
  # The action sanitizes form input using +Sanitizer+ and builds correct arguments for
  # TorrentFile object. The object initiates validations internally and if the file is
  # valid, the action sends the file as application/x-bittorrent. If validations fail,
  # user comes back to the edit form where he/she can continue editing
  post '/build_torrent' do
    torrent_file = TorrentFile.new(parameters: sanitize_form(params['torrent_file']))

    if torrent_file.validation_errors.empty?
      file_path = torrent_file.export
      if params['delivery_type'] == 'email'
        if params['email'] && !params['email'].empty?
          torrent_file.email_file(file_path, params['email'])
          locals = { success_message: 'Email has successfully been sent' }
        else
          locals = { error_message: 'The email is invalid', torrent_file: torrent_file }
        end
      else
        send_file file_path, filename: File.basename(file_path), type: 'application/x-bittorrent'
        return
      end
    else
      locals = { error_message: torrent_file.error_full_messages.join("\n"), torrent_file: torrent_file }
    end

    haml :index, layout: :'layouts/application', locals: locals
  end

end
