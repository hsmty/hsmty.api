configure do
    set :db_engine, ''
    set :db_name, ''
    set :idevice_key, ''
end

configure :test do
    set :db_engine, :sqlite
    set :db_name, '/tmp/hsmty.db'
    set :idevice_key, '0123456789ABCDEF'
end
