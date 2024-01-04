Make this entries in the root crontab

```bash
## Start the Love Matrix @ reboot
@reboot cd /opt/love && /opt/love/love.sh

## Start the toggler
@reboot /opt/love/toggler.sh

## Stop the "love" screen session at 6pm
0 18 * * * /usr/bin/screen -S love -X quit

## Start the "love" screen at 5am
0 5 * * * cd /opt/love && /opt/love/love.sh
```