humidity <- "";
temperature <- "";
batt <- "";

const html1 = @"<!DOCTYPE html>
<html lang=""en"">
    <head>
        <meta charset=""utf-8"">
        <meta http-equiv=""refresh"" content=""30"">
        <meta name=""viewport"" content=""width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"">
        <meta name=""apple-mobile-web-app-capable"" content=""yes"">
        
        <script src=""http://code.jquery.com/jquery-1.9.1.min.js""></script>
        <script src=""http://code.jquery.com/jquery-migrate-1.2.1.min.js""></script>
        <script src=""http://d2c5utp5fpfikz.cloudfront.net/2_3_1/js/bootstrap.min.js""></script>
        
        <link href=""//d2c5utp5fpfikz.cloudfront.net/2_3_1/css/bootstrap.min.css"" rel=""stylesheet"">
        <link href=""//d2c5utp5fpfikz.cloudfront.net/2_3_1/css/bootstrap-responsive.min.css"" rel=""stylesheet"">
        <link rel=""shortcut icon"" href=""//cdn.shopify.com/s/files/1/0370/6457/files/favicon.ico?802"">
        <title>C3V0 Sensor Module</title>
    </head>
    <body style=""background-color:#666666"">
        <div class='container'>
            <div class='well' style='max-width: 640px; margin: 0 auto 10px; text-align:center;'>
        
            <img src=""//cdn.shopify.com/s/files/1/0370/6457/files/red_black_logo_side_300x100.png?800"">
                
                <h2>C3V0+<h2>
                <h4>Electric Imp sensor monitor</h4>
                <h2>Temperature:</h2><h1>";
const html2 = @"&degF</h1>
                <h2>Humidity:</h2><h1>";
const html3 = @"%</h1>
                <h2>Battery:</h2><h1>";
const html4 = @"V</h1>
            <img src=""//cdn.shopify.com/s/files/1/0370/6457/files/built-for-imp_300px.png?801"">
            </div>
        </div>
    </body>
</html>";

http.onrequest(function(request, response) { 
    if (request.body == "") {
        local html = html1 + temperature + html2 + humidity + html3 + batt + html4;
        response.send(200, html);
    }
    else {
        response.send(500, "Internal Server Error: ");
    }
});

Xively <- {};    // this makes a 'namespace'

class Xively.Client {
    ApiKey = null;
    triggers = [];

	constructor(apiKey) {
		this.ApiKey = apiKey;
	}
	
	/*****************************************
	 * method: PUT
	 * IN:
	 *   feed: a XivelyFeed we are pushing to
	 *   ApiKey: Your Xively API Key
	 * OUT:
	 *   HttpResponse object from Xively
	 *   200 and no body is success
	 *****************************************/
	function Put(feed){
		local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
		local headers = { "X-ApiKey" : ApiKey, "Content-Type":"application/json", "User-Agent" : "Xively-Imp-Lib/1.0" };
		local request = http.put(url, headers, feed.ToJson());

		return request.sendsync();
	}
	
	/*****************************************
	 * method: GET
	 * IN:
	 *   feed: a XivelyFeed we fulling from
	 *   ApiKey: Your Xively API Key
	 * OUT:
	 *   An updated XivelyFeed object on success
	 *   null on failure
	 *****************************************/
	function Get(feed){
		local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
		local headers = { "X-ApiKey" : ApiKey, "User-Agent" : "xively-Imp-Lib/1.0" };
		local request = http.get(url, headers);
		local response = request.sendsync();
		if(response.statuscode != 200) {
			server.log("error sending message: " + response.body);
			return null;
		}
	
		local channel = http.jsondecode(response.body);
		for (local i = 0; i < channel.datastreams.len(); i++)
		{
			for (local j = 0; j < feed.Channels.len(); j++)
			{
				if (channel.datastreams[i].id == feed.Channels[j].id)
				{
					feed.Channels[j].current_value = channel.datastreams[i].current_value;
					break;
				}
			}
		}
	
		return feed;
	}

}
    

class Xively.Feed{
    FeedID = null;
    Channels = null;
    
    constructor(feedID, channels)
    {
        this.FeedID = feedID;
        this.Channels = channels;
    }
    
    function GetFeedID() { return FeedID; }

    function ToJson()
    {
        local json = "{ \"datastreams\": [";
        for (local i = 0; i < this.Channels.len(); i++)
        {
            json += this.Channels[i].ToJson();
            if (i < this.Channels.len() - 1) json += ",";
        }
        json += "] }";
        return json;
    }
}

class Xively.Channel {
    id = null;
    current_value = null;
    mytag = "";
    
    constructor(_id)
    {
        this.id = _id;
    }
    
    function Set(value, tag) { 
    	this.current_value = value;
        this.mytag = tag;
    }
    
    function Get() { 
    	return this.current_value; 
    }
    
    function ToJson() { 
    	local json = http.jsonencode({id = this.id, current_value = this.current_value, tags = this.mytag});
        //server.log(json);
        return json;
    }
}
APIKEY <- "";
FEED_ID <- "";
channel1 <- Xively.Channel("Temperature");
channel2 <- Xively.Channel("Humidity");
channel3 <- Xively.Channel("Battery_Voltage");

client <- Xively.Client(APIKEY);

device.on("data", function(data) {
    humidity = data.humidity;
    temperature = data.temperature;
    batt = data.batt;
    channel1.Set(temperature, "House Temperature");
    channel2.Set(humidity, "House Humidity");
    channel3.Set(batt, "Battery Voltage");
    feed <- Xively.Feed(FEED_ID, [channel1, channel2, channel3]);
    //client.Put(feed);
});
