require_relative './autorun'

class TorrentFileTest < MiniTest::Test

  def setup
    @valid_path1 = File.expand_path(File.join('test', 'fixtures', 'archlinux_valid.torrent'))
    @valid_path2 = File.expand_path(File.join('test', 'fixtures', 'custom_made_valid.torrent'))
    @valid_path3 = File.expand_path(File.join('test', 'fixtures', 'kinokopilka_valid.torrent'))
    @valid_path4 = File.expand_path(File.join('test', 'fixtures', 'rutracker_valid.torrent'))
    @invalid_path = File.expand_path(File.join('test', 'fixtures', 'lostfilm_invalid.torrent'))
  end

  def test_build_from_path
    valid_file = TorrentFile.new(filepath: @valid_path1)
    assert_equal true, valid_file.validation_errors.empty?
    assert_equal true, TorrentFile.new(filepath: @valid_path2).validation_errors.empty?
    assert_equal true, TorrentFile.new(filepath: @valid_path3).validation_errors.empty?
    assert_equal true, TorrentFile.new(filepath: @valid_path4).validation_errors.empty?
    assert_raises(BEncode::DecodeError) { TorrentFile.new(filepath: @invalid_path) }

    assert_equal 565182464, valid_file.contents['info']['length']
  end

  def test_build_from_contents
    valid_contents = File.open(@valid_path3, 'rb').read
    invalid_contents = File.open(@invalid_path, 'rb').read

    assert_equal true, TorrentFile.new(raw_contents: valid_contents).validation_errors.empty?
    assert_raises(BEncode::DecodeError) { TorrentFile.new(raw_contents: invalid_contents) }
  end

  def test_build_from_arguments
    raw_contents = {
      'announce'=>'http://bt4.tracktor.in/tracker.php/5d26741fc5d69b59aae15fe4a20615a1/announce',
      'info'=> {
        'length'=>26214000,
        'name'=>'Name',
         'piece length'=>262140,
         'pieces'=> 'asdffasdffasdffasdff' * 100,
      },
      'nodes'=>[]
    }

    assert_equal true, TorrentFile.new(parameters: raw_contents).validation_errors.empty?

    raw_contents['info']['length'] = 234
    assert_equal true, TorrentFile.new(parameters: raw_contents).validation_errors.has_key?('length')
  end

  def test_base64_encode_decode
    valid_file = TorrentFile.new(filepath: @valid_path1)
    original = valid_file.contents['info']['pieces']
    valid_file.base64_decode_pieces!
    valid_file.base64_encode_pieces!

    assert_equal original, valid_file.contents['info']['pieces']
  end

  def test_export
    valid_file = TorrentFile.new(filepath: @valid_path1)
    rebuilt_file = TorrentFile.new(filepath: valid_file.export)
    valid_file.base64_encode_pieces!

    assert_equal valid_file.contents, rebuilt_file.contents
  end
end