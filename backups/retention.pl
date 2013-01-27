#!/usr/bin/perl -w

# This script is a retention script which prunes
# backups according to a policy which does the following:
# 1. Keep the past 7 days backups
# 2. Keep the past 4 weekly backups on a Sunday
# 3. Keep the past 12 months of backups of the 1st day of the month
# It looks in a dir which is filled with dirs
# named after days - the format: YYYYMMDD and parses
# the listing to apply the above policy

use strict;
use Date::Pcalc qw(Today Parse_Date Add_Delta_Days Monday_of_Week Week_of_Year);
use File::Path;

my $dir = "/mongodb_backups";	

sub get_list_of_backups_to_keep {
	my @today = Today();
	# For testing
	#my @today = ( "2011" ,"7", "12" );
	my ($t_year,$t_month,$t_day) = @today;

	# Get an array of the previous 7 days
	my $days = "8";
	my @list_keep_backups;
	while ($days >= 0) {
		my @day = Add_Delta_Days($t_year,$t_month,$t_day, -${days});	
		push (@list_keep_backups,[@day] );	
		$days--;
	}

	# Get an array of the previous 4 Sundays:
	# Firstly, get the Sunday for the current week
	my @sunday_this_week = Add_Delta_Days(Monday_of_Week(Week_of_Year(@today)),6);

	my $sundays="28";
	my @last_4_sundays;
	while ($sundays > 0 ) {
		my @sunday = Add_Delta_Days(@sunday_this_week, -$sundays);
		push (@list_keep_backups, [@sunday]);
		$sundays = $sundays - 7;
	}

	# Get an array of the previous 12 1st day of the Month
	# $t_month is the current month so we take that and use 11 - $t_month 
	# to get the months required for the previous year

	my $previous_year_months = 11 -$t_month ;
	my $current_year_months = $t_month ;

	# Current year array:
	my @first_month_year;
	while ( $current_year_months > 0 ) {
		my @first_of_month = ($t_year,$current_year_months,1);
		push (@list_keep_backups ,[@first_of_month]);
		$current_year_months--;
	}
	# Previous year array;
	my $last_year = $t_year -1;
	my @previous_year_1st_month;
	while ( $previous_year_months >= 0 ) {
		my $real_month = 12 - $previous_year_months;
		my @first_of_month = ($last_year,$real_month,1);
		push (@list_keep_backups, [@first_of_month]);
		$previous_year_months--; 
	}
	return @list_keep_backups;
}
sub get_list_backups {
	my @list_backups;
	opendir DIR, $dir or die "Can't open directory $dir: $!\n";
	while (my $file= readdir DIR) {
		# filter for the backup dirs
		# Very basic sanity check
		if ( $file =~ m/(20\d{2})(\d{2})(\d{2})/ ) {
			my $year = $1;
			my $month = $2;
			my $day = $3;
			$month =~ s/0(\d{1})/$1/ ;
			$day =~   s/0(\d{1})/$1/;
			my @date = ("$year", "$month", "$day");
			push (@list_backups, [@date]);
		}
	}
	closedir DIR;
	return @list_backups;
}
my @actual_backups = &get_list_backups;
my @wanted_backups = &get_list_of_backups_to_keep;

# We want to convert these dates into backup
# dir names. The format is:
# 20110530 for the 30th May 2011

sub convert_dates_to_dirs {
	# We are passed a REFERENCE
	# to an array
	# so dereference it
	my $passed_array_ref = shift;
	my @passed_array = @$passed_array_ref;	
	my @finished_dirs;
	foreach (@passed_array) {
		my @date = @$_;
		my $dir = sprintf '%04d%02d%02d',$date[0],$date[1],$date[2];
	push (@finished_dirs, $dir);
	}
	return @finished_dirs;
}
my ($wanted, $actual);
my @wanted_dirs_raw = &convert_dates_to_dirs(\@wanted_backups);
my @actual_dirs = &convert_dates_to_dirs(\@actual_backups);

# We need to filter out multiple occurrences of
# wanted dirs

my %seen = (); 
my @wanted_dirs;
foreach my $item (@wanted_dirs_raw) { 
	push(@wanted_dirs, $item) unless $seen{$item}++; 
	}

#### tests ####
#print "What we want\n";
#foreach my $liz (@wanted_dirs) {
#	print "$liz\n";
#}
#print "What we have\n";
#foreach my $stan (@actual_dirs) {
#	print "$stan\n";
#}
#### end tests ####

# Now we have a list of dirs. We want to find the dirs that are not
# in @wanted_dirs
my %count;
my (@keep,@delete);
my $date;
foreach $date (@wanted_dirs,@actual_dirs) {
	$count{$date}++;	
	if ( $count{$date} == 2 ) {
		push (@keep, $date);
		#print "Keep: $date\n";
	}
}
foreach my $date ( keys %count ) {
	if ( $count{$date} == 1) {
		push (@delete, $date);
		#print "Delete: $date\n";
	}
}


# Now we delete any of these files that exist
foreach my $delete_dir (@delete) {
	if ( -e "$dir/$delete_dir" ) {
		rmtree ("$dir/$delete_dir");		
		#print "Delete: $delete_dir\n";
	}
}

