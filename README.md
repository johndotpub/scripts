scripts
=======

## bond.pl
```
./bond.pl --read=(eth*|bond*|IP|int) --slave1=eth0 --slave2=eth1 --master=bond0 --mask=127.0.0.1 --gateway=127.0.0.1
```
Automates NIC bonding in RHEL/CentOS (Tested on RHEL5/6)

The bond will be created using the input from the 'read' variable. If "eth*" or "bond*" is used for --read intead of
an IP it will use that NIC's current IP for the bond. 'nic1' and 'nic2' are the NIC's that are to be bonded. The
'bond' variable is the bond number the NIC's will be assigned to.  'mask' and 'gateway' are the netmask and gateway
to be used by the new bond.  Use the --keepmac for those servers that require the MAC address in the ifcfg-eth* slave
configs.

## ftp2s3.pl
```
./ftp2s3.pl
```
**REQUIRED** `yum install tee lftp lftp-scripts cpan s3cmd; cpan Getopt::Long;`

An automated script to locally mirror files from an FTP host and then archive to Amazon s3 after X days.

## s3cmd-du.pl
```
./s3cmd-du.pl s3://BUCKET
```
Convert `s3cmd du` output from bits to human readable format.

Unlicense
---------

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
