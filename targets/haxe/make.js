var path = require("path");

exports.putInRoot = true;

exports.makeCombinedAPI = function (apis, sourceDir, apiOutputDir) {
	console.log("Generating Haxe combined SDK to " + apiOutputDir);
	
	copyTree(path.resolve(sourceDir, "source"), apiOutputDir);
	
	for (var i in apis) {
		makeDatatypes(apis[i], sourceDir, apiOutputDir);
		makeAPI(apis[i], sourceDir, apiOutputDir);
	}
	
	generateSimpleFiles(apis, sourceDir, apiOutputDir);
}

function makeDatatypes(api, sourceDir, apiOutputDir) {
	var templateDir = path.resolve(sourceDir, "templates");
	
	var modelTemplate = ejs.compile(readFile(path.resolve(templateDir, "Model.hx.ejs")));
	var enumTemplate = ejs.compile(readFile(path.resolve(templateDir, "Enum.hx.ejs")));
	
	for (var d in api.datatypes) {
		var datatype = api.datatypes[d];
		
		var modelLocals = {};
		modelLocals.api = api;
		modelLocals.datatype = datatype;
		modelLocals.getPropertyDef = getModelPropertyDef;
        modelLocals.getPropertyInit = getModelPropertyInit;
		var generatedModel = null;
		
		if (datatype.isenum) {
			generatedModel = enumTemplate(modelLocals);
		}
		else {
			modelLocals.needsPlayFabUtil = needsPlayFabUtil(datatype);
			generatedModel = modelTemplate(modelLocals);
		}
		
		writeFile(path.resolve(apiOutputDir, "com/playfab/" + api.name.toLowerCase() + "models/" + datatype.name + ".hx"), generatedModel);
	}
}

function needsPlayFabUtil(datatype) {
	for (var i in datatype.properties) {
		var property = datatype.properties[i];
		if (property.actualtype === "DateTime")
			return true;
	}
	
	return false;
}

function makeAPI(api, sourceDir, apiOutputDir) {
	console.log("Generating Haxe " + api.name + " library to " + apiOutputDir);
	
	var templateDir = path.resolve(sourceDir, "templates");
	
	var apiTemplate = ejs.compile(readFile(path.resolve(templateDir, "API.hx.ejs")));
	var apiLocals = {};
	apiLocals.api = api;
	apiLocals.getAuthParams = getAuthParams;
	apiLocals.getRequestActions = getRequestActions;
	apiLocals.getResultActions = getResultActions;
	apiLocals.getUrlAccessor = getUrlAccessor;
	apiLocals.hasClientOptions = api.name === "Client";
	var generatedApi = apiTemplate(apiLocals);
	writeFile(path.resolve(apiOutputDir, "com/playfab/PlayFab" + api.name + "API.hx"), generatedApi);
}

function generateSimpleFiles(apis, sourceDir, apiOutputDir) {
	var errorsTemplate = ejs.compile(readFile(path.resolve(sourceDir, "templates/Errors.hx.ejs")));
	var errorLocals = {};
	errorLocals.errorList = apis[0].errorList;
	errorLocals.errors = apis[0].errors;
	var generatedErrors = errorsTemplate(errorLocals);
	writeFile(path.resolve(apiOutputDir, "com/playfab/PlayFabError.hx"), generatedErrors);
	
	var versionTemplate = ejs.compile(readFile(path.resolve(sourceDir, "templates/PlayFabVersion.hx.ejs")));
	var versionLocals = {};
	versionLocals.sdkRevision = exports.sdkVersion;
	var generatedVersion = versionTemplate(versionLocals);
	writeFile(path.resolve(apiOutputDir, "com/playfab/PlayFabVersion.hx"), generatedVersion);

	var settingsTemplate = ejs.compile(readFile(path.resolve(sourceDir, "templates/PlayFabSettings.hx.ejs")));
	var settingsLocals = {};
	settingsLocals.hasServerOptions = false;
	settingsLocals.hasClientOptions = false;
	for (var i in apis) {
		if (apis[i].name === "Client")
			settingsLocals.hasClientOptions = true;
		else
			settingsLocals.hasServerOptions = true;
	}
	var generatedsettings = settingsTemplate(settingsLocals);
	writeFile(path.resolve(apiOutputDir, "com/playfab/PlayFabSettings.hx"), generatedsettings);
}

function getModelPropertyDef(property, datatype) {
	var type = getPropertyHXType(property, datatype);
	
	if (property.collection) {
		if (property.collection === "array") {
			type = "Array<" + type + ">";
		}
		else if (property.collection === "map") {
			type = "Map<String, " + type + ">";
		}
		else {
			throw "Unknown collection type: " + property.collection + " for " + property.name + " in " + datatype.name;
		}
	}
	
	var comment = "";
	if (property.description) {
		comment = "/**";
		var lineLength = 80;
		var line = "";
		for (var i = 0; i < property.description.length; i += line.length + 1) {
			line = property.description.substr(i, lineLength);
			if (line.length == lineLength)
				line = line.substr(0, line.lastIndexOf(" "));
			comment += "\n\t * " + line;
		}
		comment += "\n\t */\n\t";
	}
	
	return comment + "public var " + property.name + ":" + type + ";";
}

function getModelPropertyInit(property, datatype) {
    if (property.isclass) {
        if (property.collection) {
            if (property.collection === "array")
                return "if(data." + property.name + " != null) " + property.name + " = [for(object in data." + property.name + ") new " + property.actualtype + "(object)];";
            else if (property.collection === "map")
                return "if(data." + property.name + " != null) " + property.name + " = [for(field in Reflect.fields(data." + property.name + ")) field => new " + property.actualtype + "(Reflect.field(data." + property.name + ", field))];";
            else
                throw "Unknown collection type: " + property.collection + " for " + property.name + " in " + datatype.name;
        }
        else {
            return property.name + " = new " + property.actualtype + "(data." + property.name + ");";
        }
    }
    else if (property.collection) {
        if (property.collection === "array") {
            return property.name + " = data." + property.name + ";";
        }
        else if (property.collection === "map") {
            return "if(data." + property.name + " != null) " + property.name + " = [for(field in Reflect.fields(data." + property.name + ")) field => Reflect.field(data." + property.name + ", field)];";
        }
        else {
            throw "Unknown collection type: " + property.collection + " for " + property.name + " in " + datatype.name;
        }
    }
    else if (property.actualtype === "DateTime") {
        return property.name + " = PlayFabUtil.parseDate(data." + property.name + ");";
    }
    else {
        return property.name + " = data." + property.name + ";";
    }
}

function getPropertyHXType(property, datatype) {
	if (property.actualtype === "String")
		return "String";
	else if (property.actualtype === "Boolean")
		return "Bool";
	else if (property.actualtype === "int16")
		return "Int";
	else if (property.actualtype === "uint16")
		return "UInt";
	else if (property.actualtype === "int32")
		return "Int";
	else if (property.actualtype === "uint32")
		return "UInt";
	else if (property.actualtype === "int64")
		return "Float";
	else if (property.actualtype === "uint64")
		return "Float";
	else if (property.actualtype === "float")
		return "Float";
	else if (property.actualtype === "double")
		return "Float";
	else if (property.actualtype === "decimal")
		return "Float";
	else if (property.actualtype === "DateTime")
		return "Date";
	else if (property.isclass)
		return property.actualtype;
	else if (property.isenum)
		return "String";
	else if (property.actualtype === "object")
		return "Dynamic";
	throw "Unknown property type: " + property.actualtype + " for " + property.name + " in " + datatype.name;
}

function getAuthParams(apiCall) {
	if (apiCall.auth === "SecretKey")
		return "\"X-SecretKey\", PlayFabSettings.DeveloperSecretKey";
	else if (apiCall.auth === "SessionTicket")
		return "\"X-Authorization\", authKey";
	return "null, null";
}

function getRequestActions(apiCall, api) {
	if (api.name === "Client" && (apiCall.result === "LoginResult" || apiCall.request === "RegisterPlayFabUserRequest"))
		return "			request.TitleId = PlayFabSettings.TitleId != null ? PlayFabSettings.TitleId : request.TitleId;\n" 
			+ "			if(request.TitleId == null) throw new Error (\"Must be have PlayFabSettings.TitleId set to call this method\");";
	if (api.name === "Client" && apiCall.auth === "SessionTicket")
		return "			if (authKey == null) throw new Error(\"Must be logged in to call this method\");";
	if (apiCall.auth === "SecretKey")
		return "			if (PlayFabSettings.DeveloperSecretKey == null) throw new Error (\"Must have PlayFabSettings.DeveloperSecretKey set to call this method\");";
	return "";
}

function getResultActions(apiCall, api) {
	if (api.name === "Client" && (apiCall.result === "LoginResult" || apiCall.result === "RegisterPlayFabUserResult"))
		return "				authKey = resultData.SessionTicket != null ? resultData.SessionTicket : authKey;\n" 
			+ "				MultiStepClientLogin(resultData.SettingsForUser.NeedsAttribution);\n";
	else if (api.name === "Client" && apiCall.result === "AttributeInstallResult")
		return "				// Modify AdvertisingIdType:  Prevents us from sending the id multiple times, and allows automated tests to determine id was sent successfully\n"
			+ "				PlayFabSettings.AdvertisingIdType += \"_Successful\";\n";
	else if (api.name === "Client" && apiCall.result === "GetCloudScriptUrlResult")
		return "				PlayFabSettings.LogicServerURL = resultData.Url;\n";
	return "";
}

function getUrlAccessor(apiCall) {
	if (apiCall.serverType === "logic")
		return "PlayFabSettings.GetLogicURL()";
	return "PlayFabSettings.GetURL()";
}
