RUBY=/usr/bin/ruby
LIB=./lib

test: test-basic test-idevice

test-basic: t/basic.rb 
	$(RUBY) -I $(LIB) $(<)

test-idevice: t/idevice.rb
	$(RUBY) -I $(LIB) $(<)

run: lib/hsmty/api.rb
	$(RUBY) $(<)
