#!/usr/bin/ruby

# Minimal version of the api.hsmty.org web service
require 'sinatra'
require 'json'
require 'sequel'

# Load configuration scheme to access the database
load 'conf.rb'

get '/' do
    'HSMTY API Web Service'
end

get '/status.json' do
    status = get_status()

    headers "Content-type" => "application/json"
    status.to_json
end

post '/status' do
    open = false
    status = params[:status]

    if status == 'open'
        open = true
    elsif status == "close"
        open = false
    else
        # Bad request
        halt 400
    end

    dbh = get_dbh()
    state = dbh[:status].reverse_order(:changed).get(:state)

    if state != open
        # Update the DB only if the state of the space has
        # changed
        dbh[:status].insert(
            :state => open, 
            :changed => Time.now().to_i
            )
    end

    # Return the string 'updated' to the client
    return {:status => 'Updated'}.to_json
end


def get_status()
    dbh = get_dbh()

    status_file = open('status.json')
    status = JSON.parse(status_file.read)

    if (status and status['state']) then
        status[:state][:open] = dbh[:status].reverse_order(:changed).get(:state)
    else
        status = {}
    end

    return status
end

def get_dbh()
    if settings.db_engine == :sqlite
        file = settings.db_file || "/tmp/hsmty.db"
        dbh = Sequel.sqlite(file)
    elsif settings.db_engine == :postgres
        info = {
            :host => settings.db_host || 'localhost',
            :database => settings.db_name || 'api',
            :user => settings.db_user || 'postgres',
            :password => settings.db_pass || nil,
            }
        dbh = Sequel.postgres(info)
    else
        dbh = nil
    end

    return dbh
end
