#!/usr/bin/perl

# John Miller 2011/05/16

# ./bond.pl --read=(eth*|bond*|IP|int) --slave1=eth0 --slave2=eth1 --master=bond0 --mask=127.0.0.1 --gateway=127.0.0.1

# Automate NIC bonding in RHEL/CentOS
#
# The bond will be created using the input from the 'read' variable. If "eth*" or "bond*" is used for --read intead of
# an IP it will use that NIC's current IP for the bond. 'nic1' and 'nic2' are the NIC's that are to be bonded. The
# 'bond' variable is the bond number the NIC's will be assigned to.  'mask' and 'gateway' are the netmask and gateway
# to be used by the new bond.  Use the --keepmac for those servers that require the MAC address in the ifcfg-eth* slave
# configs.

use Getopt::Long;

GetOptions( "read=s", "slave1=s", "slave2=s", "master=s", "mask=s", "gateway=s", "keepmac" );

$scripts_path = '/etc/sysconfig/network-scripts/';

if ($opt_read eq '' || $opt_slave1 eq '' || $opt_slave2 eq '' || $opt_master eq '' || $opt_mask eq '' || $opt_gateway eq '') {
    print STDERR "I need ALL options!\n";
	print STDERR "\n";
	print STDERR "./bond.pl --read=(eth*|bond*|IP) --slave1=eth0 --slave2=eth1 --master=bond0 --mask=127.0.0.1 --gateway=127.0.0.1\n";
    exit(1);
}

getip();
slave1_config();
slave2_config();
master_config();
modconfig();
system("/etc/init.d/network stop");
system("modprobe bonding");
system("/etc/init.d/network start");

sub getip {
	if ($opt_read eq "int") {
		$findip = `ifconfig bond0 | grep 'inet addr' | cut -f2 -d':' | cut -f1 -d' '`;
		chomp($findip);
		$intip = `echo $findip | sed 's/10.100./10.200./'`;
		chomp($intip);
		$master_ip = $intip;
	}
	if ($opt_read =~ /eth/ || $opt_read =~ /bond/) {
		$findip = `ifconfig $opt_read | grep 'inet addr' | cut -f2 -d':' | cut -f1 -d' '`;
		chomp($findip);
		$master_ip = $findip;
	}
	if ($master_ip eq '') {
		$master_ip = $opt_read;
	}
}

sub slave1_config {
	if ($opt_keepmac eq '') {
		system("cat $scripts_path/ifcfg-$opt_slave1 | grep -v '' > /tmp/slave1.new");
	}
	else {
		system("cat $scripts_path/ifcfg-$opt_slave1 | grep -i HWADDR > /tmp/slave1.new");
	}
	
	system("cat /tmp/slave1.new > $scripts_path/ifcfg-$opt_slave1");
	open(SLAVE1, ">>$scripts_path/ifcfg-$opt_slave1");
	print SLAVE1 "DEVICE=$opt_slave1\n";
	print SLAVE1 "USERCTL=no\n";
	print SLAVE1 "ONBOOT=yes\n";
	print SLAVE1 "MASTER=$opt_master\n";
	print SLAVE1 "SLAVE=yes\n";
	print SLAVE1 "BOOTPROTO=none\n";
	close(SLAVE1);
}

sub slave2_config {
	if ($opt_keepmac eq '') {
		system("cat $scripts_path/ifcfg-$opt_slave2 | grep -v '' > /tmp/slave2.new");
	}
	else {
		system("cat $scripts_path/ifcfg-$opt_slave2 | grep -i HWADDR > /tmp/slave2.new");
	}
	
	system("cat /tmp/slave2.new > $scripts_path/ifcfg-$opt_slave2");
	open(SLAVE2, ">>$scripts_path/ifcfg-$opt_slave2");
	print SLAVE2 "DEVICE=$opt_slave2\n";
	print SLAVE2 "USERCTL=no\n";
	print SLAVE2 "ONBOOT=yes\n";
	print SLAVE2 "MASTER=$opt_master\n";
	print SLAVE2 "SLAVE=yes\n";
	print SLAVE2 "BOOTPROTO=none\n";
	close(SLAVE2);
}

sub master_config {
	open MASTER, "> $scripts_path/ifcfg-$opt_master" or die "Can't open $scripts_path/ifcfg-$opt_master: $!\n";
	print MASTER <<"EOL";
DEVICE=$opt_master
IPADDR=$master_ip
NETMASK=$opt_mask
GATEWAY=$opt_gateway
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
USERCTL=no
STARTMODE=onboot
BONDING_MASTER=yes
BONDING_SLAVE0=$opt_slave1
BONDING_SLAVE1=$opt_slave2
EOL
}

sub modconfig {
   if(-f "/etc/modprobe.conf") {
      $modconfig = "/etc/modprobe.conf";
   }
   else {
      $modconfig = "/etc/modules.conf";
   }

	$bondcount = `echo $opt_master | egrep "[0-9]{1,}" -o`;
	chomp($bondcount);
	$bonding = "bonding" . $bondcount;
	chomp($bonding);

	system("cat /etc/sysconfig/network | grep -v BONDING > /tmp/network.new");
	system("cat /tmp/network.new > /etc/sysconfig/network");
	open(CONFIG, ">>/etc/sysconfig/network");
	print CONFIG "BONDING_OPTS=\"mode=1 miimon=100\"\n";
	close(CONFIG);

	system("cat $modconfig | grep -v $opt_master > /tmp/modconfig.new");
	system("cat /tmp/modconfig.new > $modconfig");
	open(CONFIG, ">>/etc/modprobe.conf");
	print CONFIG "alias $opt_master bonding\n";
	print CONFIG "install $opt_master \/sbin\/modprobe bonding -o $bonding miimon=100 mode=1\n";
	close(CONFIG);
}
