package;

import flash.net.*;
import flash.errors.*;
import flash.events.*;
import flash.utils.Timer;

import com.playfab.clientmodels.*;
import com.playfab.servermodels.*;
import com.playfab.PlayFabClientAPI;
import com.playfab.PlayFabServerAPI;
import com.playfab.PlayFabSettings;
import com.playfab.PlayFabHTTP;
import com.playfab.PlayFabError;

import asyncUnitTest.ASyncUnitTestSuite;
import asyncUnitTest.ASyncUnitTestEvent;
import asyncUnitTest.ASyncAssert;
import asyncUnitTest.ASyncUnitTestReporter;

import haxe.Json;

class PlayFabApiTests extends ASyncUnitTestSuite
{
    private static var TITLE_DATA_FILENAME:String;
    
    private static inline var TEST_STAT_BASE:Int = 10;
    private static inline var TEST_STAT_NAME:String = "str";
    private static inline var CHAR_TEST_TYPE:String = "Test";
    private static inline var TEST_DATA_KEY:String = "testCounter";
    
    // Functional
    private static var EXEC_ONCE:Bool = true;
    private static var TITLE_INFO_SET:Bool = false;
    private static var TITLE_CAN_UPDATE_SETTINGS:Bool = false;
    
    // Fixed values provided from testInputs
    private static var USER_NAME:String;
    private static var USER_EMAIL:String;
    private static var USER_PASSWORD:String;
    private static var CHAR_NAME:String;
    
    // Information fetched by appropriate API calls
    private static var playFabId:String;
    private static var characterId:String;
    
    // Variables for specific tests
    private var testIntExpected:Int;
    private var testIntActual:Int;
    
    public function new(titleDataFileName:String, reporter:ASyncUnitTestReporter)
    {
        super(reporter);
        TITLE_DATA_FILENAME = titleDataFileName;
        
        AddTest("InvalidLogin", InvalidLogin);
        AddTest("LoginOrRegister", LoginOrRegister);
        AddTest("LoginWithAdvertisingId", LoginWithAdvertisingId);
        AddTest("UserDataApi", UserDataApi);
        AddTest("UserStatisticsApi", UserStatisticsApi);
        AddTest("UserCharacter", UserCharacter);
        AddTest("LeaderBoard", LeaderBoard);
        AddTest("AccountInfo", AccountInfo);
        AddTest("CloudScript", CloudScript);
        
        KickOffTests();
    }
    
    override private function SuiteSetUp() : Void
    {
        var myTextLoader:URLLoader = new URLLoader();
        myTextLoader.addEventListener(Event.COMPLETE, Wrap1(OnTitleDataLoaded, "TitleData"));
        myTextLoader.load(new URLRequest(TITLE_DATA_FILENAME));
    }
    
    private function OnTitleDataLoaded(event:Event) : Void
    {
        SetTitleInfo(event.target.data);
        SuiteSetUpCompleteHandler();
    }
    
    /// <summary>
    /// PlayFab Title cannot be created from SDK tests, so you must provide your titleId to run unit tests.
    /// (Also, we don't want lots of excess unused titles)
    /// </summary>
    private static function SetTitleInfo(titleDataString):Bool
    {
        var testTitleData:Dynamic = Json.parse(titleDataString);
        
        PlayFabSettings.TitleId = testTitleData.titleId;
        PlayFabSettings.DeveloperSecretKey = testTitleData.developerSecretKey;
        TITLE_CAN_UPDATE_SETTINGS = testTitleData.titleCanUpdateSettings.toLowerCase() == "true";
        USER_NAME = testTitleData.userName;
        USER_EMAIL = testTitleData.userEmail;
        USER_PASSWORD = testTitleData.userPassword;
        CHAR_NAME = testTitleData.characterName;
        
        TITLE_INFO_SET = PlayFabSettings.TitleId != null
            || PlayFabSettings.TitleId != null
            || PlayFabSettings.DeveloperSecretKey != null
            || TITLE_CAN_UPDATE_SETTINGS
            || USER_NAME != null
            || USER_EMAIL != null
            || USER_PASSWORD != null
            || CHAR_NAME != null;
        return TITLE_INFO_SET;
    }
    
    /// <summary>
    /// CLIENT API
    /// Try to deliberately log in with an inappropriate password,
    ///   and verify that the error displays as expected.
    /// </summary>
    private function InvalidLogin() : Void
    {
        // If the setup failed to log in a user, we need to create one.
        var request:com.playfab.clientmodels.LoginWithEmailAddressRequest = {
            TitleId : PlayFabSettings.TitleId,
            Email : USER_EMAIL,
            Password : USER_PASSWORD + "INVALID"
        };
        PlayFabClientAPI.LoginWithEmailAddress(request, Wrap1(InvalidLogin_Success, "Success"), Wrap1(InvalidLogin_Failure, "Fail"));
    }
    private function InvalidLogin_Success(result:com.playfab.clientmodels.LoginResult) : Void
    {
        reporter.Debug("InvalidLogin_Success");
        ASyncAssert.Fail("Login unexpectedly succeeded.");
    }
    private function InvalidLogin_Failure(error:com.playfab.PlayFabError) : Void
    {
        ASyncAssert.AssertNotNull(error.errorMessage);
        if(error.errorMessage.toLowerCase().indexOf("password") >= 0)
            FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_PASSED, ""));
        else
            ASyncAssert.Fail("Unexpected error result: " + error.errorMessage);
    }
    
    private function Shared_ApiCallFailure(error:com.playfab.PlayFabError) : Void
    {
        ASyncAssert.Fail(error.errorMessage);
    }
    
    /// <summary>
    /// CLIENT API
    /// Test a sequence of calls that modifies saved data,
    ///   and verifies that the next sequential API call contains updated data.
    /// Verify that the data is correctly modified on the next call.
    /// Parameter types tested: string, Dictionary<string, string>, DateTime
    /// </summary>
    private function LoginOrRegister() : Void
    {
        var loginRequest:com.playfab.clientmodels.LoginWithEmailAddressRequest = {
            TitleId : PlayFabSettings.TitleId,
            Email : USER_EMAIL,
            Password : USER_PASSWORD
        };
        // Try to login, but if we fail, just fall-back and try to create character
        PlayFabClientAPI.LoginWithEmailAddress(loginRequest, Wrap1(LoginOrRegister_LoginSuccess, "Login1"), Wrap1(LoginOrRegister_AcceptableFailure, "Fail1"));
    }
    private function LoginOrRegister_LoginSuccess(result:com.playfab.clientmodels.LoginResult) : Void
    {
        // Typical success
        playFabId = result.PlayFabId;
        FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_PASSED, ""));
    }
    private function LoginOrRegister_AcceptableFailure(error:com.playfab.PlayFabError) : Void
    {
        // Acceptable failure - register character and re-attempt
        var registerRequest:com.playfab.clientmodels.RegisterPlayFabUserRequest = {
            TitleId : PlayFabSettings.TitleId,
            Username : USER_NAME,
            Email : USER_EMAIL,
            Password : USER_PASSWORD
        };
        PlayFabClientAPI.RegisterPlayFabUser(registerRequest, Wrap1(LoginOrRegister_RegisterSuccess, "Register"), Wrap1(Shared_ApiCallFailure, "Fail2"));
    }
    private function LoginOrRegister_RegisterSuccess(result:com.playfab.clientmodels.RegisterPlayFabUserResult) : Void
    {
        var loginRequest:com.playfab.clientmodels.LoginWithEmailAddressRequest = {
            TitleId : PlayFabSettings.TitleId,
            Email : USER_EMAIL,
            Password : USER_PASSWORD
        };
        // Try again, but this time, error on failure
        PlayFabClientAPI.LoginWithEmailAddress(loginRequest, Wrap1(LoginOrRegister_LoginSuccess, "Login2"), Wrap1(Shared_ApiCallFailure, "Fail3"));
    }
    
    /// <summary>
    /// CLIENT API
    /// Test that the login call sequence sends the AdvertisingId when set
    /// </summary>
    private function LoginWithAdvertisingId() : Void
    {
        PlayFabSettings.AdvertisingIdType = PlayFabSettings.AD_TYPE_ANDROID_ID;
        PlayFabSettings.AdvertisingIdValue = "PlayFabTestId";
        
        var loginRequest:com.playfab.clientmodels.LoginWithEmailAddressRequest = {
            TitleId : PlayFabSettings.TitleId,
            Email : USER_EMAIL,
            Password : USER_PASSWORD
        };
        // Try to login, but if we fail, just fall-back and try to create character
        PlayFabClientAPI.LoginWithEmailAddress(loginRequest, Wrap1(LoginWithAdvertisingId_LoginSuccess, "LoginWithAdvertisingId"), Wrap1(Shared_ApiCallFailure, "LoginWithAdvertisingId"));
        var RecursiveWrap:Void -> Void = CheckAdvertIdSuccess.bind(-1);
        Wrap0(RecursiveWrap, "RecursiveWrap_First")(); // ODD SYNTAX HERE: Wrap0 returns a function, which we then need to call.  Normally the wrap-return is passed in as a callback, which gets called by the sdk, or a utility.
    }
    private function LoginWithAdvertisingId_LoginSuccess(result:com.playfab.clientmodels.LoginResult) : Void
    {
        // Typical success
        playFabId = result.PlayFabId;
    }
    private function CheckAdvertIdSuccess(count:Float) : Void
    {
        TickTestHandler();
        if (count > 20) // count is the number of attempts to test the successful send of the AdvertisingId.  It needs to be high enough to guarantee regular-case success, but low enough to fail within a reasonable time-limit
        {
            ASyncAssert.Fail("AdvertisingId not sent properly: " + PlayFabSettings.AdvertisingIdType);
        }
        else if (PlayFabSettings.AdvertisingIdType == PlayFabSettings.AD_TYPE_ANDROID_ID + "_Successful") // Base case, success!
        {
            FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_PASSED, ""));
        }
        else
        {
            var RecursiveWrap:Void -> Void = CheckAdvertIdSuccess.bind(count + 1);
            
            // timer takes a delay, which in this case re-tests the successful send of the AdvertisingId.  It needs to be high enough to guarantee regular-case success, but low enough to fail within a reasonable time-limit
            haxe.Timer.delay(Wrap0(RecursiveWrap, "RecursiveWrap_" + count), 50);
        }
    }
    
    /// <summary>
    /// CLIENT API
    /// Test a sequence of calls that modifies saved data,
    ///   and verifies that the next sequential API call contains updated data.
    /// Verify that the data is correctly modified on the next call.
    /// Parameter types tested: string, Dictionary<string, string>, DateTime
    /// </summary>
    private function UserDataApi() : Void
    {
        var getRequest:com.playfab.clientmodels.GetUserDataRequest = {};
        PlayFabClientAPI.GetUserData(getRequest, Wrap1(UserDataApi_GetSuccess1, "GetSuccess1"), Wrap1(Shared_ApiCallFailure, "Fail1"));
    }
    private function UserDataApi_GetSuccess1(result:com.playfab.clientmodels.GetUserDataResult) : Void
    {
        testIntExpected = Reflect.hasField(result.Data, TEST_DATA_KEY) ? Reflect.field(result.Data, TEST_DATA_KEY).Value : 1;
        testIntExpected = (testIntExpected + 1) % 100; // This test is about the expected value changing - but not testing more complicated issues like bounds
        
        var updateRequest:com.playfab.clientmodels.UpdateUserDataRequest = {
            Data : {}
        };
        Reflect.setField(updateRequest.Data, TEST_DATA_KEY, Std.string(testIntExpected));
        PlayFabClientAPI.UpdateUserData(updateRequest, Wrap1(UserDataApi_UpdateSuccess, "UpdateSuccess"), Wrap1(Shared_ApiCallFailure, "Fail2"));
    }
    private function UserDataApi_UpdateSuccess(result:com.playfab.clientmodels.UpdateUserDataResult) : Void
    {
        var getRequest:com.playfab.clientmodels.GetUserDataRequest = {};
        PlayFabClientAPI.GetUserData(getRequest, Wrap1(UserDataApi_GetSuccess2, "GetSuccess2"), Wrap1(Shared_ApiCallFailure, "Fail3"));
    }
    private function UserDataApi_GetSuccess2(result:com.playfab.clientmodels.GetUserDataResult) : Void
    {
        testIntActual = Reflect.field(result.Data, TEST_DATA_KEY).Value;
        ASyncAssert.AssertEquals(testIntExpected, testIntActual);
        
        var timeUpdated:Float = Date.fromString(Reflect.field(result.Data, TEST_DATA_KEY).LastUpdated).getTime();
        var now:Float = Date.now().getTime();
        var testMin:Float = now - (5*60*1000);
        var testMax:Float = now + (5*60*1000);
        ASyncAssert.AssertTrue(testMin <= timeUpdated && timeUpdated <= testMax);
        
        FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_PASSED, ""));
    }
    
    /// <summary>
    /// CLIENT API
    /// Test a sequence of calls that modifies saved data,
    ///   and verifies that the next sequential API call contains updated data.
    /// Verify that the data is saved correctly, and that specific types are tested
    /// Parameter types tested: Map<String, Int>
    /// </summary>
    private function UserStatisticsApi() : Void
    {
        var getRequest:com.playfab.clientmodels.GetUserStatisticsRequest = {};
        PlayFabClientAPI.GetUserStatistics(getRequest, Wrap1(UserStatisticsApi_GetSuccess1, "GetSuccess1"), Wrap1(Shared_ApiCallFailure, "Fail1"));
    }
    private function UserStatisticsApi_GetSuccess1(result:com.playfab.clientmodels.GetUserStatisticsResult) : Void
    {
        testIntExpected = Reflect.field(result.UserStatistics, TEST_STAT_NAME);
        testIntExpected = (testIntExpected + 1) % 100; // This test is about the expected value changing - but not testing more complicated issues like bounds
        
        var updateRequest:com.playfab.clientmodels.UpdateUserStatisticsRequest = {
            UserStatistics : {}
        };
        Reflect.setField(updateRequest.UserStatistics, TEST_STAT_NAME, testIntExpected);
        PlayFabClientAPI.UpdateUserStatistics(updateRequest, Wrap1(UserStatisticsApi_UpdateSuccess, "UpdateSuccess"), Wrap1(Shared_ApiCallFailure, "Fail2"));
    }
    private function UserStatisticsApi_UpdateSuccess(result:com.playfab.clientmodels.UpdateUserStatisticsResult) : Void
    {
        var getRequest:com.playfab.clientmodels.GetUserStatisticsRequest = {};
        PlayFabClientAPI.GetUserStatistics(getRequest, Wrap1(UserStatisticsApi_GetSuccess2, "GetSuccess2"), Wrap1(Shared_ApiCallFailure, "Fail3"));
    }
    private function UserStatisticsApi_GetSuccess2(result:com.playfab.clientmodels.GetUserStatisticsResult) : Void
    {
        testIntActual = Reflect.field(result.UserStatistics, TEST_STAT_NAME);
        
        ASyncAssert.AssertEquals(testIntExpected, testIntActual);
        FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_PASSED, ""));
    }
    
    /// <summary>
    /// SERVER API
    /// Get or create the given test character for the given user
    /// Parameter types tested: Contained-Classes, string
    /// </summary>
    private function UserCharacter() : Void
    {
        var getRequest:com.playfab.servermodels.ListUsersCharactersRequest = {
            PlayFabId : playFabId
        };
        PlayFabServerAPI.GetAllUsersCharacters(getRequest, Wrap1(UserCharacter_GetSuccess1, "GetSuccess1"), Wrap1(Shared_ApiCallFailure, "Fail1"));
    }
    private function UserCharacter_GetSuccess1(result:com.playfab.servermodels.ListUsersCharactersResult) : Void
    {
        for(eachCharacter in result.Characters)
            if (eachCharacter.CharacterName == CHAR_NAME)
                characterId = eachCharacter.CharacterId;
        
        if (characterId != null)
        {
            // Character is defined and found, success
            FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_PASSED, ""));
        }
        else
        {
            // Character not found, create it
            var grantRequest:com.playfab.servermodels.GrantCharacterToUserRequest = {
                PlayFabId : playFabId,
                CharacterName : CHAR_NAME,
                CharacterType : CHAR_TEST_TYPE
            };
            PlayFabServerAPI.GrantCharacterToUser(grantRequest, Wrap1(UserCharacter_RegisterSuccess, "RegisterSuccess"), Wrap1(Shared_ApiCallFailure, "Fail2"));
        }
    }
    private function UserCharacter_RegisterSuccess(result:com.playfab.servermodels.GrantCharacterToUserResult) : Void
    {
        var getRequest:com.playfab.servermodels.ListUsersCharactersRequest = {
            PlayFabId : playFabId
        };
        PlayFabServerAPI.GetAllUsersCharacters(getRequest, Wrap1(UserCharacter_GetSuccess2, "GetSuccess2"), Wrap1(Shared_ApiCallFailure, "Fail3"));
    }
    private function UserCharacter_GetSuccess2(result:com.playfab.servermodels.ListUsersCharactersResult) : Void
    {
        for(eachCharacter in result.Characters)
            if (eachCharacter.CharacterName == CHAR_NAME)
                characterId = eachCharacter.CharacterId;
        
        ASyncAssert.AssertNotNull(characterId, "Character not found, " + result.Characters.length + ", " + playFabId);
        // Character is defined and found, success
        FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_PASSED, ""));
    }
    
    /// <summary>
    /// CLIENT AND SERVER API
    /// Test that leaderboard results can be requested
    /// Parameter types tested: List of contained-classes
    /// </summary>
    private function LeaderBoard() : Void
    {
        var clientRequest:com.playfab.clientmodels.GetLeaderboardAroundCurrentUserRequest = {
            MaxResultsCount : 3,
            StatisticName : TEST_STAT_NAME
        };
        PlayFabClientAPI.GetLeaderboardAroundCurrentUser(clientRequest, Wrap1(GetClientLbCallback, "ClientLB"), Wrap1(Shared_ApiCallFailure, "ClientLB_Fail"));
    }
    private function GetClientLbCallback(result:com.playfab.clientmodels.GetLeaderboardAroundCurrentUserResult) : Void
    {
        if (result.Leaderboard.length == 0)
            ASyncAssert.Fail("Client leaderboard results not found");
        
        var serverRequest:com.playfab.servermodels.GetLeaderboardAroundUserRequest = {
            MaxResultsCount : 3,
            StatisticName : TEST_STAT_NAME,
            PlayFabId : playFabId
        };
        PlayFabServerAPI.GetLeaderboardAroundUser(serverRequest, Wrap1(GetServerLbCallback, "ServerLB"), Wrap1(Shared_ApiCallFailure, "ServerLB_Fail"));
    }
    private function GetServerLbCallback(result:com.playfab.servermodels.GetLeaderboardAroundUserResult) : Void
    {
        if (result.Leaderboard.length == 0)
            ASyncAssert.Fail("Server leaderboard results not found");
        
        FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_PASSED, ""));
    }
    
    /// <summary>
    /// CLIENT API
    /// Test that AccountInfo can be requested
    /// Parameter types tested: List of enum-as-strings converted to list of enums
    /// </summary>
    private function AccountInfo() : Void
    {
        var request:com.playfab.clientmodels.GetAccountInfoRequest = {};
        PlayFabClientAPI.GetAccountInfo(request, Wrap1(GetInfoCallback, "ServerLB"), Wrap1(Shared_ApiCallFailure, "Fail"));
    }
    private function GetInfoCallback(result:com.playfab.clientmodels.GetAccountInfoResult) : Void
    {
        ASyncAssert.AssertNotNull(result.AccountInfo);
        ASyncAssert.AssertNotNull(result.AccountInfo.TitleInfo);
        ASyncAssert.AssertNotNull(result.AccountInfo.TitleInfo.Origination);
        ASyncAssert.AssertTrue(result.AccountInfo.TitleInfo.Origination.length > 0); // This is not a string-enum in AS3, so this test is a bit pointless
        
        FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_PASSED, ""));
    }
    
    /// <summary>
    /// CLIENT API
    /// Test that CloudScript can be properly set up and invoked
    /// </summary>
    private function CloudScript() : Void
    {
        if (PlayFabSettings.LogicServerURL == null)
        {
            var urlRequest:com.playfab.clientmodels.GetCloudScriptUrlRequest = {};
            PlayFabClientAPI.GetCloudScriptUrl(urlRequest, Wrap1(GetCloudUrlCallback, "CloudUrl"), Wrap1(Shared_ApiCallFailure, "Fail"));
        }
        else
        {
            CallHelloWorldCloudScript();
        }
    }
    private function GetCloudUrlCallback(result:com.playfab.clientmodels.GetCloudScriptUrlResult) : Void
    {
        ASyncAssert.AssertTrue(result.Url.length > 0);
        CallHelloWorldCloudScript();
    }
    private function CallHelloWorldCloudScript() : Void
    {
        var hwRequest:com.playfab.clientmodels.RunCloudScriptRequest = {
            ActionId : "helloWorld"
        };
        PlayFabClientAPI.RunCloudScript(hwRequest, Wrap1(CloudScriptHWCallback, "CloudUrl"), Wrap1(Shared_ApiCallFailure, "Fail"));
        
        //UUnitAssert.Equals("Hello " + playFabId + "!", lastReceivedMessage);
    }
    private function CloudScriptHWCallback(result:com.playfab.clientmodels.RunCloudScriptResult) : Void
    {
        ASyncAssert.AssertTrue(result.ResultsEncoded.length > 0);
        ASyncAssert.AssertEquals(result.Results.messageValue, "Hello " + playFabId + "!");
        
        FinishTestHandler(new ASyncUnitTestEvent(ASyncUnitTestEvent.FINISH_TEST, ASyncUnitTestEvent.RESULT_PASSED, ""));
    }
}
