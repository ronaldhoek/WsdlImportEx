# WsdlImportEx
Upgraded version of the default Delphi WSDL importer

The biggest problem using the importer (and using the Delphi SOAP implementation) is the fact you cannot import two 'different' webservices and have two class definitons (in two separate files) for the exact same class.

In many cases you won't have this problem, when connection some a few SOAP services, but when you need to connect to many (20-50) webservices and also need to support multiple versions of a specific webservice (which in many cases use common XSD's to specify shared types) you run into the problem that request won't work as expected (or don;t work at all).
This project tries to overcome this issue by splitting the import into several files: one file per namespace!

WORK IN NPROGRESS!!!
