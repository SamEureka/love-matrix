# love-matrix
Love displayed on a RGB Matrix 

### Install
##### Ansible Playbook

```bash
ansible-playbook -e "target_hosts=hostname1,hostname2" install_love_playbook.yml
```
```bash
ansible-playbook -e "target_hosts=hostname1,hostname2" reboot_playlist.yml
``` 

##### Bash Script

```bash
curl -sSL https://raw.githubusercontent.com/SamEureka/love-matrix/main/install.sh | sudo bash
```

__NOTE:__ Be sure to short pin 25 to ground after installing. The code expects pin 25 to be shorted and will reboot until it is.