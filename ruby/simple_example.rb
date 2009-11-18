require "rubygems"
require "rest_client"
require "json"

repository = RestClient::Resource.new(
  "http://localhost:3000", 
  :user => "user", 
  :password => "password"
)

# Get allele lists - first page
response = repository['alleles.json?page=1'].get
puts json.parse( response )

# Get allele id 1 - no need to keep track of the ids
# a search method is provided, see extended example.
response = repository['alleles/1.json'].get
puts json.parse( response )

# Create an allele
data =
{ :allele => 
  {
    :pipeline_id               => 1,
    :ikmc_project_id           => 35507,
    :allele_symbol_superscript => "tm1e(EUCOMM)Wtsi",
    :mgi_accession_id          => "MGI:44556",
    :assembly                  => "NCBIM37",
    :chromosome                => "11",
    :strand                    => "+",
    :design_type               => "KO",
    :design_subtype            => "Frameshift",
    :homology_arm_start        => 10,
    :homology_arm_end          => 10000,
    :cassette_start            => 50,
    :cassette_end              => 500,
    :cassette                  => "L1L2_gt2",
    :backbone                  => "L3L4_pZero_kan",
    :intermediate_vector       => "PCS00041_A",
    :targeting_vector          => "PGDGR00041_A"
  }
}
response = repository['alleles.json'].post data, :content_type => "application/json"
puts json.parse( response )

# Delete allele id 1
repository['alleles/1/'].delete