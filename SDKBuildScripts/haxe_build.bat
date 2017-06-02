pushd ..
if [%1] == [] (
rem === BUILDING HaxeSDK ===
node generate.js haxe=..\sdks\HaxeSDK -apiSpecPath
) else (
rem === BUILDING HaxeSDK with params %* ===
node generate.js haxe=..\sdks\HaxeSDK %*
)
popd
