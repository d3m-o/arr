# arr

This is a docker compose file and some scripts for maintaining an arr stack. ProtonVPN is run inside `gluetun` and `speedtest-tracker` is used to periodically monitor connection speed.

## Requirements

Other than Docker, you need to install `jq` for the scripts.

## Environment

Your `.env` file will contain your current wireguard key and public IP.

```
WIREGUARD_PRIVATE_KEY=wireguard+private-key+hash1= #AA-123
PUBLIC_IP=1.1.1.1
```

This file will get updated automatically by scripts. The wireguard keys should be stored under `wkeys.json` in the following format.

```
{
    "proton": [
        {
            "region": "AA-123",
            "key": "wireguard+private-key+hash1="
        },
        {
            "region": "BB-456",
            "key": "wireguard+private-key+hash2="
        },
        {
            "region": "CC-789",
            "key": "wireguard+private-key+hash3="
        }
    ]
}
```

## Compose

Anything encapsulated with `{{}}` in the compose file needs to be replaced. These are either paths for your volume mounts or keys/values specific to your environment. See the inline comments for some additional guidance. If it's your first time setting up an arr stack, refer to a [guide](https://trash-guides.info) or look up a YouTube tutorial.

If you want to use my paths for the application data and logs, make these directories.

```
mkdir /docker
mkdir /docker/appdata
mkdir /docker/appdata/gluetun
mkdir /docker/appdata/prowlarr
mkdir /docker/appdata/qbittorrent
mkdir /docker/appdata/speedtest
mkdir /docker/appdata/radarr
mkdir /docker/appdata/sonarr
mkdir /docker/cron
mkdir /docker/cron/log
mkdir /docker/cron/log/health
mkdir /docker/cron/log/daily
```

You'll need to configure your own paths for media and downloads.

## Scripts

### Reload

`reload.sh` will reload the docker stack with a specified region. Running the script with no argument returns a list of available regions. Use this if you're reloading your containers manually.

### Randomizer

`random.sh` will invoke `reload.sh` using a randomly-selected region from `wkeys.json`.

### Public IP Check

`ipcheck.sh` uses `ifconfig.co` to retrieve your public IP. If your current public IP differs from what is in `.env`, then it will update it and run `random.sh` to restart the stack.

### Speed Check

`speedcheck.sh` runs the `speedtest` CLI utility inside the `speedtest-tracker` container. It looks at the download speed and if that speed is less than 100 Mbps it will invoke `random.sh`.

### Database Cleaner

`cleandb.sh` looks at the `speedtest-tracker` SQLite database and will prune any entries that are older than `x` amount of days where `x` is the arg passed to the script. I originally had this running in a cron job, but it isn't necessary since `speedtest-tracker` has a setting which will automatically perform this task.

```
PRUNE_RESULTS_OLDER_THAN=7
```

### Health Check

`healthcheck.sh` performs a series of checks to assert that the stack is in suitable condition.

1. `ipcheck.sh` is invoked. `healthcheck.sh` exits if the stack is restarted.
2. `speedcheck.sh` is invoked at 45 minutes past the hour. `healthcheck.py` exits if the stack is restarted.
3. Finally, each container is inspected to ensure it is running and healthy (if applicable). If any issues are detected, the stack is restarted.

## Cron Jobs

There are two (active) cron jobs.

1. Every morning at 4:15, we restart the stack with a random VPN connection.
2. Every 5 minutes, except between 4:00 and 4:30, we run a health check.

```
15 4 * * * cd /path/to/your/arr/folder && ./random.sh >> /docker/cron/log/daily/output.log 2>&1
*/5 * * * * cd /path/to/your/arr/folder && ./healthcheck.sh >> /docker/cron/log/health/output.log 2>&1
#15 5 * * * cd /path/to/your/arr/folder && ./cleandb.sh 7 >> /docker/cron/log/stdb/output.log 2>&1
```

### Logs

All log files are stored under `/docker/cron/log` and rotated out using `logrotate`.

* `/etc/logrotate.d/cron-daily` rotates the daily restart log file every week and keeps logs for 4 weeks.

```
/docker/cron/log/daily/output.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    notifempty
    create 644 root root
}
```

* `/etc/logrotate.d/cron-stdb` was configured for the speedtest database process, but not needed unless you opt to use this process over the inbuilt pruning functionality. It is also configured to rotate the log weekly and keep logs for 4 weeks.

```
/docker/cron/log/stdb/output.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    notifempty
    create 644 root root
}
```

* `/etc/logrotate.d/cron-health` rotates the health check log file every day and keeps logs for 7 days.

```
/docker/cron/log/health/output.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
}
```
