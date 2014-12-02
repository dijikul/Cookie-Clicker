#############################
# Ruby Watir Cookie Clicker #
#############################
#
# Requires watir-webdriver 
#
#############################

#puts "Enter your click delay in milliseconds: "
#int = gets.chomp

# if this is set to anything lower than about 100, Watir starts tripping up
# on DOM elements that get renamed/repurposed.
int = 1

puts "Loading cookie clicker bot with a " + int.to_s + " millisecond delay!"

require 'watir-webdriver'
require 'cgi'

$b = Watir::Browser.start('http://orteil.dashnet.org/cookieclicker/')
$b.execute_script('var autoClicker = 0;')
$cookies = Hash.new
$stats = Hash.new
$cookie = $b.div(:id, 'bigCookie')
$initTime = Time.now
upname = nil
upgrades = Hash.new

def click(howManyTimes = 1)
	howManyTimes.to_i.times do
		$cookie.click
		update_stats
	end
end


# This updates the bot's memory with how many cookies we have, including CPS
def update_stats
	$cookies["amt"] = $b.div(:id, 'cookies').text.scan(/\d+.?\d?+/)[0].to_i
	$cookies["cps"] = $b.div(:id, 'cookies').text.scan(/\d+.?\d?+/)[1].to_i
	return $cookies
end


###################
#      CHEATS     #
###################
$b.execute_script("var autoClicker;")
def autoclick(int = 250) # auto clicker
	$b.execute_script("autoClicker = setInterval(Game.ClickCookie, #{int});")	
end
def stopclick # auto click off
	# Thg Doesn't actually work for some reason. need to debug
	$b.execute_script('clearInterval(autoClicker);')
end


def timenow
	# Try and make it display proper minutes / hours if left running
	seconds = (Time.now - $initTime).to_f
	minutes = (seconds/60)
	hours = (seconds/3600)
	
=begin
	puts sprintf('%.2f', seconds) + "s"
	puts sprintf('%.2f', minutes) + "m"
	puts sprintf('%.2f', hours) + "h"
=end
	minutes > 1 ? "[ " + minutes.to_i.to_s + "m " + (seconds.to_i - (minutes.to_i * 60)).to_s.rjust(2, '0') + "s ] :: "  : "[ " + sprintf('%.1f', seconds) + "s ] :: "

end


# Get number of potential upgrades (varies by game version)
# subtract 1 - indexes start at 0
def checkupgrades


	update_stats

	# Achievements		
	if $b.div(:class, 'framed note haspic hasdesc').exists?
		# old way
		puts (timenow + "Achievement unlocked: " + $b.divs(:class, 'framed note haspic hasdesc').first.div(:class, /title/).when_present.text.to_s)
		if $b.divs(:class, 'framed note haspic hasdesc').first.div(:class, /close/).exists?
			$b.divs(:class, 'framed note haspic hasdesc').first.div(:class, /close/).click  # 
		end
	end
	# Are there any available upgrades?	
	$upgrades = $b.divs(:class, 'product unlocked enabled')
	$powerups = $b.divs(:class, 'crate upgrade enabled')


	# Refresh money
	update_stats

	# If there are powerups, buy them
	if $powerups.size >= 1 then
		mouseover = nil
		decoded_mouseover = nil
		powerup_name = nil
		# Increment powerup count
		$stats["powerup"] = $stats["powerup"].to_i + 1
		# powerup name is stored in tooltip, assigned by mouseover. HMMMM....
		mouseover = $powerups[0].onmouseover if $powerups[0].exists?
		# decode onmouseoer text
		decoded_mouseover = CGI::unescape( mouseover ) if mouseover
		
		# extract the name element
		decoded_mouseover ? powerup_name = decoded_mouseover.match(/<div class="name">([\w ]+)<\/div>/)[1] : puts("*** element not detected")
		
		# log the powerup we're purchasing
		puts timenow + "Power up #" + $stats["powerup"].to_s + ": '" + powerup_name.to_s + "' purchased!"
		# ...and click it to actually do the thing we said we just did.
		if $powerups[0].exists?
			$powerups[0].click 
		end
	end

	# New upgrades algo
	if $upgrades.size >= 1 then
		# grab the largest available powerup index, with the thinking
		# being that the more-advanced powerup will have larger yield,
		# so purchase it first if there are more than one available.
		w = $upgrades.size - 1
		upname = $upgrades[w].div(:class, /title/).when_present.text
		upprice = $upgrades[w].span(:class, /price/).text.to_s if $upgrades[w].span(:class, /price/).exists?
		
		# increment this powerup's counter
		$stats["#{upname}"] = $stats["#{upname}"].to_i + 1
		puts timenow + "Purchased '#{upname}' number #{$stats[upname]} for #{upprice} cookies"
		$upgrades[w].click if $upgrades[w].exists?
		
	end
end

# If CTRL-D is detected, stop the bot from purchasing upgrades.
def quit?
  begin
    # See if a 'Q' has been typed yet
    while c = STDIN.read_nonblock(1)
      puts "I found a #{c}"
      return true if c == 'Q'
    end
    # No 'Q' found
    false
  rescue Errno::EINTR
    puts "Well, your device seems a little slow..."
    false
  rescue Errno::EAGAIN
    # nothing was ready to be read
    #puts "Nothing to be read..."
    false
  rescue EOFError
    # quit on the end of the input stream
    # (user hit CTRL-D)
    puts "Who hit CTRL-D, really?"
    true
  end
end


# call the auto-clicker method

autoclick(int)
#$b.execute_script('Game.cookies = 1000000000000000')
#click 15
puts timenow + "Cookie clicker initialized at " + $initTime.to_s
#define main upgrade loop
def gobot
	loop do
		checkupgrades
		break if quit?
		sleep (1.0 / 10)
	end
end
gobot


