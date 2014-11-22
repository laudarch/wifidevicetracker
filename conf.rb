require 'json'

# read and manage config.json
class Conf
	attr_accessor :lat_lon, :sleeptime, :timeout, :rules, :devices, :devices_all

	def initialize( filename )
		# read config
		json_sting = File.read( filename )
		config	   = JSON.parse( json_sting )
		puts "Parsing JSON ... done"

		# set values
		self.lat_lon   = config["lat_lon"]
		self.sleeptime = config["sleeptime"]
		self.timeout   = config["timeout"]
		self.devices   = { :mobiles => config["mobiles"], :computers => config["computers"], :others => config["others"] }
		self.rules 	   = config["rules"]

		puts "Loading Config ... done"
	end

end