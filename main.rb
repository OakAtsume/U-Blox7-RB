# Path to the serial device
device_path = '/dev/ttyACM0'

# Open the serial device file
serial_device = File.open(device_path, 'r+')

# Configure the serial port settings (if necessary)
serial_device.sync = true
serial_device.binmode


records = {
	"latitude" => "",
	"longitude" => "",
	"speed" => "",
	"altitude" => "",
	"heading" => "",
	"satellites" => 0, # Array of satellites
	"quality" => "",
	"hdop" => "",
	"vdop" => "",
	"pdop" => "",
	"geoid" => "",
	"age" => "",
	"station" => "",
	"mode" => "",
	"date" => "",
	"time" => ""

}

oldlat = 0
oldlon = 0
begin 
	loop do
		serial = serial_device.gets
		next if serial.nil? || serial.unpack("H*")[0] == "0a" # Ignore empty seperator
		parse = serial.split("\x0a")
		sector = parse[0].split(",")
		case sector[0]
		when "$GPGGA"
			# [1] = UTC Time (hhmmss.ss)
		# [2] = Latitude (ddmm.mmmm)
		# [3] = Latitude Direction (N or S)
		# [4] = Longitude (dddmm.mmmm)
		# [5] = Longitude Direction (E or W)
		# [6] = GPS Quality Indicator (0=Invalid, 1=GPS Fix, 2=Diff. GPS Fix)
		# [7] = Number of Satellites in use (00-12)
		# [8] = Horizontal Dilution of Precision (HDOP)
		# [9] = Antenna Altitude above/below mean-sea-level (geoid) (in meters)
		# [10] = Units of antenna altitude, meters
		# [11] = Geoidal separation, the difference between the WGS-84 earth
		# ellipsoid and mean-sea-level (geoid), "-" means mean-sea-level below ellipsoid
		# [12] = Units of geoidal separation, meters
		# [13] = Age of differential GPS data, time in seconds since last SC104
		# type 1 or 9 update, null field when DGPS is not used
		# [14] = Differential reference station ID, 0000-1023
		

		# Parse Time to HH:MM:SS
		records["time"] = sector[1][0..1] + ":" + sector[1][2..3] + ":" + sector[1][4..5]
		# Round Latitude to 4 decimal places
		puts sector[2]
		
		# Round Longitude to 4 decimal places
		# records['cordinates'] = "#{sector[2]} #{sector[3]} #{sector[4]} #{sector[5]}}"


		# records['cords'] are formatted for google maps
		# records['cords'] = "#{(sector[2].to_f / 100).round(4)},#{(sector[4].to_f / 100).round(4)}"
		# Check if negative or positive
		# Well check sector[3] and sector[5] for N or S and E or W
		
		# Well check out sector[3] and sector[5] for N or S and E or W
		if sector[3] == "N"
			records['cords'] = "#{(sector[2].to_f / 100).round(4)} #{sector[3]} #{(sector[4].to_f / 100).round(4)} #{sector[5]}"
		elsif sector[3] == "S"
			records['cords'] = "-#{(sector[2].to_f / 100).round(4)} #{sector[3]} #{(sector[4].to_f / 100).round(4)} #{sector[5]}"
		end
		if sector[5] == "E"
			records['cords'] = "#{(sector[2].to_f / 100).round(4)} #{sector[3]} #{(sector[4].to_f / 100).round(4)} #{sector[5]}"
		elsif sector[5] == "W"
			records['cords'] = "#{(sector[2].to_f / 100).round(4)} #{sector[3]} -#{(sector[4].to_f / 100).round(4)} #{sector[5]}"
		end
		

		# records["longitude"] ="#{(sector[4].to_f / 100).round(4)} : #{sector[5]} : Raw(#{sector[4]})"
		# records["latitude"] = "#{(sector[2].to_f / 100).round(4)} : #{sector[3]} : Raw(#{sector[2]}))"
		# Check if negative or positive
		records["longitude"] = "#{(sector[4].to_f / 100).round(4)} #{sector[5]}" if sector[5] == "W"
		records["longitude"] = "-#{(sector[4].to_f / 100).round(4)} #{sector[5]}" if sector[5] == "E"
		records["latitude"] = "#{(sector[2].to_f / 100).round(4)} #{sector[3]}" if sector[3] == "N"
		records["latitude"] = "-#{(sector[2].to_f / 100).round(4)} #{sector[3]}" if sector[3] == "S"

		
		records["quality"] = "Invalid" if sector[6] == "0"
		records["quality"] = "GPS Fix" if sector[6] == "1"
		records["quality"] = "Diff. GPS Fix" if sector[6] == "2"
		records["satellites"] = sector[7]
		records["hdop"] = "#{sector[8]} m"
		records['vdop'] = "#{sector[10]} m"
		records["pdop"] = "#{sector[12]} m"
		records["altitude"] = "#{sector[9]} m"
		records["geoid"] = "#{sector[11]} m"
		records["age"] = "#{sector[13]} s"
		records["station"] = sector[14]
		records["mode"] = "No Fix" if sector[6] == "0"
		records["mode"] = "2D Fix" if sector[6] == "1"
		records["mode"] = "3D Fix" if sector[6] == "2"


		# For longitude and latitude use the fix
		
		when "$GPVTG"
			# [1] = True track made good (degrees)
			# [2] = True track made good symbol
			# [3] = Magnetic track made good (degrees)
			# [4] = Magnetic track symbol
			# [5] = Speed over ground (knots)
			# [6] = Speed over ground symbol
			# [7] = Speed over ground (km/h)
			# [8] = Speed over ground symbol
			# [9] = Checksum
			records["heading"] = sector[1]
			# records["speed"] = "#{sector[5]} knots"
			# Turn speed into km/h
			records["speed"] = "#{(sector[7].to_f * 1.852).round(2)} km/h"
		when "$GPRMC"
			# [1] = UTC Time (hhmmss.ss)
			# [2] = Status, V=Navigation receiver warning A=Valid
			# [3] = Latitude (ddmm.mmmm)
			# [4] = Latitude Direction (N or S)
			# [5] = Longitude (dddmm.mmmm)
			# [6] = Longitude Direction (E or W)
			# [7] = Speed over ground (knots)
			# [8] = Track made good (degrees)
			# [9] = UTC Date (ddmmyy)
			# [10] = Magnetic Variation (ddd.d)
			# [11] = Magnetic Variation Direction (E or W)
			# [12] = Checksum
			records["date"] = sector[9][0..1] + "/" + sector[9][2..3] + "/" + sector[9][4..5]


		end
		# Draw inside of a box
		consoleX = `tput cols`.to_i
		consoleY = `tput lines`.to_i
		# Clear the screen
		print "\e[2J\e[f"
		#records['cordinates'] = "#{records['latitude']} #{records['longitude']}"
		
		# Draw the box outline
		
		records.each do |key, value|
			# puts "#{key}: #{value}"
			# Organize the data into a table
			# puts "#{key}: #{value}"
			print("#{key}: #{value}\n")
		end

		# puts "Time: #{records["time"]}"

		
	end
rescue Interrupt
	serial_device.close
ensure
	serial_device.close unless serial_device.nil?

end

