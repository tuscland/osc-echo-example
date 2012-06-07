osc-echo-example
================

Basic OSC echo responder running on TCP.
Registers a Bonjour _osc._tcp service.

You will need Xcode 3.2.6+ to compile this example and the VVOSC framework (binary included in the repo, used for serialization / deserialization).  Put the two VV frameworks in /Library/Frameworks to compile and run the example.

This example has been highly influenced / derived by the CocoaHTTPServer Apple example.
