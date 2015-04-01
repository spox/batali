require 'batali'
require 'minitest/autorun'

describe Batali do

  describe 'HTTP proxy support' do
    before do
      ENV['http_proxy'] = 'http://example.com'
    end
    after do
      ENV.delete('http_proxy')
    end

    it 'should proxy HTTP request' do
      HTTP.get('http://www.google.com').code.wont_equal 200
    end

  end

  describe 'HTTPS proxy support' do
    before do
      ENV['https_proxy'] = 'http://example.com'
    end
    after do
      ENV.delete('https_proxy')
    end

    it 'should proxy HTTPS request' do
      HTTP.get('https://www.google.com').code.wont_equal 200
    end

  end

  describe 'No proxy support' do
    it 'should not proxy request' do
      HTTP.get('https://www.google.com').code.must_equal 200
      HTTP.get('http://www.google.com').code.must_equal 200
    end
  end

end
