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
        asashi => 5,
        ntv => 6,
      };
      return bless $self, $name;
    }
};
1;
