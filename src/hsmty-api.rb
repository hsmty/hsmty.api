
require 'sinatra'
require 'json'
require 'sequel'

get '/status.json' do

    status = createstatus()

    status.to_json
end

def createstatus()
    db = getdbh();

    file = open('status.json')
    status = JSON.parse(file.read)

    if (status and status['state']) then
        open = db[:status].select(:state).reverse_order(:changed).limit(1).all[0]
        status['state'][:open] = open
    else
        status = {}
    end

    return status
end

def getdbh()
    dbh = Sequel.sqlite('/tmp/hsmty.db')
end
