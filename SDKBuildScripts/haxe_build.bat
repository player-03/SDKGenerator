rem === Cleaning existing files from HaxeSDK ===
pushd ..\..\sdks\HaxeSDK\PfApiTest\com\playfab
pushd adminmodels
del *.hx >nul 2>&1
popd
pushd clientmodels
del *.hx >nul 2>&1
popd
pushd matchmakermodels
del *.hx >nul 2>&1
popd
pushd servermodels
del *.hx >nul 2>&1
popd
popd

pushd ..
rem === BUILDING HaxeSDK ===
node generate.js ..\API_Specs haxe=..\sdks\HaxeSDK\PfApiTest
popd
