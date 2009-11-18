#!/usr/bin/env ruby -wKU

#
# Author::    Darren Oakley  (mailto:do2@sanger.ac.uk)
#
# This is an example script demonstrating how you can 
# interact with the I-DCC Targeting Repository via its 
# web services interface.
#
# In this Ruby example we use the rest_client gem to 
# handle the HTTP requests, and use JSON as our data 
# encapsulation method.
#
# If you plan to use Ruby to upload your data, you can 
# simply copy this script and just modify the function 
# 'get_alleles_to_load' to read in real data from your 
# systems.
#

require "rubygems"
require "rest_client"
require "json"
require "uri"

#
# Define our connection parameters
#

@@repository = RestClient::Resource.new(
  "http://localhost:3000", 
  :user => "user", 
  :password => "password"
)

#
# Methods
#

# Generic helper method for handling the web calls to the 
# repository.  Gives us a single place to handle service errors.
def request( options={} )
  response = nil
  url = URI.escape(options[:url])
  begin
    case options[:method]
    when "post"
      response = @@repository[ url ].post( options[:payload], :content_type => "application/json" )
    when "put"
      response = @@repository[ url ].put( options[:payload], :content_type => "application/json" )
    when "delete"
      response = @@repository[ url ].delete
    else
      response = @@repository[ url ].get
    end
  rescue RestClient::Exception => e
    raise "Error comminicating with repository #{e.message}"
  end
  return response
end

# In your scripts, this would be where you access your 
# database(s) and build up structures of your alleles and 
# products.
def get_alleles_to_load
  [
    {
      :pipeline_id               => @pipelines["KOMP-CSD"]["id"],
      :ikmc_project_id           => 35507,
      :allele_symbol_superscript => "tm1a(EUCOMM)Wtsi",
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
      :loxp_start                => 1000,
      :loxp_end                  => 1500,
      :cassette                  => "L1L2_gt2",
      :backbone                  => "L3L4_pZero_kan",
      :intermediate_vector       => "PCS00041_A",
      :targeting_vector          => "PGS00041_A",
      :products                  => [
        { :escell_clone => "EPD00064_1_A01" },
        { :escell_clone => "EPD00064_1_A03" },
        { :escell_clone => "EPD00064_1_A04" },
        { :escell_clone => "EPD00064_1_A05" }
      ]
    },
    {
      :pipeline_id               => @pipelines["EUCOMM"]["id"],
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
      :targeting_vector          => "PGS00041_A",
      :products                  => [
        { :escell_clone => "EPD00064_1_A02" }
      ]
    }
  ]
end

# Helper function to interact with the web services and find 
# an allele.
def find_allele(a)
  allele_search_url = "alleles.json?" + 
    "allele_symbol_superscript=#{a[:allele_symbol_superscript]}&" +
    "ikmc_project_id=#{a[:ikmc_project_id]}&" +
    "mgi_accession_id=#{a[:mgi_accession_id]}"
  
  allele_data = request( :url => allele_search_url )
  
  # Check that we have a unique allele - the repository does 
  # handle this for us, but you can't be too cautious!
  if JSON.parse(allele_data).size > 1
    raise "Error: found more than one allele for #{a[:mgi_accession_id]} | #{a[:allele_symbol_superscript]}!"
  elsif JSON.parse(allele_data).size == 1
    return JSON.parse(allele_data)[0]["allele"]
  else
    return nil # no allele found
  end
end

# Helper function to interact with the web services and create
# an allele.
def create_allele(a)
  allele_data = request(
    :url     => "alleles.json",
    :method  => "post",
    :payload => { :allele => a }.to_json
  )
  allele = JSON.parse(allele_data)["allele"]
  return allele
end

# Helper function to interact with the web services and find 
# a product.
def find_product(p)
  product_search_url = "products.json?escell_clone=#{p[:escell_clone]}"
  product_data = request( :url => product_search_url )
  
  # Check that we have a unique product - the repository does 
  # handle this for us, but you can't be too cautious!
  if JSON.parse(product_data).size > 1
    raise "Error: found more than one product entry for #{p[:escell_clone]}!"
  elsif JSON.parse(product_data).size == 1
    return JSON.parse(product_data)[0]["product"]
  else
    return nil
  end
end

# Helper function to interact with the web services and create 
# a product.
def create_product( a, p )
  product_json = { 
    :product => { 
      :escell_clone => p[:escell_clone], 
      :allele_id => a["id"] 
    } 
  }.to_json
  
  product_data = request(
    :url     => "products.json",
    :method  => "post",
    :payload => product_json
  )
  
  product = JSON.parse(product_data)["product"]
  return product
end

#
# Main body of script
#

# First communicate with the repository and get a list 
# of all of the pipelines represented and thier details.
#
# (We're storing the pipeline details in a hash, keyed 
# by the pipeline name for use in the allele building).
@pipelines = {}
pipeline_data = request( :url => "pipelines.json" )
JSON.parse( pipeline_data ).each do |p|
  @pipelines[ p["pipeline"]["name"] ] = p["pipeline"]
end

# Now we define the alleles and products that we want 
# to load into the repository.
#
# (In your code you will need to retrieve data from 
# your production systems here).
#
# NOTE that we also define the pipeline_id here when 
# constructing our object.
alleles = get_alleles_to_load()

#
# Now we shall loop through each of our alleles and 
# create entries in the targeting repository for both 
# the alleles and thier products.
#

alleles.each do |a|
  
  # First we must remove the products from the allele 
  # data structure - these must be processed in a seperate 
  # transaction.  Leaving them in the data structure 
  # will cause errors!
  allele_products = a[:products].clone
  a.delete(:products)
  
  # See if our Allele is already in the database
  allele = find_allele(a)
  
  unless allele
    # Looks like we have to create our allele entry
    allele = create_allele(a)
  end
  
  # Now work on our allele_products
  allele_products.each do |p|
    # See if our product is already in the database
    product = find_product(p)
    
    unless product
      # If not, create it
      product = create_product( allele, p )
    end
  end
  
end