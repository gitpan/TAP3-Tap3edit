# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TAP3-Tap3edit.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('TAP3::Tap3edit') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use TAP3::Tap3edit;
use Data::Dumper;
$Data::Dumper::Indent=1;
$Data::Dumper::Quotekeys=1;
$Data::Dumper::Useqq=1;

$filename="CDOPER1OPER200001";

$notific_struct = {
    "notification" => {
      "releaseVersionNumber" => 10,
      "transferCutOffTimeStamp" => {
        "localTimeStamp" => "20040101000000",
        "utcTimeOffset" => "+0000"
      },
      "recipient" => "OPER2",
      "specificationVersionNumber" => 3,
      "fileCreationTimeStamp" => {
        "localTimeStamp" => "20040101000000",
        "utcTimeOffset" => "+0000"
      },
      "sender" => "OPER1",
      "fileSequenceNumber" => "00001",
      "fileAvailableTimeStamp" => {
        "localTimeStamp" => "20040101000000",
        "utcTimeOffset" => "+0000"
      }
    },
};


ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("TAP"));
ok($tap3->version(3));
ok($tap3->release(10));

ok($tap3->structure($notific_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

if ( -f $filename ) { unlink $filename };
