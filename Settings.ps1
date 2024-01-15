# Configure the variables below that will be used in the script
$HAToken = "<Insert token>" # Example: eyJ0eXAiOiJKV1...
$UserName = "<UserName>" # When not sure, open a command prompt and type: echo %USERNAME%
$HAUrl = "<HAUrl>" # Example: https://yourha.duckdns.org

# Set language variables below
$lgAvailable = "Available"
$lgBusy = "Busy"
$lgOnThePhone = "On the phone"
$lgAway = "Away"
$lgBeRightBack = "BeRightBack"
$lgDoNotDisturb = "DoNotDisturb"
$lgPresenting = "Presenting"
$lgFocusing = "Focusing"
$lgInAMeeting = "In a meeting"
$lgOffline = "Offline"
$lgNotInACall = "Not in a call"
$lgInACall = "In a call"

# Set icons to use for call activity
$iconInACall = "mdi:phone-in-talk-outline"
$iconNotInACall = "mdi:phone-off"
$iconMonitoring = "mdi:api"

# Set entities to post to
$entityStatus = "sensor.teams_status"
$entityStatusName = "Microsoft Teams status"
$entityActivity = "sensor.teams_activity"
$entityActivityName = "Microsoft Teams activity"
$entityHeartbeat = "binary_sensor.teams_monitoring"
$entityHeartbeatName = "Microsoft Teams monitoring"
