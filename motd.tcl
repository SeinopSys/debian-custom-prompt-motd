#!/usr/bin/env tclsh
# * Config
set name [string totitle [exec hostname]]

# * Variables
set var(user) $env(USER)
set var(path) $env(PWD)
set var(home) $env(HOME)
set var(cols) [lindex [exec stty size] 1]
set RED      "\033\[31m"
set GREEN    "\033\[32m"
set YELLOW   "\033\[33m"
set CYAN     "\033\[36m"
set LRED     "\033\[1;31m"
set LGREEN   "\033\[1;32m"
set LYELLOW  "\033\[1;33m"
set LCYAN    "\033\[1;36m"
set GREY     "\033\[1;30m"
set RESET    "\033\[0m"
if { "$var(user)" eq "root" } {
  set LACC $LCYAN
  set ACC $CYAN
} else {
  set LACC $LRED
  set ACC $RED
}

# * Calculate last login
set lastlogins [split [exec -- last -F ] "\n"]
set lastlog    [lindex $lastlogins 1 ]
set ll(host)   [regsub -all {^.*[-.](\d{1,3})-(\d{1,3})-(\d{1,3})-(\d{1,3}).*$} [lindex $lastlog 2] {\1.\2.\3.\4} ]
set ll(m)      [lindex $lastlog 4]
set ll(d)      [lindex $lastlog 5]
set ll(time)   [lindex $lastlog 6]
set ll(y)      [lindex $lastlog 7]

# * Session start
set currsess [lindex $lastlogins 0 ]
set ss(host) [regsub -all {^.*[-.](\d{1,3})-(\d{1,3})-(\d{1,3})-(\d{1,3}).*$} [lindex $currsess 2] {\1.\2.\3.\4} ]
set ss(m)    [lindex $currsess 4]
set ss(d)    [lindex $currsess 5]
set ss(time) [lindex $currsess 6]
set ss(y)    [lindex $currsess 7]

# * Calculate current system uptime
set uptime    [exec -- /usr/bin/cut -d. -f1 /proc/uptime]
set up(days)  [expr {$uptime/60/60/24}]
set up(hours) [expr {$uptime/60/60%24}]
set up(mins)  [expr {$uptime/60%60}]
set up(secs)  [expr {$uptime%60}]

# * For progress bars
set width 30
set div   [expr {double(100)/$width} ]

# * Calculate Memory
set memory  [exec -- free -m]
set mem(total)    [lindex $memory 7]
set mem(used)     [lindex $memory 8]
set mem(usedperc) [regsub {\.\d+$} [expr {(double($mem(used))/$mem(total))*100} ] "" ]

set memout "$GREY\u2590$RESET"
if [expr {$mem(usedperc) >= 90}] {
  append memout "$RED"
} elseif [expr {$mem(usedperc) >= 75}] {
  append memout "$YELLOW"
} else {
  append memout "$GREEN"
}
for {set i 0} {$i < $width} {incr i} {
  if [expr {$i <= $mem(usedperc)/$div}] {
    append memout "\u2588"
  } else {
    append memout " "
  }
}
append memout "$RESET$GREY\u258c$RESET"

# * Calculate disk usage
set diskfree       [exec -- stat -f -c {scale=3;(%a*%S)/1024/1024/1024} / | bc ]
set disk(total)    [regsub {\.0+$} [exec -- stat -f -c {scale=3;(%b*%S)/1024/1024/1024} / | bc ] "" ]
set diskused       [expr {"$disk(total)"-"$diskfree"} ]
set disk(used)     [regsub {(\.\d{1,3}).*$} "$diskused" {\1} ]
set disk(usedperc) [regsub {\.\d+$} [expr {(double($diskused)/$disk(total))*100} ] "" ]
set diskout "$GREY\u2590$RESET"
if [expr {$disk(usedperc) >= 90}] {
  append diskout "$RED"
} elseif [expr {$disk(usedperc) >= 75}] {
  append diskout "$YELLOW"
} else {
  append diskout "$GREEN"
}
for {set i 0} {$i < $width} {incr i} {
  if [expr {$i <= $disk(usedperc)/$div}] {
    append diskout "\u2588"
  } else {
    append diskout " "
  }
}
append diskout "$RESET$GREY\u258c$RESET"

# * Calculate processes
set psa [expr {[lindex [exec -- ps -A h | wc -l] 0]-000}]
set psu [expr {[lindex [exec -- ps U $var(user) h | wc -l] 0]-002}]
if [expr $psu < 2] {
  if [expr $psu eq 0] {
    set psu "egy sem"
  }
}

# * ASCII head
set head [string trimright [exec -- figlet $name -ct -f roman ] "\n "]

proc center {name data} {
    global ACC
    global LACC
    global RESET
    global var

    set colsize $var(cols)
    set prints ""
    if [expr {$data eq 0} ] {
        set text $name
        set colSUBline [expr {( $colsize - ([string length $text]-( [string length $ACC] + [string length $LACC]*2 + [string length $RESET]*3 )) )/2} ]
    } else {
        set text "$name$RESET $data"
        set colSUBline [expr {( $colsize - ([string length $text]-( [string length $RESET]+1 )) )/2} ]
    }
    for {set i 0} { $i < $colSUBline} {incr i} {
        append prints " "
    }
    if [expr {$data eq 0} ] {
        puts "$prints$text"
    } else {
        puts "$prints$LACC$text"
    }
}

# * Print Output
puts [exec clear]
puts "\n$LACC$head$RESET\n"
center "Session started" "$ss(host) @ $ss(y) $ss(m) $ss(d) $ss(time)"
center "Last login" "$ll(host) @ $ll(y) $ll(m) $ll(d) $ll(time)"
center "Memory" "$mem(used)/$mem(total) MB ($mem(usedperc)%) used"
center "$memout" 0
center "Storage" "$disk(used)/$disk(total) GB ($disk(usedperc)%) used"
center "$diskout" 0
center "Uptime" "$up(days) days $up(hours)h $up(mins)m $up(secs)s"
center "Processes" "$psa running, of which $psu is yours"
puts ""
