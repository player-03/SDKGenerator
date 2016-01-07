PlayFab SDK Generator README
========
1. Overview:
----
This is a node.js based program that takes a json description of the PlayFab API and uses it to generate out all the different SDKs that must be kept up to date. This project also contains the sources for all PlayFab SDKs on all platforms. If you want to make a change in an SDK, this is where the change has to go.

This fork adds Haxe support. Note: PlayFab has not checked the Haxe generator.


2. Prerequisites:
----
1. You must have Node.js installed: http://nodejs.org/
2. You must have the PlayFab API spec json files: https://github.com/PlayFab/api_specs
3. SdkManualNotes.json (in the api_specs project) must contain an entry for Haxe. If not, copy the ActionScript entry.


3. Usage Instructions:
----
To invoke the generator, open a command line at the root of the project and type:
```
node generate.js <apiSpecLocation> [<targetName>=<targetOutputLocation>] ...
```

&lt;apiSpecLocation&gt; is the directory containing the api spec json files obtained from the PlayFab api_specs repo.

Next you supply a list of targets to generate, and the directory to generate them to. Each target takes the form:

&lt;targetName&gt;=&lt;targetOutputLocation&gt;

Where &lt;targetName&gt; is one of the supported SDK targets, and &lt;targetOutputLocation&gt; is a path to a directory to generate the SDK in. Note: Make sure there are no spaces between he arguments and the equals sign. Additional

Example:
```
node generate.js ../api_specs haxe=../sdks/haxeSDK
```

4. Troubleshooting:
----
For a complete list of available APIs, check out the [online documentation](http://api.playfab.com/Documentation/).

#### Contact Us
We love to hear from our developer community! 
Do you have ideas on how we can make our products and services better? 

Our Developer Success Team can assist with answering any questions as well as process any feedback you have about PlayFab services.

[Forums, Support and Knowledge Base](https://community.playfab.com/hc/en-us)


5. Copyright and Licensing Information:
----
  Apache License -- 
  Version 2.0, January 2004
  http://www.apache.org/licenses/

  Full details available within the LICENSE file.
