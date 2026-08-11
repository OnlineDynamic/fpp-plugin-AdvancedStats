<?php

include_once("/opt/fpp/www/common.php");
$pluginName = basename(dirname(__FILE__));

// Safely get the plugin config file path
if (isset($settings) && isset($settings['configDirectory'])) {
    $pluginConfigFile = $settings['configDirectory'] . "/plugin." . $pluginName;
} else {
    // Fallback to default FPP config directory
    $pluginConfigFile = "/home/fpp/media/config/plugin." . $pluginName;
}

if (file_exists($pluginConfigFile)){
$pluginSettings = parse_ini_file($pluginConfigFile);
}else{
$pluginSettings = array();
}

// Get plugin setting by key
function advancedstats_getPluginSetting($key, $default = '') {
global $pluginSettings;
return isset($pluginSettings[$key]) ? $pluginSettings[$key] : $default;
}

// Timeouts (seconds) for calls to the local FPP API, so a hung or
// unresponsive fppd can't stall the page/hook that triggered the call.
define('ADVANCEDSTATS_API_CONNECT_TIMEOUT', 2);
define('ADVANCEDSTATS_API_TIMEOUT', 5);

// Apply the standard timeouts to a curl handle
function advancedstats_setCurlTimeouts($ch) {
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, ADVANCEDSTATS_API_CONNECT_TIMEOUT);
curl_setopt($ch, CURLOPT_TIMEOUT, ADVANCEDSTATS_API_TIMEOUT);
}

// Get all playlists from FPP
function advancedstats_getPlaylistsFromFPP() {
$ch = curl_init('http://localhost/api/playlists');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, 0);
advancedstats_setCurlTimeouts($ch);
$data = curl_exec($ch);
curl_close($ch);
$result = json_decode($data, true);
// FPP API returns a simple array of playlist names
if (is_array($result)) {
return $result;
}
return array();
}

// Get FPP status
function advancedstats_getFPPStatus() {
$ch = curl_init('http://localhost/api/fppd/status');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, 0);
advancedstats_setCurlTimeouts($ch);
$data = curl_exec($ch);
curl_close($ch);
return json_decode($data, true);
}

// Check if a playlist is currently running
function advancedstats_isPlaylistRunning($playlistName) {
$status = advancedstats_getFPPStatus();
$currentPlaylist = isset($status['current_playlist']['playlist']) ? $status['current_playlist']['playlist'] : '';
return ($currentPlaylist === $playlistName && $playlistName !== '');
}

// Start a playlist
function advancedstats_startPlaylist($playlistName, $repeat = false) {
$data = array('command' => 'start', 'playlist' => $playlistName);
if ($repeat) {
$data['repeat'] = true;
}

$ch = curl_init('http://localhost/api/command');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
advancedstats_setCurlTimeouts($ch);
$response = curl_exec($ch);
curl_close($ch);

return json_decode($response, true);
}

// Stop all playlists
function advancedstats_stopAllPlaylists() {
$data = array('command' => 'stop');
$ch = curl_init('http://localhost/api/command');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
advancedstats_setCurlTimeouts($ch);
$response = curl_exec($ch);
curl_close($ch);

return json_decode($response, true);
}

// Get current brightness
function advancedstats_getCurrentBrightness() {
$brightness = getSetting('brightness');
if ($brightness === false || $brightness === '') {
return 100;
}
return intval($brightness);
}

// Set brightness
function advancedstats_setFPPBrightness($level) {
if ($level < 0) $level = 0;
if ($level > 100) $level = 100;

$ch = curl_init('http://localhost/api/system/brightness/' . $level);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
advancedstats_setCurlTimeouts($ch);
$response = curl_exec($ch);
curl_close($ch);

return json_decode($response, true);
}

// Log to plugin log file
function advancedstats_logPluginMessage($message) {
$logFile = '/home/fpp/media/logs/fpp-plugin-AdvancedStats.log';
$timestamp = date('Y-m-d H:i:s');
$logMessage = "[$timestamp] $message\n";
file_put_contents($logFile, $logMessage, FILE_APPEND);
}

?>
