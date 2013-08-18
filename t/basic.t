require 'hsmty/api'
require 'test/unit'
require 'rack/test'

class APITest < Test::Unit::TestCase
    include Rack::Test::Methods

    def app
        Sinatra::Application
    end

    def test_index
        get '/'
        assert last_response.ok?
    end

    def test_status
        get '/status.json'
        assert last_response.ok?
        assert_equal 'application/json', last_response.header['Content-type']
    end
end
