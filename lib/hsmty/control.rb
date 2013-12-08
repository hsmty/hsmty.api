#!/usr/bin/ruby

require 'rubygems'
require 'daemons'

DIR="/var/www/hsmty_api"
prog="lib/hsmty/minimal.rb"

ENV["RACK_ENV"] = "production"

Daemons.run_proc(prog) do
  Dir.chdir(DIR)
  exec "ruby", prog
end
