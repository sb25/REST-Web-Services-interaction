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
 
#   
#   Examples
#

# Set connection to the server
connection = Connection(base_url, username, password)

# Get allele list - first page
response = connection.request( 'GET', 'alleles.json?page=1' )
print json.loads( response )

# Get allele id 1 - no need to keep track of the ids a search method is 
# provided in the extended example.
response = connection.request( 'GET', 'alleles/1.json' )
print json.loads( response )

# Create an allele
data = 
{ 'allele': 
  {
    'pipeline_id'               : 1,
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
    'targeting_vector'          : "PGDGR00041_A"
  }
}

allele_as_json = connection.request( 'POST', 'alleles.json', json.dumps(data) )
print json.loads( allele_as_json )

# Delete allele id 1
connection.request( 'DELETE', 'alleles/1' )