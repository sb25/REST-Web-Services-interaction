use LWP::UserAgent;
use URI;
use JSON;

# Settings
my $browser = LWP::UserAgent->new;
my $url_base = 'http://user:password@localhost:3000';

# Helper method
sub request {
  my ($method, $url, $data) = @_;
  $method ||= 'GET';
  
  my $request = HTTP::Request->new($method => $url_base.'/'.$url);
  
  if ($method =~ /^(POST|PUT)$/) {
    $request->content_type('application/json');
    $request->content($data);
  }
  
  my $response = $browser->request($request);
  
  if ($response->is_success) {
    return $response->content;
  } 
  else {
    die $response->content."\n";
  }
}

# Examples

# Get allele list - first page
my $alleles_as_json = request( 'GET', 'alleles.json?page=1' );
print from_json( $alleles_as_json );

# Get allele id 1 - no need to keep track of the ids a search method is 
# provided in the extended example.
my $allele_as_json = request( 'GET', 'alleles/1.json' );
print from_json( $allele_as_json );

# Create an allele
my %data = 
( allele =>
  {
    pipeline_id                 => 1,
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
    targeting_vector            => 'PGRGS00041_A'
  }
);

my $allele_as_json = request( 'POST', 'alleles.json', to_json(data) );
print from_json( $allele_as_json );

# Delete allele id 1
request( 'DELETE', 'alleles/1' );