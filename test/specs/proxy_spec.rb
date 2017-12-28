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

  describe 'No proxy defined' do
    it 'should not proxy request' do
      HTTP.get('https://www.google.com').code.wont_equal 404
      HTTP.get('http://www.google.com').code.wont_equal 404
    end
  end

  describe 'no_proxy environment variable' do
    before do
      ENV['http_proxy'] = 'http://example.com'
      ENV['no_proxy'] = '*google.com, yahoo.com'
    end
    after do
      ENV.delete('http_proxy')
      ENV.delete('no_proxy')
    end

    it 'should proxy when no match is defined within no_proxy' do
      HTTP.get('http://www.amazon.com').code.wont_equal 200
    end

    it 'should not proxy when direct match is found' do
      HTTP.get('http://yahoo.com').code.wont_equal 404
    end

    it 'should not proxy when glob match is found' do
      HTTP.get('http://maps.google.com').code.wont_equal 404
    end
  end
end
