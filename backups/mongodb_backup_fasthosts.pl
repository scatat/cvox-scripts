#!/usr/bin/perl -w

# We run an fsync command to mongo which 
# is verified as sucessful, then 
# run the mongodump.
# When the mongodump is completed and exits
# cleanly, we run the unlock of the db

use MongoDB;
use MongoDB::Admin;

$backup_host = ( "api.vm.example.com" );

sub email_support {
	$subject = shift;
	$content = shift;
	system "echo \"$content\"| /usr/bin/mail -s \"$subject\" support\@example.com";
}
#print "Host to be backed up is: $backup_host\n";

# Open a connection to backup host
my $back_connection = MongoDB::Connection->new(host => "$backup_host", port => 27017);
my $back_admin = MongoDB::Admin->new('connection' => $back_connection);

# Check that the host is not locked already. If it is
# then wait for 5 mins and if it still is locked
# then email user and die
# The reason for this is there **might** be 
# another person locking deliberately and we want 
# wait until they have finished
my $locked = 1;
my $sleep = 0;
until ( $locked == 0  ) {
	$locked = $back_admin->fsync_lock_check();	
	#print "locked var: $locked\n";
	sleep 1;
	$sleep++;
	if ( $sleep == 300 ) {
		email_support("$backup_host locking problems","Host is locked for 5 mins");
		die;
	}
}
# Lock mongodb
my $locked_ret = $back_admin->fsync_lock();
if ( $locked_ret != 1 ) {
	email_support("Unable to lock $backup_host","Was unable to lock mongodb using fsync_lock ");	
}
my $date = `/bin/date +%Y%m%d`;
my $backup_complete = `/usr/bin/mongodump -h $backup_host -o /mongodb_backups/$date`;
my $error = $?;
#print "error is $error\n";
if ( $error == 0 ) {
	email_support("Backup of $backup_host completed","$backup_complete");
	system "/usr/local/bin/retention.pl";
}
elsif ( $error > 0 ) {
	email_support("Backup of $backup_host did not complete","Connect to $backup_host to check");
}
# Unlock mongodb
my $unlocked = $back_admin->unlock();
#print "unlocked is $unlocked\n";
unless ( $unlocked == 1 ) {
	email_support("Unable to unlock $backup_host","Connect to admin server to check");	
}

