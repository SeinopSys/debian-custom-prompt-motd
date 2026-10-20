# Custom bash prompt and MOTD

## Installation instructions for Debian:

	$ curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -o ~/.git-prompt.sh
	$ sudo chmod +x ~/.git-prompt.sh
	$ nano ~/.color_prompt

Copy the contents of  `.color_prompt` then save

	$ sudo chmod +x ~/.color_prompt
	$ echo "~/.color_prompt" >> ~/.bashrc
	$ sudo apt-get install tcl figlet bc wtmpdb -y
	$ [ ! -f /usr/share/figlet/roman.flf ] && sudo wget ftp://ftp.figlet.org/pub/figlet/fonts/contributed/roman.flf -P /usr/share/figlet
	$ sudo nano /etc/motd.tcl

Copy the contents of `motd.tcl` then save. Optionally copy `motd.conf.example` to `/etc/motd.conf` to set the header name, figlet font, or restrict which users see the MOTD.

	$ sudo chmod +x /etc/motd.tcl
	$ sudo nano /etc/profile

Add `/etc/motd.tcl` on its own lise at the end

Your prompt and MOTD should be replaced after logging out then back in.

## Keeping a server up to date

Instead of copying `motd.tcl` by hand, clone the repo and symlink it:

	$ sudo git clone https://github.com/SeinopSys/debian-custom-prompt-motd.git /var/debian-custom-prompt-motd
	$ sudo ln -sf /var/debian-custom-prompt-motd/motd.tcl /etc/motd.tcl
	$ sudo cp /var/debian-custom-prompt-motd/motd.conf.example /etc/motd.conf

Per-server settings live in `/etc/motd.conf` (not tracked), so updating is just:

	$ sudo git -C /var/debian-custom-prompt-motd pull --ff-only
