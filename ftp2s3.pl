#!/usr/bin/perl

use Getopt::Long;

# INFO: An automated script to locally mirror files from an FTP host and then archive to Amazon s3 after X days.
# OS: CentOS 6.x
# REQUIRED: yum install tee lftp lftp-scripts cpan s3cmd; cpan Getopt::Long;

# OPTIONS

GetOptions(
    "log=s",
    "host=s",
    "user=s",
    "pass=s",
    "source=s",
    "target=s",
    "maxage=s",
    "bucket=s",
    "lastrun=s",
    "skipftp",
    "deletesource",
    "s3delmissing",
    "cleanup",
    "info");

# Create Job Timestamp
$timestamp = time();

# SETUP

# Default Log File
if (!$opt_log) {
    $opt_log = "/ftp2s3/$timestamp.log";
    print STDOUT "INFO: --log not provided. Default: $opt_log\n";
}
else {
    print STDOUT "INFO: --log=$opt_log\n";
}

# Open Log
system("touch $opt_log");

# Forward STDOUT to log
open (STDOUT, "| tee -ai $opt_log");

# Default Max Age
if (!$opt_maxage) {
    $opt_maxage = "12am - 31days";
    print STDOUT "INFO: --maxage not provided. Default: \"$opt_maxage\"\n";
}
else { print STDOUT "INFO: --maxage=\"$opt_maxage\"\n"; }

# Default FTP Hostname
if (!$opt_host) {
    $opt_host = "localhost";
    print STDOUT "INFO: --host not provided. Default: $opt_host\n";
}
else { print STDOUT "INFO: --host=$opt_host\n"; }

# Default FTP Username
if (!$opt_user) {
    $opt_user = "guest";
    print STDOUT "INFO: --user not provided. Default: $opt_user\n";
}
else { print STDOUT "INFO: --user=$opt_user\n"; }

#Default FTP Password
if (!$opt_pass) {
    $opt_pass = "guest";
    print STDOUT "INFO: --pass not provided. Default: $opt_pass\n";
}
else { print STDOUT "INFO: --pass=$opt_pass\n"; }

# Default FTP Source Folder
if (!$opt_source) {
    $opt_source = "/";
    print STDOUT "INFO: --source not provided. Default: $opt_source\n";
}
else { print STDOUT "INFO: --source=$opt_source\n"; }

# Default Local Target Directory
if (!$opt_target) {
    $opt_target = "/ftp2s3/TARGET/";
    print STDOUT "INFO: --target not provided. Default: $opt_target\n";
}
else { print STDOUT "INFO: --target=$opt_target\n"; }
system("mkdir -p $opt_target");

# Default s3 Target Bucket
if (!$opt_bucket) {
    $opt_bucket = "s3://localhost/ftp2s3/$timestamp/";
    print STDOUT "INFO: --bucket not provided. Default: $opt_bucket\n";
}
else { print STDOUT "INFO: --bucket=$opt_bucket\n"; }

# Default Job Cleanup
if ($opt_cleanup) {
    print STDOUT "INFO: --cleanup ENABLED\n";
    if (!$opt_lastrun) {
            $opt_lastrun = "/ftp2s3/LASTRUN/";
            print STDOUT "INFO: --lastrun not provided. Default: $opt_lastrun\n";
    }
    else { print STDOUT "INFO: --lastrun=$opt_lastrun\n"; }
   system("mkdir -p $opt_lastrun");
}
else { print STDOUT "INFO: --cleanup not provided. Default: DISABLED\n"; }

# Default Delete Source from FTP
if (!$opt_deletesource) {
    print STDOUT "INFO: --deletesource not provided. Default: DISABLED\n";
        $mirroropt = "--loop --continue --verbose=3 --older-than=\"$opt_maxage\"";
}
else {
    print STDOUT "INFO: --deletesource ENABLED\n";
        $mirroropt = "--loop --continue --verbose=3 --older-than=\"$opt_maxage\" --Remove-source-files";
}

# Default s3 Delete Missing
if (!$opt_s3delmissing) {
    print STDOUT "INFO: --s3delmissing not provided. Default: DISABLED\n";
    $s3cmd = "for run in {1..2}; do s3cmd sync -r $opt_target $opt_bucket; done;";
}
else {
    print STDOUT "INFO: --s3delmissing ENABLED\n";
    $s3cmd = "for run in {1..2}; do s3cmd sync --delete-removed -r $opt_target $opt_bucket; done;";
}

# Default Skip FTP
if (!$opt_skipftp) {
    print STDOUT "INFO: --skipftp not provided. Default: DISABLED\n\n";
}
else {
        print STDOUT "INFO: --skipftp ENABLED\n\n";
}

# Configure
$timeout = "600";
$lftpopt = "set net:timeout $timeout; set xfer:verify yes; set xfer:verify-command /usr/share/lftp/verify-file";
$lftpcmd = "lftp -e '$lftpopt; mirror $mirroropt $opt_source $opt_target; exit' -u $opt_user,$opt_pass $opt_host";

if ($opt_info) {
        print STDOUT "LFTP Options: $lftpopt\n";
        print STDOUT "LFTP CMD: $lftpcmd\n\n";
        print STDOUT "s3 CMD: $s3cmd\n";
        exit;
}

# Cleanup
if ($opt_cleanup) {
    print STDOUT "Deleting $opt_lastrun* ....\n";
    system("rm -rf $opt_lastrun*");
    print STDOUT "Moving $opt_target* to $opt_lastrun ....\n";
    system("mv $opt_target* $opt_lastrun");
}

# Execute LFTP Transfer
system("mkdir -p $opt_target");
if ((!$opt_deletesource) && (!$opt_skipftp)) { print STDOUT "\nExecuting lftp run....\n"; }
elsif (!$opt_skipftp) { print STDOUT "\nExecuting lftp run with post-transfer source deletion....\n"; }
if (!$opt_skipftp) {
        print STDOUT "$lftpcmd\n\n";
        system("$lftpcmd");
}


# Remove Empty Folders
system("find $opt_target -empty -type d -delete"); # Remove Empty Folders

# Wait for LFTP background task to complete before executing s3 sync
$lftp_running=`ps -ef | grep lftp | grep -v grep | wc -l`;
while ("$lftp_running" != 0) {
    system("echo LFTP is still running! Waiting for 10mins more....\n");
    system("sleep 600");
    $lftp_running=`ps -ef | grep lftp | grep -v grep | wc -l`;
}

# Execute s3 Sync
print STDOUT "\nExecuting s3 sync....\n";
print STDOUT "$s3cmd\n\n";
system("$s3cmd");

# Eexit
print STDOUT "ALL DONE!\n";
close (STDOUT);
