class D
	def initialize
		puts "class D: #{self.class}.#{__method__}"
	end

	def foo
		puts "#{self.class}.#{__method__}"
		work
	end

	private
	
	def work
		puts "#{self.class}.#{__method__}"
	end
end

class A < D
end

d = D.new
d.foo

a = A.new
a.foo

