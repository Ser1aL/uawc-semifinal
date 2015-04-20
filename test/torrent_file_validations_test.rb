require_relative './autorun'

class TorrentFileValidationsTest < MiniTest::Test
  include TorrentFileValidations

  def setup
    # ceil (6553600 / 262144) * 160 = 25 * 20 * 8
    @contents = {
      'announce-list' => [['https://google.com/announce'], ['http://nowhere.com']],
      'info' => {
        'pieces' => pieces_digest = Digest::SHA1.digest('test') * 25,
        'length' => 6553600,
        'piece length' => 262144
      },
      'httpseeds' => ['http://google.com', 'http://nowhere.com'],
      'nodes' => [['127.33.11.22', 1234], ['http://ya.ru', 1235]]
    }

    @files = [
      {'length' => 3276800, path: ['path', 'to', 'file']},
      {'length' => 3276799, path: ['path', 'to', 'file2']},
      {'length' => 1, path: ['path', 'to', 'file3']}
    ]
  end

  def test_annunce_list_validation
    validate_announce_list('announce-list', @contents, errors = {})
    assert_equal false, errors.has_key?('announce-list')

    @contents['announce-list'] += @contents['announce-list']
    validate_announce_list('announce-list', @contents, errors = {})
    assert_equal false, errors.has_key?('announce-list') # since uniqueness is tested separately

    @contents['announce-list'] = [['https://google.com', 'http://ya.ru'], ['http://nowhere.com']]
    validate_announce_list('announce-list', @contents, errors = {})
    assert_equal true, errors.has_key?('announce-list')

    @contents['announce-list'] = [['invalid'], ['http://nowhere.com']]
    validate_announce_list('announce-list', @contents, errors = {})
    assert_equal true, errors.has_key?('announce-list')
  end

  def test_piece_size_validation
    validate_pieces_size('pieces', @contents['info'], errors = {})
    assert_equal false, errors.has_key?('pieces')

    @contents['info']['pieces'] += '123'
    validate_pieces_size('pieces', @contents['info'], errors = {})
    assert_equal true, errors.has_key?('pieces')

    @contents['info']['pieces'] = ''
    validate_pieces_size('pieces', @contents['info'], errors = {})
    assert_equal false, errors.has_key?('pieces') # since presence is tested separately
  end

  def test_length_validation
    validate_length_and_pieces('pieces', @contents['info'], errors = {})
    assert_equal false, errors.has_key?('pieces')

    @contents['info']['length'] = 12
    validate_length_and_pieces('pieces', @contents['info'], errors = {})
    assert_equal true, errors.has_key?('pieces')

    @contents['info']['length'] = -5
    validate_length_and_pieces('pieces', @contents['info'], errors = {})
    assert_equal true, errors.has_key?('pieces')

    @contents['info']['length'] = 0
    validate_length_and_pieces('pieces', @contents['info'], errors = {})
    assert_equal true, errors.has_key?('pieces')

    @contents['info'].reject! { |k| k == 'length' }
    @contents['info']['files'] = @files
    validate_length_and_pieces('pieces', @contents['info'], errors = {})
    assert_equal false, errors.has_key?('pieces')

    @contents['info']['files'] << { 'length' => 1, 'path' => ['path']}
    validate_length_and_pieces('pieces', @contents['info'], errors = {})
    assert_equal true, errors.has_key?('pieces')
  end

  # file uniqueness
  def test_files_format_validation
    @contents['info']['files'] = [{'length' => 1, 'path' => ['file']}]
    validate_files_format('files', @contents['info'], errors = {})
    # files and length should not live together
    assert_equal true, errors.has_key?('files')

    @contents['info'].reject! { |k| k == 'length' }

    @contents['info']['files'] = [{'length' => 1, 'path' => ['file']}]
    validate_files_format('files', @contents['info'], errors = {})
    assert_equal false, errors.has_key?('files')

    @contents['info']['files'] = [{'length' => 1, 'path' => 'file'}]
    validate_files_format('files', @contents['info'], errors = {})
    assert_equal true, errors.has_key?('files')

    @contents['info']['files'] = [{'length' => 1}]
    validate_files_format('files', @contents['info'], errors = {})
    assert_equal true, errors.has_key?('files')

    @contents['info']['files'] = [{'length' => 4, 'path' => [1, 'string']}]
    validate_files_format('files', @contents['info'], errors = {})
    assert_equal true, errors.has_key?('files')

    @contents['info']['files'] = [
      {'length' => 4, 'path' => ['video.mov']},
      {'length' => 4, 'path' => ['video.mov']}
    ]
    validate_files_format('files', @contents['info'], errors = {})
    assert_equal true, errors.has_key?('files')
  end

  def test_httpseeds_validation
    validate_httpseeds('httpseeds', @contents, errors = {})
    assert_equal false, errors.has_key?('httpseeds')

    @contents['httpseeds'] << 'invalid_url'
    validate_httpseeds('httpseeds', @contents, errors = {})
    assert_equal true, errors.has_key?('httpseeds')
  end

  def test_nodes_validation
    validate_nodes('nodes', @contents, errors = {})
    assert_equal false, errors.has_key?('nodes')

    @contents['nodes'] << 'invalid_url'
    validate_nodes('nodes', @contents, errors = {})
    assert_equal true, errors.has_key?('nodes')
  end

end