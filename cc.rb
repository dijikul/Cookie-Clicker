#############################
# Ruby Watir Cookie Clicker #
#############################
#
# Requires watir-webdriver 
#
# 2014 by jenksy 
#
#############################


#puts "Enter your Cookie-Click delay in milliseconds: "
#int = gets.chomp
int = 250
puts "Loading cookie clicker bot with a " + int.to_s + " millisecond delay!"

require 'watir-webdriver'
require 'cgi'

$b = Watir::Browser.start('http://orteil.dashnet.org/cookieclicker/')

$cookies = Hash.new
$stats = Hash.new
$cookie = $b.div(:id, 'bigCookie')
$initTime = Time.now
upname = nil
# initialize our available upgrades hash
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
def ac(int) # auto cLicker
	$b.execute_script("autoClicker = setInterval(Game.ClickCookie, #{int});")	
end
def aco # auto click off
	# Thg Doesn't actually work for some reason. need to debug
	$b.execute_script('clearInterval(autoClicker);')
end


def timenow
	if ( (Time.now - $initTime).to_i > 3600 )
		return "[" + (sprintf('%.2f',(Time.now - $initTime)) / 3600 ) + "h] :: "
	elseif ( (Time.now - $initTime).to_i > 60 )
		return "[" + (sprintf('%.2f',(Time.now - $initTime)) / 60 ) + "m] :: "
	else
		return "[" + sprintf('%.2f',(Time.now - $initTime)) + "s] :: "
	end
end


# Get number of potential upgrades (varies by game version)
# subtract 1 - indexes start at 0
def checkupgrades


	update_stats

	# Check for popped-open achievements (and log them)		
	if $b.div(:class, 'framed note haspic hasdesc').exists?
		achieved = $b.divs(:class, 'framed note haspic hasdesc')
		title = achieved[0].div(:class, /title/).text.to_s if achieved[0].div(:class, /title/).exists?
		puts timenow + "Achievement unlocked: " + title.upcase
		#$b.execute_script('Game.CloseNotes()') 
		achieved[0].div(:class, /close/).click if achieved[0].div(:class, /close/).exists?
	end
	# Are there any available upgrades?	
	$upgrades = $b.divs(:class, 'product unlocked enabled')
	$powerups = $b.divs(:class, 'crate upgrade enabled')


	# Refresh money
	update_stats

	# If there are powerups, buy them
	if $powerups.size >= 1 then
		$stats["powerup"] = $stats["powerup"].to_i + 1

		mouseover = $powerups[0].onmouseover if $powerups[0].exists?
		# decode onmouseoer text
		decoded_mouseover = CGI::unescape( mouseover )
		# strip the name element
		powerup_name = decoded_mouseover.match(/<div class="name">([\w ]+)<\/div>/)[1]
		puts timenow + "Power up " + $stats["powerup"].to_s + ": " + powerup_name.upcase + " purchased!"
		$powerups[0].click if $powerups[0].exists?
	end

	# New upgrades algo
	if $upgrades.size >= 1 then
		w = $upgrades.size - 1
		upname = $upgrades[w].div(:class, /title/).text if $upgrades[w].div(:class, /title/).exists?
		upprice = $upgrades[w].span(:class, /price/).text.to_s if $upgrades[w].span(:class, /price/).exists?
		$stats["#{upname}"] = $stats["#{upname}"].to_i + 1
		puts timenow + "Purchasing #{upname.upcase} number #{$stats[upname]} for #{upprice} cookies"
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

ac(int)
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


