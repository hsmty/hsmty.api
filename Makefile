RUBY=/usr/bin/ruby
LIB=./lib

test: test-basic test-idevice

test-basic: t/basic.rb 
	RACK_ENV=test $(RUBY) -I $(LIB) $(<)

test-idevice: t/idevice.rb
	RACK_ENV=test $(RUBY) -I $(LIB) $(<)
