#!/usr/bin/ruby

# path to script folder
@path = '/home/pi/checkwlandevices'

require "#{@path}/conf"
require "#{@path}/chan"
require "#{@path}/device"
require "#{@path}/events"
require "solareventcalculator"


begin

	@config = Conf.new( "#{@path}/config.json" )
	log = Chan.new

	# start event listener
	e = Thread.new do	
		begin
			Events.new( @config, log )
		rescue => e
			puts e.backtrace
			puts e
			raise e
		end
	end

	# start devices
	devices = []
	count = 0
	@config.devices.each do |category,devlist|
		devlist.each do |dev|
			count += 1
			t = Thread.new{ Device.new( dev, category, @config, log ) }
			devices.push( t )
		end
	end

	puts "Running! Watching #{count} devices."

	# dont make orphans
	#devices.each{ |d| d.join }
	e.join

rescue SystemExit, Interrupt
	puts "\nSkript wird beendet..."
	raise
rescue => e
	puts e
end
