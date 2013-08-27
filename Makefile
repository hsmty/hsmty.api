RUBY=/usr/bin/ruby
LIB=./lib

test: t/basic.rb t/idevice.rb
	$(RUBY) -I $(LIB) $(<)
	$(RUBY) -I $(LIB) t/idevice.rb 
