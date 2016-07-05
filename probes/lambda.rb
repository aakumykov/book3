class Object
	def proc?
		self.class==Proc and !self.lambda?
	end
end

l = lambda do |arg|
	puts "self: #{self}"
	puts "self.class: #{self.class}"
	puts "self.inspect: #{self.inspect}"
	puts "arg: #{arg}"
end

p = Proc.new do
	puts "self: #{self}"
end

puts "l.lambda? #{l.lambda?}"
puts "l.proc? #{l.proc?}"

puts "p.proc? #{p.proc?}"
puts "p.lambda? #{p.lambda?}"

