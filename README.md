# Custom bash prompt and MOTD

## Installation instructions for Debian:

	$ curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -o ~/.git-prompt.sh
	$ sudo chmod +x ~/.git-prompt.sh
	$ nano ~/.color_prompt

Copy the contents of  `.color_prompt` then save

	$ sudo chmod +x ~/.color_prompt
	$ echo "~/.color_prompt" >> ~/.bashrc
	$ sudo apt-get install tcl figlet bc -y
	$ [ ! -f /usr/share/figlet/roman.flf ] && sudo wget ftp://ftp.figlet.org/pub/figlet/fonts/contributed/roman.flf -P /usr/share/figlet
	$ sudo nano /etc/motd.tcl

Copy the contents of `motd.tcl` then save

	$ sudo chmod +x /etc/motd.tcl
	$ sudo nano /etc/profile

Add `/etc/motd.tcl` on its own lise at the end

Your prompt and MOTD should be replaced after logging out then back in.
