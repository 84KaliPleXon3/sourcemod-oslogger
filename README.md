# sourcemod-oslogger
logs os info to sql database, fork of paranoia ip

## install

clone repo, extract to `/tf/addons/sourcemod/`

update `/tf/addons/sourcemod/configs/databases.cfg` to be something like this:

```
...

"oslogger"
        {
                "driver"                        "default"
                "host"                          "127.0.0.1"
                "database"                      "oslogger"
                "user"                          "username"
                "pass"                          "password"
                //"timeout"                     "0"
                "port"                          "3306"
        }

...
```
