class LogElement
	attr_accessor :time, :hostname, :category, :online

	def initialize(hostname, category, online)
		self.time      = Time.now
		self.hostname  = hostname
		self.category  = category
		self.online    = online
	end
end