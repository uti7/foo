package e {
  sub new (){
  my $n = shift;
    my $self = {
      message => "Transfer Complete",
      };
    return bless $self, $n;
    }
    sub message()
    {
      $self = shift;
      return $self->{message};
    }
};
my $f = e->new(); 
print $f->message . "\n";
