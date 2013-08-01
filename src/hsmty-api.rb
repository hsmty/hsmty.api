
require 'sinatra'

get '/status.json' do
  '{ "api": 0.13, "space": "HackerspaceMTY" }'
end

