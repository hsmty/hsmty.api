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
        assert_equal 200, last_response.status
    end

    def test_status
        get '/status.json'
        assert_equal 200, last_response.status
    end

end
