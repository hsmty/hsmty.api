
require 'sinatra'
require 'json'
require 'sequel'

error 400 do |mesg|
    if mesg then
        'Bad Request: #{mesg}'
    else
        'Bad Request'
    end
end

get '/status.json' do

    status = createstatus()

    status.to_json
end

get '/idevices/?' do
    db = getdbh()
    count = db[:devices].count
    return count.to_s
end

get '/idevices/:token' do |token|
    db = getdbh()
    device = db[:devices].where(:token => token).first
    if device then
        'found'
    else
        status 404
        body 'Device not found'
    end
end

put '/idevices/:token' do |token|
    reg = JSON.parse(request.body.read)
    if (reg and reg['id'] and reg['key']) then
        db = getdbh()
        db[:devices].insert(
            :id  => reg['id'],
            :key => reg['key'],
            :token => tokey,
            :version => 0
        )
        
    elsif (reg)
        status 400
        body 'Missing params'
    else
        status 400
        body 'Invalid Request'
    end

end

def createstatus()
    db = getdbh()

    file = open('status.json')
    status = JSON.parse(file.read)

    if (status and status['state']) then
        row = db[:status].select(:state).reverse_order(:changed).limit(1).first
        status['state'][:open] = row[:state]
    else
        status = {}
    end

    return status
end

def getdbh()
    dbh = Sequel.sqlite('/tmp/hsmty.db')
end
