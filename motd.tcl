#!/usr/bin/env tclsh
# * Config
# Defaults, override any of these in /etc/motd.conf (see motd.conf.example)
set cfg(name)          [string totitle [exec hostname]]
set cfg(font)          roman
set cfg(allowed_users) {}  ;# empty = every user; root is always allowed
if {[info exists env(MOTD_CONF)]} {
  set conf $env(MOTD_CONF)
} else {
  set conf /etc/motd.conf
}
if {[file readable $conf]} {
  source $conf
}
set name $cfg(name)

# * Variables
set var(user) $env(USER)
set var(path) $env(PWD)
set var(home) $env(HOME)
if {[catch {set var(cols) [lindex [exec stty size < /dev/tty] 1]}] || ![string is integer -strict $var(cols)] || $var(cols) < 1} {
  # No controlling terminal (e.g. non-interactive session)
  set var(cols) [expr {[info exists env(COLUMNS)] && [string is integer -strict $env(COLUMNS)] ? $env(COLUMNS) : 80}]
}
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
  if {[llength $cfg(allowed_users)] > 0 && $var(user) ni $cfg(allowed_users)} {
    exit 0
  }
  set LACC $LRED
  set ACC $RED
}

# * Calculate last login & session start
foreach line [lrange [split [exec lastlog2] "\n"] 1 end] {
  if {[string match "$var(user) *" $line]} {
    regexp {^\S+\s+\S+\s+(\S*)\s+\w+\s+(\w+)\s+(\d+)\s+(\d+:\d+:\d+)\s+[+-]\d+\s+(\d{4})$} \
      $line -> host mon day time year

    set ll(host) $host
    set ll(m)    $mon
    set ll(d)    $day
    set ll(time) $time
    set ll(y)    $year

    set ss(host) $host
    set ss(m)    $mon
    set ss(d)    $day
    set ss(time) $time
    set ss(y)    $year

    break
  }
}

# * Session start & previous login from wtmp
# lastlog2 only keeps the newest login per user and isn't always updated, so
# the two newest logins are read from wtmp (struct utmp records), newest
# first: this session, then the one before it. glibc lays the record out as
# 384 bytes with a 32-bit time on x86_64 and 32-bit systems, and as 400 bytes
# with a 64-bit time on other 64-bit systems such as aarch64.
proc recent_logins {user count} {
  global tcl_platform
  set logins {}
  if {[catch {set f [open /var/log/wtmp rb]}]} {
    return $logins
  }
  if {$tcl_platform(pointerSize) == 8 && $tcl_platform(machine) ne "x86_64"} {
    set recsize 400
    set format @0s1@44a32@76a256@344w1
  } else {
    set recsize 384
    set format @0s1@44a32@76a256@340i1
  }
  set size [file size /var/log/wtmp]
  for {set pos [expr {$size - $size % $recsize - $recsize}]} {$pos >= 0} {incr pos -$recsize} {
    seek $f $pos
    binary scan [read $f $recsize] $format type rec_user host sec
    # type 7 = USER_PROCESS
    if {$type != 7 || [lindex [split $rec_user \0] 0] ne $user} continue
    lappend logins [list [lindex [split $host \0] 0] $sec]
    if {[llength $logins] == $count} break
  }
  close $f
  return $logins
}

proc login_fields {arr login} {
  upvar $arr a
  lassign [clock format [lindex $login 1] -format {%b %d %H:%M:%S %Y}] a(m) a(d) a(time) a(y)
  set a(host) [lindex $login 0]
}

set logins [recent_logins $var(user) 2]
if {[llength $logins] >= 1} {
  login_fields ss [lindex $logins 0]
}
if {[llength $logins] >= 2} {
  login_fields ll [lindex $logins 1]
} else {
  array set ll {host - m - d - time - y -}
}

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
set head [string trimright [exec -- figlet $name -ct -f $cfg(font) ] "\n "]

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
