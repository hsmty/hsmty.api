
require 'sinatra'
require 'json'
require 'sequel'

get '/status.json' do

    status = createstatus()

    status.to_json
end

def createstatus()
    dbh = getdbh();

    file = open('status.json')
    status = JSON.parse(file.read)

    if (status and status['state']) then
        status['state'][:open] = true
    else
        status = {}
    end

    return status
end

def getdbh()
    dbh = Sequel.sqlite('/tmp/hsmty.db')
end
