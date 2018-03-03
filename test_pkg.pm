package dayofweek {
  our $sunday = "nitiyo";
  our $monday = "getuyo";
};

package month;
  our $jan = 1;
  our $dec = 12;

{
  package  tvchannel;
    sub new(){
      my $name = "tvchannel";

      my $self = {
        tbs => 4,
        'asashi' => 5,
        ntv => 6,
      };
      return bless $self, $name;
    }
};

package  eto;
our $mouse = 'ne';
our $cow = 'uchi';
our $tiger = 'tora';
sub zodiac_sign_of(){
  my $year =shift;
  return $tiger if($year == 2034);
}

package  radiochannel;
our $jokr= "tbsradio";
our $jolf= "nipponhoso";
our $joqr= "bunkahoso";
use constant DEBUG => 1;
1;
