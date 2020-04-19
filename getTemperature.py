import pybase64
import requests
# ******************************************************************************************************************************************
# Example script to show how to pull a temperture value from a Kinvey cloud database
# ******************************************************************************************************************************************

print('Example that pulls a record from a Kinvey database')

# Coded string that contains Authorization parameters (right now AppKey and MasterSecret)
mytoken = pybase64.b64encode(b'kid_HkJ6ekcuL:a9a5413bae454bf48cef1ff43c025691').decode("ascii")
 
# Constructing rest API header
rest_header = {"Authorization":"Basic "+mytoken,
               "X-Kinvey-API-Version": "3",
               "Content-Type": "application/json"}
 
# Send a single REST API request to pull out one record
req = requests.get('https://baas.kinvey.com/appdata/kid_HkJ6ekcuL/Temperatures/', params='query={"UTC":1587325204}', headers=rest_header)
 
# result should be a JSON type
myJson = req.json()
 
# Pull Temperature from JSON  
Temperature = myJson[0]['Temperature']
  
print('Temperature is {} degrees'.format(Temperature))
 
