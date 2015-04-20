require_relative './autorun'

class CommonValidationsTest < MiniTest::Test
  include CommonValidations

  def test_presence_validation
    validate_presence_of('attr', {'attr' => ''}, errors = {})
    assert_equal true, errors.has_key?('attr')

    validate_presence_of('attr', {'attr' => 'some text'}, errors = {})
    assert_equal false, errors.has_key?('attr')

    validate_presence_of('attr', {'attr' => nil}, errors = {})
    assert_equal true, errors.has_key?('attr')

    validate_presence_of('attr', {'attr' => []}, errors = {})
    assert_equal true, errors.has_key?('attr')
  end

  def test_uniqueness_validation
    validate_uniqueness_of('attr', {'attr' => ''}, errors = {})
    assert_equal false, errors.has_key?('attr')

    validate_uniqueness_of('attr', {'attr' => ['a', 'd']}, errors = {})
    assert_equal false, errors.has_key?('attr')

    validate_uniqueness_of('attr', {'attr' => ['a', 'a']}, errors = {})
    assert_equal true, errors.has_key?('attr')
  end

  def test_url_validation
    validate_url_of('attr', {'attr' => ''}, errors = {})
    assert_equal true, errors.has_key?('attr')

    validate_url_of('attr', {'attr' => 'http://google.com'}, errors = {})
    assert_equal false, errors.has_key?('attr')

    validate_url_of('attr', {'attr' => 'invalid url'}, errors = {})
    assert_equal true, errors.has_key?('attr')
  end

  def test_array_of_urls_validation
    validate_urls_array_of('attr', {'attr' => ['invalid url']}, errors = {})
    assert_equal true, errors.has_key?('attr')

    validate_urls_array_of('attr', {'attr' => ['http://google.com']}, errors = {})
    assert_equal false, errors.has_key?('attr')

    validate_urls_array_of('attr', {'attr' => ['http://google.com', 'invalid']}, errors = {})
    assert_equal true, errors.has_key?('attr')

    validate_urls_array_of('attr', {'attr' => ['http://google.com', 'http://ya.ru']}, errors = {})
    assert_equal false, errors.has_key?('attr')
  end

end