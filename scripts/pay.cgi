#!/usr/bin/perl
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Mollie::Micropayment;

my $cgi	   = new CGI;
my $mollie = new Mollie::Micropayment();

print $cgi->header();

# change this to your partner ID
$mollie->partnerid(10000);

if(length($cgi->param("c")) > 0) {
	$mollie->country($cgi->param("c"));
}

# Set payment amount
$mollie->amount(1.30);


if (length($cgi->param("servicenumber")) > 0 && length($cgi->param("paycode")) > 0) {
    # user posted a paymentcheck, so below we'll check if the servicenumber and the paycode is fully payed
    
    $mollie->servicenumber($cgi->param("servicenumber"));
    $mollie->paycode($cgi->param("paycode"));
    $mollie->checkpayment();
    
    if($mollie->is_payed() eq "true") {
        # User payed succesfully!
        # Now, do your thing: for example put credits on the users account, or give access to premium content
        
        print '<b>Thank you for your payment</b><br />
              Your payment has been recieved.';
    } else {
        # payment is not (fully) done, send the user back to the payment-screen
        print '<font color=red><b>Payment not complete,<br />please read the instructions!</b></font><br /><br />';
    }
}

if ($mollie->is_payed() eq "false") {
    # Below we include the payment-screen, because no payment is received (yet)
    my($gotpayinfo,$cur);
	if ($mollie->servicenumber() && $mollie->paycode()) {
	    $gotpayinfo = 1;
	} else {
	    $gotpayinfo = $mollie->payinfo();
	}
	
	if ($gotpayinfo) {
	    if ($mollie->currency() == 'eur') {
	        $cur = '&euro;';
	    } elsif ($mollie->currency() == 'dollar') {
	        $cur = '$';
	    } elsif ($mollie->currency() == 'gbp') {
	        $cur = '&pound;';
	    }
	    
	    # landen keuze
	    print '
	    <small>Choose a country for payment:</small><br />
	    <table>
	    <tr>
	    <td><a href="./pay.cgi?c=31"><img src="./images/flag-31.gif" width="20" height="12" border="" alt="flag 31" style="border: 1px solid black" /></a></td>
	    <td><a href="./pay.cgi?c=31">Netherlands</a></td>
	    <td width="10"> </td>
	    <td><a href="./pay.cgi?c=32"><img src="./images/flag-32.gif" width="20" height="12" border="" alt="flag 31" style="border: 1px solid black" /></a></td>
	    <td><a href="./pay.cgi?c=32">Belgium</a></td>
	    </tr>
	    </table>
	    <br />';

 	    print 'To pay ' . $cur . sprintf("%.2f",$mollie->amount()) . ' please follow these steps:<br /><br />
 	    	   <font size="4"><b>Call ' . $mollie->servicenumber() . '</b></font><br />
	    	   <small>';
	    	   
	    if ($mollie->mode() eq 'ppc') {
	        print $cur . sprintf("%.2f",$mollie->costpercall()) .' per call';
	    } elsif ($mollie->mode() eq 'ppm') {
	        print $cur . sprintf("%.2f",$mollie->costperminute()) .' per minute, about ' . $mollie->duration() . ' seconds';
	        # With an iframe or AJAX you could do a realtime payment check.
	        # Or maybe something like a progress bar that shows the user
	        # how long he/she still has to wait
	    }
	    print '</small>
				 <br />
	    		 And enter the following code: <font size="4"><b>' . $mollie->paycode() . '</b></font><br /><br />
	    		 <form method="get">
	             	<input type="hidden" name="servicenumber" value="' . $mollie->servicenumber() .'">
	              	<input type="hidden" name="paycode" value="' . $mollie->paycode() . '">
	              	<input type="submit" value="Click here after paying">
	             </form>';
	} else {
	    print 'Could not retrieve payment information.';
	}
}
