require "Configuration"
require "net/http"
require "uri"

conf = Configuration.load "/etc/sense.conf"
status = "closed"

# Read list of MACs from file
if File.file?(conf.file)
    mac_file = File.open(conf.file, "r")
else
    exit
end
# Read MAC addresses in the network
macs = `arp-scan 192.168.1.0/24`
# clean the 'macs' 
# Compare addresses, if at least one matches, send
# the status as open to the server, else, send it as
# closed.

if macs & mac_file
    status = "open"
end

http = Net::HTTP.new(conf.server, conf.port)
req = Net::HTTP::Post.new("/status")
req.set_form_data({"status" => status})

res = http.request(req)
