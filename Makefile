RUBY=/usr/bin/ruby
LIB=./lib

test: t/basic.rb
	$(RUBY) -I $(LIB) $(<)
