#!/usr/bin/perl -w 

use strict;

# This script is dirty, I know, but I don't have time to be anally retentive
# and we just need to know if any of our outputs don't conform. A human needs
# check the RAID array, not a program in any case. If this needs to be 
# refined, then we can write a better script


my $host = `hostname`;
my $megaraid_command = "/opt/MegaRAID/MegaCli/MegaCli";

# Check that the megacli command exists or die 
unless ( -e $megaraid_command ) {
	die "Problem - $megaraid_command does not exist!\n";
}


# For each Virtual Disk, we will check that it's State is Optimal
# A simple test using grep will acheive this

sub state_virtual_disks {
	my $virtual_disk_command = "$megaraid_command -LDPDInfo  -a0 | grep ^State";
	my $virtual_output = `$virtual_disk_command`;
	# print $virtual_output;
	foreach  ( split ( /\n/, $virtual_output)) {
		unless ( $virtual_output =~ /^State.* Optimal/ ) {
			&email_support("RAID array problem on $host" ,"One of the Virtual disks is not Optimal")
		} 
	}
}


sub state_physical_disks {

	# For each drive, we run a : MegaCli -PDInfo -PhysDrv [$enc:$disk] -a$ad
	# where the slot changes each time

	# Vars: 
	# enc, adaptor and disk slots are constant for our purposes across
	# all Fasthost servers
	my $enc = "252";
	my @disk_slot = (0,1,2,3);
	my $ad = "0"; 

	# Define our values in a hash
	# Get the output from the command
	# Split the lines into 2 values
	# For each line in the command output
	#  - see if we have a match for our key
	#  - if we have a match, compare the value to acceptable value
	#  - if the value is not matched, send a mail with the keys and values to support 
	# "Media Error Count"
	# "Other Error Count"
	# "Firmware State"
	# "Predictive Failure Count"
	# "Drive has flagged a S.M.A.R.T alert"
	
	my %optimal_state = ( 	'Media Error Count' => '0',
				'Firmware state' => 'Online, Spun Up',
				'Predictive Failure Count' => '0',	
				'Drive has flagged a S.M.A.R.T alert ' => 'No'
				);

	foreach my $disk ( @disk_slot ) {
		my $disk_output_command =  "$megaraid_command -PDInfo -PhysDrv [$enc:$disk] -a$ad";
		#print "$disk_output_command\n";
		my $disk_output = `$disk_output_command`;				
		#print "$disk_output\n";
		foreach my $disk_output_line  ( split ( /\n/, $disk_output)) {
			if ( $disk_output_line =~ /(.*):\s+(.*)/) {	
				my $key = $1;	
				my $value = $2;
				#print "$key:$value\n";
				foreach my $optimal_key ( keys %optimal_state) {
					if ( $key eq $optimal_key ) {
						#print "$key\n";
						if ($value ne $optimal_state{$optimal_key}) {
							&email_support("Disk issue on $host","Issue Paramaters are: \"$optimal_key: $value\" on disk $disk"); 
						}
					}
				}
			}
		}	
	} 	
}

# email subroutine to spam Stephen and Boyan
sub email_support {
        my $subject = shift;
        my $content = shift;
        system "echo \"$content\"| /bin/mail -s \"$subject\" ops\@certivox.com";
}

&state_virtual_disks;
&state_physical_disks;
