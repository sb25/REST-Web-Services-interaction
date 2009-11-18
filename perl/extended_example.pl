#!/usr/bin/env perl

#
# Author:: Sebastien Briois (mailto:sb25@sanger.ac.uk)
#
# This is an example script demonstrating how you can
# interact with the I-DCC Targeting Repository via its
# web services interface.
#
# In this Perl example we use the HTTP module to
# handle the HTTP requests, and use JSON as our data
# encapsulation method.
#
# If you plan to use Perl to upload your data, you can
# simply copy this script and just modify the function
# 'get_alleles_to_load' to read in real data from your
# systems.

# In your scripts, this would be where you access your 
# database(s) and build up structures of your alleles and 
# products.

use strict;
use warnings FATAL=>'all';
use JSON;
use LWP::UserAgent;
use URI;
use Smart::Comments;

my %pipelines;

#
# Define our connection parameters
#
my $uri_base = 'http://htgt:htgt@localhost:3000';
my $browser = LWP::UserAgent->new;

#
# Methods
#

# Generic helper method for handling the web calls to the 
# repository.  Gives us a single place to handle service errors.
sub request {
  my ($method, $url, $data) = @_;
  $method ||= 'GET';
  
  my $request = HTTP::Request->new($method => $uri_base.'/'.$url);
  if ($method =~ /^(POST|PUT)$/) {
    $request->content_type('application/json');
    $request->content($data);
  }
  
  # Send the request and get the response
  my $response = $browser->request($request);
  
  # Check the outcome of the response
  if ($response->is_success) {
    return $response->content;
  } 
  else {
    die $response->content."\n";
  }
}

sub get_alleles_to_load {
  return 
  [
    {
      pipeline_id               => $pipelines{'KOMP-Regeneron'},
      ikmc_project_id             => 35507,
      allele_symbol_superscript   => 'tm1a(Regeneron)Wtsi',
      mgi_accession_id            => 'MGI:44557',
      assembly                    => 'NCBIM37',
      chromosome                  => '11',
      strand                      => '+',
      design_type                 => 'KO',
      design_subtype              => 'Frameshift',
      homology_arm_start          => 10,
      homology_arm_end            => 10000,
      cassette_start              => 50,
      cassette_end                => 500,
      loxp_start                  => 1000,
      loxp_end                    => 1500,
      cassette                    => 'L1L2_gt1',
      backbone                    => 'L3L4_pZero_kan',
      intermediate_vector         => 'PCS00041_A',
      targeting_vector            => 'PGRGS00041_A',
      products                    => [
        { escell_clone => "EPD00064_1_A01" },
        { escell_clone => "EPD00064_1_A03" },
        { escell_clone => "EPD00064_1_A04" },
        { escell_clone => "EPD00064_1_A05" }
      ]
    },
    {
      pipeline_id                 => $pipelines{NorCOMM},
      ikmc_project_id             => 35507,
      allele_symbol_superscript   => 'tm1e(NorCOMM)Wtsi',
      mgi_accession_id            => 'MGI:44557',
      assembly                    => 'NCBIM37',
      chromosome                  => '11',
      strand                      => '+',
      design_type                 => 'KO',
      design_subtype              => 'Frameshift',
      homology_arm_start          => 10,
      homology_arm_end            => 10000,
      cassette_start              => 50,
      cassette_end                => 500,
      cassette                    => 'L1L2_gt3',
      backbone                    => 'L3L4_pZero_kan',
      intermediate_vector         => 'PCS00041_A',
      targeting_vector            => 'PGS00041_A',
      products                    => [
        { escell_clone => "EPD00064_1_A02" }
      ]
    }
  ];
}

# Helper function to interact with the web services and find 
# an allele.
sub find_allele {
  my ($allele) = @_;

  my $allele_search_url = "alleles.json?".
    "allele_symbol_superscript=$allele->{allele_symbol_superscript}&".
    "ikmc_project_id=$allele->{ikmc_project_id}&".
    "mgi_accession_id=$allele->{mgi_accession_id}";
  my $alleles_as_json = request('GET', $allele_search_url );
  
  # Check that we have a unique allele - the repository does 
  # handle this for us, but you can't be too cautious!
  my $alleles = from_json($alleles_as_json);
  if (@$alleles > 1) {
    die "Error: found more than one allele for ".
    "$allele->{mgi_accession_id} | $allele->{allele_symbol_superscript}!";
  }
  if (@$alleles == 1) {
    return $alleles->[0];
  }
  return;
}

# Helper function to interact with the web services and create
# an allele.
sub create_allele {
  my ($allele) = @_;
  my $json = to_json($allele);
  my $allele_as_json = request( 'POST', 'alleles.json', "{\"allele\":$json}" );
  return from_json($allele_as_json);
}

# Helper function to interact with the web services and find 
# a product.
sub find_product {
  my ($product) = @_;
  my $product_search_url = "products.json?escell_clone=$product->{escell_clone}";
  my $product_as_json = request('GET', $product_search_url);
  
  # Check that we have a unique product - the repository does 
  # handle this for us, but you can't be too cautious!
  my $products = from_json($product_as_json);

  if (@$products > 1) {
    die "Error: found @$products products entries for $product->{escell_clone}!"."\n";
  }
  if (@$products == 1) {
    return $products->[0];
  }
  return;
}

# Helper function to interact with the web services and create 
# a product.
sub create_product {
  my ($allele, $p) = @_;
  my $product = to_json({
    product => { 
      escell_clone => $p->{escell_clone}, 
      allele_id => $allele->{id}
    }
  });
  my $product_as_json = request('POST', 'products.json', $product);
  return from_json($product_as_json);
}


#
# Main body of script
#

# First communicate with the repository and get a list 
# of all of the pipelines represented and their details.
#
# (We're storing the pipeline details in a hash, keyed 
# by the pipeline name for use in the allele building).
my $pipeline_data = request( 'GET', 'pipelines.json' );
my $pipeline_as_json = from_json($pipeline_data);
for my $pipeline ( @$pipeline_as_json ) {
  $pipelines{ $pipeline->{name} } = $pipeline->{id};
}

# Now we define the alleles and products that we want 
# to load into the repository.
#
# (In your code you will need to retrieve data from 
# your production systems here).
#
# NOTE that we also define the pipeline_id here when 
# constructing our object.
my $alleles = get_alleles_to_load();

#
# Now we shall loop through each of our alleles and 
# create entries in the targeting repository for both 
# the alleles and their products.
#

for my $a (@$alleles) {
  
  # First we must remove the products from the allele 
  # data structure - these must be processed in a seperate 
  # transaction.  Leaving them in the data structure 
  # will cause errors!
  my $allele_products = $a->{products};
  delete $a->{products};
  
  # See if our Allele is already in the database
  my $allele = find_allele($a);

  unless ($allele) {
    # Looks like we have to create our allele entry
    $allele = create_allele($a);
  }

  # Now work on our allele_products
  for my $p (@$allele_products) {
    # See if our product is already in the database
    my $product = find_product($p);

    unless ($product) {
      # If not, create it
      $product = create_product( $allele, $p );
    }
  }

}