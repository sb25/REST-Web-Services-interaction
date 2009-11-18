#!/usr/bin/env python

#
# Author::    Sebastien Briois (mailto:sb25@sanger.ac.uk)
#
# This is an example script demonstrating how you can 
# interact with the I-DCC Targeting Repository via its 
# web services interface.
#
# In this Python example we use the rest_client gem to 
# handle the HTTP requests, and use JSON as our data 
# encapsulation method.
#
# If you plan to use Ruby to upload your data, you can 
# simply copy this script and just modify the function 
# 'get_alleles_to_load' to read in real data from your 
# systems.
#

import httplib2
import urllib
import urlparse

try:
  import json # Python 2.6
except ImportError:
  import simplejson as json # Python 2.4+

# Settings
base_url = "http://localhost:3000"
username = 'username'
password = 'password'

# Generic helper class for handling the web requests to the 
# repository.
class Connection(object):
  def __init__(self, base_url, username = None, password = None):
    self.base_url = base_url
    self.username = username
    self.password = password

  def request(self, method, url, data = None):
    # Set authentication parameters
    http = httplib2.Http()
    if self.username and self.password:
      http.add_credentials(self.username, self.password)

    url = self.base_url + "/" + url
    headers = { 'Content-Type' : 'application/json' }

    # Send request and get response
    headers, response = http.request(url, method.upper(), data, headers)
    return response
  

# In your scripts, this would be where you access your 
# database(s) and build up structures of your alleles and 
# products.
def get_alleles_to_load(pipelines):
  return [
    {
      'pipeline_id'               : pipelines["KOMP-CSD"],
      'ikmc_project_id'           : 35507,
      'allele_symbol_superscript' : "tm1a(EUCOMM)Wtsi",
      'mgi_accession_id'          : "MGI:44556",
      'assembly'                  : "NCBIM37",
      'chromosome'                : "11",
      'strand'                    : "+",
      'design_type'               : "KO",
      'design_subtype'            : "Frameshift",
      'homology_arm_start'        : 10,
      'homology_arm_end'          : 10000,
      'cassette_start'            : 50,
      'cassette_end'              : 500,
      'loxp_start'                : 1000,
      'loxp_end'                  : 1500,
      'cassette'                  : "L1L2_gt2",
      'backbone'                  : "L3L4_pZero_kan",
      'intermediate_vector'       : "PCS00041_A",
      'targeting_vector'          : "PGDGR00041_A",
      'products'                  : [
        { 'escell_clone' : "EPD00064_1_A01" },
        { 'escell_clone' : "EPD00064_1_A03" },
        { 'escell_clone' : "EPD00064_1_A04" },
        { 'escell_clone' : "EPD00064_1_A05" }
      ]
    },
    {
      'pipeline_id'               : pipelines["EUCOMM"],
      'ikmc_project_id'           : 35507,
      'allele_symbol_superscript' : "tm1e(EUCOMM)Wtsi",
      'mgi_accession_id'          : "MGI:44556",
      'assembly'                  : "NCBIM37",
      'chromosome'                : "11",
      'strand'                    : "+",
      'design_type'               : "KO",
      'design_subtype'            : "Frameshift",
      'homology_arm_start'        : 10,
      'homology_arm_end'          : 10000,
      'cassette_start'            : 50,
      'cassette_end'              : 500,
      'cassette'                  : "L1L2_gt2",
      'backbone'                  : "L3L4_pZero_kan",
      'intermediate_vector'       : "PCS00041_A",
      'targeting_vector'          : "PGS00041_A",
      'products'                  : [
        { 'escell_clone' : "EPD00064_1_A02" }
      ]
    }
  ]


# Helper function to interact with the web services and find 
# an allele.
def find_allele(connection, allele):
  params = "allele_symbol_superscript=" + allele['allele_symbol_superscript']
  params += "&ikmc_project_id=" + allele['ikmc_project_id']
  
  response = connection.request( 'GET', 'alleles.json?' + params )
  
  # Check that we have a unique allele - the repository does 
  # handle this for us, but you can't be too cautious!
  alleles = json.loads(response)
  if len(alleles) > 1:
    raise "Error: found more than one allele for %s | %s!"%(
      allele['ikmc_project_id'], 
      allele['allele_symbol_superscript']
    )
  elif len(alleles) == 1:
    return alleles[0]
  else:
    return None # no allele found


# Helper function to interact with the web services and create
# an allele.
def create_allele(connection, allele_data):
  data = { 'allele': allele_data }
  response = connection.request( 'POST', 'alleles.json', json.dumps(data) )
  return json.loads( response )

# Helper function to interact with the web services and find 
# a product.
def find_product(connection, product):
  params = 'escell_clone=' + product['escell_clone']
  response = connection.request( 'GET', 'products.json?' + params )
  
  # Check that we have a unique product - the repository does
  # handle this for us, but you can't be too cautious!
  products = json.loads(response)
  if len(products) > 1:
    raise "Found more than one product entry for " + product['escell_clone']
  elif len(products) == 1:
    return products[0]
  else:
    return None

# Helper function to interact with the web services and create 
# a product.
def create_product(connection, allele, product):
  data = json.dumps({ 
    'product' : { 
      'escell_clone' : product['escell_clone'], 
      'allele_id' : allele['id'] 
    }
  })
  
  response = connection.request( 'POST', 'products.json', data )
  return json.loads( response )


#
# Main body of script
#

# Set connection to the server
connection = Connection(base_url, username, password)

# First communicate with the repository and get a list 
# of all of the pipelines represented and thier details.
#
# (We're storing the pipeline details in a hash, keyed 
# by the pipeline name for use in the allele building).
response = connection.request( 'GET', 'pipelines.json' )
pipelines = dict([ (p['name'], p['id']) for p in json.loads(response) ])


# Now we define the alleles and products that we want 
# to load into the repository.
#
# (In your code you will need to retrieve data from 
# your production systems here).
#
# NOTE that we also define the pipeline_id here when 
# constructing our object.
alleles = get_alleles_to_load(pipelines)

#
# Now we shall loop through each of our alleles and 
# create entries in the targeting repository for both 
# the alleles and thier products.
#

for allele_data in alleles:
  
  # First we must remove the products from the allele 
  # data structure - these must be processed in a seperate 
  # transaction.  Leaving them in the data structure 
  # will cause errors!
  allele_products = allele_data['products']
  del allele_data['products']
  
  # See if our Allele is already in the database
  allele = find_allele( connection, allele_data )
  
  if not allele:
    # Looks like we have to create our allele entry
    allele = create_allele( connection, allele_data )
  
  # Now work on our allele_products
  for product_data in allele_products:
    # See if our product is already in the database
    product = find_product(connection, product_data)
    
    if not product:
      # If not, create it
      product = create_product(connection, allele, product_data)
