require "#{@path}/log_element"

# extend ICMP class
class Device
	attr_accessor :hostname, :category

	def initialize(hostname, category, config, log)
		self.hostname	= hostname
		self.category 	= category
		@config 		= config
		@log 			= log

		# start pinging device
		updateState
	end

	# check if device is online
	def updateState
		online 	= false

		while true
			# puts "#{self.hostname} online: #{online}"
			last = online
			# TODO: net/ping wasnt working so i used shell -> disadvantage: platform dependent
			online = `ping #{self.hostname} -c 1 -W #{@config.timeout} | grep -E ' 0% packet loss'` != ""
			# write into log state when changed
			@log.writeChan( LogElement.new( self.hostname, self.category, online ) ) if (last ^ online)

			# wait given time till next check
			sleep @config.sleeptime
		end
	end

end
