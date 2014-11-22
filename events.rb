require 'solareventcalculator'

class Events

	def initialize( config, log_chan )
		@config = config
		@chan 	= log_chan
		@device_states = {}
		@state_log = []

		# set initial state
		setState({ all_online: false, some_online: false, all_offline: true, arriving: false })

		# initalize hash with hostnames as key wich shows state of each device
		@config.devices.each do |key,hostnames|
			hostnames.each do |hostname|
				@device_states[hostname] = false
			end
		end

		# wait for changes which influence the state
		receiveChanges
	end

	# read changes and set current state
	def receiveChanges
		# receive change, suspend if no changes were made
		change = @chan.readChan
		# update @device_states
		@device_states[change.hostname] = change.online

		# get states
		all_online   = foldHash( true, @device_states ) { |r,v| r && v }
		some_online  = foldHash( false, @device_states ) { |r,v| r || v }
		all_offline  = !some_online
		# only activated if state is all_offline for 5 minutes
		arriving	 = some_online && stateFor( Time.now - 5*60, :all_offline )

		# make state hash
		state = { all_online: all_online, some_online: some_online, all_offline: all_offline, arriving: arriving }
		# set state
		setState( state )
				
		# puts "state #{state}"

		executeRules
	end

	# get rules from config and try to match condition 
	def executeRules
		# match rules
		@config.rules.each do |rule|
			# replace logic operands and daytime
			toeval = rule["if"].gsub(/and/i  ,"&&")
							   .gsub(/or/i   ,"||")
							   .gsub(/not\s/i,"!")
						  	   .gsub(/day/i  , (!isDark?).to_s)
							   .gsub(/night/i, isDark?.to_s)
			# replace states
			getState[:state].each do |key, val|
				toeval = toeval.gsub(key.to_s, val.to_s)
			end
			
			# exec rule if condition is true
			begin
				condtrue = eval( toeval )
				puts "#{rule["then"]} wird ausgefuehrt \n" if condtrue
				system "#{rule["then"]} &" if condtrue
			rescue => e
				puts "ungueltige Regel: #{rule["if"]}"
				raise e
			end
		end

		# wait for next change
		receiveChanges
	end

	# check if state was constantly true till given time
	def stateFor( time, state_key )
		result = true
		# go trough state log
		@state_log.each do |log|
			if log[:time] >= time
				result = false if !log[:state][state_key]
			else
				break
			end
		end

		result
	end

	def foldHash( init, hash )
		hash.each_value do |v| 
			init = yield init, v
		end
		init
	end

	def setState( state )
		@state_log.push( { :time => Time.now, :state => state } )
		@state_log.shift if @state_log.size > 20
	end

	# get states which is closest to given time
	def getState( time = Time.now )
		last_diff = 9999999
		result 	  = false

		@state_log.each do |log|
			result = log if (log[:time]-time).abs < last_diff
		end

		result
	end

	# Is it dark outside?
	def isDark? 
		now 	= DateTime.now.new_offset(0)
		calc 	= SolarEventCalculator.
					new( now.to_date, BigDecimal.new( @config.lat_lon[0] ), BigDecimal.new( @config.lat_lon[1] ) )
		sunset 	= calc.compute_utc_official_sunset
		sunrise = calc.compute_utc_official_sunrise

		# if sunrise is earlier then sunset we need the sunrise of the next day
		sunrise = SolarEventCalculator.
					new( now.to_date + 1, BigDecimal.new( @config.lat_lon[0] ), BigDecimal.new( @config.lat_lon[1] ) ).
					compute_utc_official_sunrise if sunrise < sunset

		# are we between sunset and sunrise?
		now > sunset && now < sunrise
	end

end