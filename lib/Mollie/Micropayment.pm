package Mollie::Micropayment;

use strict;
use warnings;

use Carp;
use LWP::Simple;
use XML::Simple;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mollie::Micropayment ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


##################################################
# Object constructor
##################################################
sub new {
	my($class,$wordlist,$replacement) = @_;
	my $self = { };

	# default vars
	$self->{'partnerid'}		= undef;
	$self->{'amount'}			= 1.30;
	$self->{'report'}			= undef;
	$self->{'country'}			= 31;
	$self->{'servicenumber'}	= undef;
	$self->{'paycode'}			= undef;
	$self->{'duration'}			= undef;
	$self->{'mode'}				= undef;
	$self->{'costperminute'}	= undef;
	$self->{'costpercall'}		= undef;
	$self->{'currency'}			= undef;
	
	# after a paycheck is done, we can use these vars
	$self->{'payed'}			= "false";
 	$self->{'durationdone'}		= 0;
 	$self->{'durationleft'}		= undef;
 	$self->{'paystatus'}		= undef;

	
	# And I give you my blessing
	return bless $self,$class;
	
}

##################################################
# For debugging purposes only!
##################################################
sub printenv {
	my $self = shift;
	foreach my $key(sort(keys(%{$self}))) {
		print $key . ": " . $self->{$key} . "\n";
	}
}

##################################################
# Set/gets the partnerid gotten from Mollie
##################################################
sub partnerid {
	my $self = shift;	
	if (@_) { $self->{"partnerid"} = shift }
	return $self->{"partnerid"};
}

##################################################
# Set/gets the amount the user has to pay
# Amount can be a float (0.00) but must be over
# 0.40 because Mollie doesn't accept amounts
# lower than 0.41
##################################################
sub amount {
	my($self,$amount) = @_;
	if ($amount > 0 || $amount eq "endless") {
	    $self->{'amount'} = $amount;
	} elsif(length($amount) == 0) {
		# It's ok, user is asking the amount
	} else {
		croak("False amount has been set. Only 'endless' or a numeric value can be set.");
	}
	return $self->{'amount'};
}

##################################################
# Sets country code. Also checks if code is OK
##################################################
sub country {
	my($self,$country) = @_;
	
	
	my %codes;
	$codes{'31'} = "NL";
	$codes{'32'} = "BE";
	$codes{'33'} = "FR";
	$codes{'39'} = "IT";
	$codes{'41'} = "CH";
	$codes{'43'} = "AT";
	$codes{'44'} = "UK";
	$codes{'49'} = "DE";

	if (int($country) && exists($codes{$country})) {
	    $self->{'country'} = $country;
	} else {
		croak("False country code used.");
	}
}

##################################################
# Sets/gets the report URL. Can be used to let Mollie
# send a response to the adres(url) in $adres
##################################################
sub reporturl {
	my $self = shift;
	if (@_) { $self->{"report"} = shift }
	return $self->{"report"};
}

##################################################
# Sets/gets the servicenumber
##################################################
sub servicenumber {
	my $self = shift;
	if (@_) { $self->{"servicenumber"} = shift }
	return $self->{"servicenumber"};	
}

##################################################
# Sets/gets paycode
##################################################
sub paycode {
	my $self = shift;
	if (@_) { $self->{"paycode"} = shift }
	return $self->{"paycode"};	
}

##################################################
# Get payment info from Mollie
##################################################
sub payinfo {
	my $self = shift;
	my $response = get(	"http://www.mollie.nl/xml/micropayment/" . 
						"?a=fetch" .
						"&partnerid=" 		. CGI::escape($self->{'partnerid'}) .
						"&amount=" 			. CGI::escape($self->{'amount'}) . 
						"&servicenumber=" 	. CGI::escape($self->{'servicenumber'}) . 
						"&country=" 		. CGI::escape($self->{'country'}) . 
						"&report=" 			. CGI::escape($self->{'report'})
						);

	if(substr($response,0,5) eq "Error") {
		croak("Error while retrieving payment info. Not a valid XML response!");
	}

	my $xs  = XML::Simple->new();
	my $xml = $xs->XMLin($response);

	$self->{'servicenumber'} 	= exists($xml->{'item'}{'servicenumber'}) 	? $xml->{'item'}{'servicenumber'} 	: undef;
	$self->{'paycode'} 			= exists($xml->{'item'}{'paycode'}) 		? $xml->{'item'}{'paycode'} 		: undef;
	$self->{'amount'} 			= exists($xml->{'item'}{'amount'}) 			? $xml->{'item'}{'amount'} 			: 0;
	$self->{'duration'} 		= exists($xml->{'item'}{'duration'}) 		? $xml->{'item'}{'duration'} 		: undef;
	$self->{'mode'} 			= exists($xml->{'item'}{'mode'}) 			? $xml->{'item'}{'mode'} 			: undef;
	$self->{'costperminute'}	= exists($xml->{'item'}{'costperminute'}) 	? $xml->{'item'}{'costperminute'} 	: undef;
	$self->{'costpercall'} 		= exists($xml->{'item'}{'costpercall'}) 	? $xml->{'item'}{'costpercall'} 	: undef;
	$self->{'currency'} 		= exists($xml->{'item'}{'currency'}) 		? $xml->{'item'}{'currency'} 		: undef;

	return 1;
}

##################################################
# Check the payment status from Mollie
##################################################
sub checkpayment {
	my $self = shift;
	my $response = get(	"http://www.mollie.nl/xml/micropayment/" . 
						"?a=check" .
						"&servicenumber=" 	. CGI::escape($self->{'servicenumber'}) .
						"&paycode=" 		. CGI::escape($self->{'paycode'}));

	if($response eq "Payment unknown.") {
		croak("Error while checking payment. Not a valid XML response!");
	}

	my $xs  = XML::Simple->new();
	my $xml = $xs->XMLin($response);

	
	$self->{'payed'} 			= exists($xml->{'item'}{'payed'}) 			? $xml->{'item'}{'payed'} 			: "false";
	$self->{'durationdone'} 	= exists($xml->{'item'}{'durationdone'}) 	? $xml->{'item'}{'durationdone'} 	: 0;
	$self->{'durationleft'} 	= exists($xml->{'item'}{'durationleft'}) 	? $xml->{'item'}{'durationleft'} 	: undef;
	$self->{'paystatus'} 		= exists($xml->{'item'}{'paystatus'}) 		? $xml->{'item'}{'paystatus'} 		: undef;
	$self->{'amount'} 			= exists($xml->{'item'}{'amount'}) 			? $xml->{'item'}{'amount'} 			: undef;
	$self->{'duration'} 		= exists($xml->{'item'}{'duration'}) 		? $xml->{'item'}{'duration'} 		: undef;
	$self->{'mode'} 			= exists($xml->{'item'}{'mode'}) 			? $xml->{'item'}{'mode'} 			: undef;
	$self->{'costperminute'} 	= exists($xml->{'item'}{'costperminute'}) 	? $xml->{'item'}{'costperminute'} 	: undef;
	$self->{'costpercall'} 		= exists($xml->{'item'}{'costpercall'}) 	? $xml->{'item'}{'costpercall'} 	: undef;
	$self->{'currency'} 		= exists($xml->{'item'}{'currency'}) 		? $xml->{'item'}{'currency'} 		: undef;

	return $self->{'payed'};
}

##################################################
# Check if user has completed payment or not
##################################################
sub is_payed {
	my $self = shift;
	return $self->{'payed'};
}

##################################################
# Retrieve currency (eur,dollar,gbp)
##################################################
sub currency {
	my $self = shift;
	return $self->{'currency'};
}

##################################################
# Retrieve the mode (ppc or ppm)
##################################################
sub mode {
	my $self = shift;
	return $self->{'mode'};
}

##################################################
# Retrieve cost per call. Only for ppc
##################################################
sub costpercall {
	my $self = shift;
	return $self->{'costpercall'};
}

##################################################
# Retrieve cost per minute. Only for ppm
##################################################
sub costperminute {
	my $self = shift;
	return $self->{'costperminute'};
}

##################################################
# Retrieve duration of call for ppm
##################################################
sub duration {
	my $self = shift;
	return $self->{'duration'};
}


1;
__END__

=head1 NAME

Mollie::Micropayment - Perl API for Mollie's Micropayment service

=head1 SYNOPSIS

  # Basic setup. Example included that fully handles payment

  use Mollie::Micropayment;
  
  my $mollie = new Mollie::Micropayment;
  $mollie->partnerid(10000);				# Set your account ID
  $mollie->amount(0.50);				# Set the amount to pay (EUR 0.50)
  $mollie->country(31);					# Set the country code (Netherlands)

  # Handle payment
  $mollie->checkpayment()
  if ($mollie->is_payed() eq "true") {
      print 'User payed succesfully!';
  } else {
      print 'payment is not (fully) done, send the user back to the payment-screen';
  }
  
  # Show payment screen
  if ($mollie->is_payed() eq "false" && $mollie->payinfo()) {
	   # print information about how to pay and put a submit button here. Look at included example
  } else {
	  print 'Unable to fetch payment info';
  }


=head1 DESCRIPTION

C<Mollie::Micropayment> is an API to handle micropayments from Mollie.nl. It's design and usage is based on the PHP class.

=head2 METHODS
The following methods can be used

=head3 new

C<new> creates a new C<Mollie::Micropayment> object.

=head3 printenv

Use this for debugging. It contains the information returned by XML responses from Mollie.nl.

=head3 partnerid

Set and/or get your Mollie account ID.

=head3 amount

Set and/or get the amount of money you want for the payment. Value can be a integer or float. Do not set a value under 0.41. This is because Mollie returns a error when using a value that's too low.

=head3 country

Set your country code. Default is 31, which is for the Netherlands. If a wrong country code has been set the script will give a error.

	Country  	Country code
	Netherlands	31
	Belgium		32
	Germany		49
	England		44
	France		33
	Italy		39
	Switserland	41
	Austria		43

=head3 servicenumber

Set and/or get the telephone number that the user has to call. 

=head3 paycode

Set and/or get the paycode. This is the code that the user has to enter through the phone.

=head3 payinfo

Requests new payment info from Mollie.nl.

=head3 checkpayment

Checks the status of the current payment.

=head3 is_payed

Returns 'true' if the payment is completed. 'false' If the payment is still in progress or not yet finished.

=head3 currency

The currency in which the user has to pay. Currently the next currencies can be returned by Mollie.nl:

	eur
	dollar
	gbp

=head3 costpercall

Returns the amount of money the user has to pay for a call.

=head3 costperminute

Returns the amount of money the user has to pay per minute.

=head3 duration

Returns the estimated time in seconds the user has to stay on the phone

=head3 mode

Returns the type of phonecall. Mollie chooses the best solution for the given amount. These are:

	cpc	cost per call
	ppm	pay per minute

=head2 EXPORT

None by default.

=head1 SEE ALSO

More info about Mollie.nl micropayments can be fount at L<http://www.mollie.nl/informatie/micropayments/>

You need an account at Mollie.nl to view the technical documentation. Please read it before you use this module.

A online example can be viewed and downloaded at the following adress: L<http://perl.pcc-online.net/Mollie-Micropayment/>.
The example has also been included in this release. It's located in the directory /scripts.

=head1 AUTHOR

C. Kras, E<lt>c.kras@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by C. Kras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
