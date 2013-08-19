require 'hsmty/api'
require 'test/unit'
require 'rack/test'

require 'json'

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

    def test_update_status
        post '/status/update', :status => 'open'
        assert_equal 401, last_response.status
        authorize 'admin', 'admin'
        post '/status/update', :status => 'open'
        assert_equal 200, last_response.status
        get '/status.json'
        status = JSON.parse(last_response.body)
        assert status['state']['open'], "Didn't update status as open"
        post '/status/update', :status => 'close'
        get '/status.json'
        status = JSON.parse(last_response.body)
        assert_equal false, status['state']['open'], "Didn't update status as close"
    end
end
