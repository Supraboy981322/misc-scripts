# misc-scripts: battery_notifier

A somewhat simple and definitely not overengineered battery notification daemon.

<sub>Also checks for AC power state.</sub>

>[!NOTE]
>This relies on notify-send to send notifications (usually pre-installed on most distros) 

My laptop runs NixOS with Hyprland, so it doesn't have a battery notification daemon by default. Instead of installing one someone already made, I thought "how hard could it be to write my own?" Then I wrote it.

The daemon tries to automatically check for a battery and AC power (in the `/sys/class/power_supply` VFS), but if your battery and/or AC power isn't located there, for whatever reason, you can use a configuration. You can configure a specific path for the battery and/or AC power, or you can disable the AC power check. You can set the `"pulse"` to change how frequent the checks are run. The battery "low" state is also configurable, which's when it'll start to send a notification for every decrement (if it's divisible by 5), but it defaults to `25`% if unset. 

Below is my configuration as an example
```gomn
/*change for a different check frequency
    (defaults to 1 if 0 or invalid)   */
["pulse"] := 1

["battery"] := |
  //remove for automatic check
  ["path"] := "/sys/class/power_supply/BAT0/capacity"
  //change for a different "low" state
  ["low"] := 25
|

["ac"] := |
  //set to false to disable ac check
  ["check"] := true
  //remove for automatic check
  ["path"] := "/sys/class/power_supply/AC0/online"
|
```

### Installation

Go install
```sh
go install github.com/Supraboy981322/misc-scripts/battery_notifier@latest
```
