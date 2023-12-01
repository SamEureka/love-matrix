# love-matrix
Love displayed on a RGB Matrix 

### Install
##### Ansible Playbook

```
ansible-playbook -e "target_hosts=hostname1,hostname2" install_love_playbook.yml
```
```
ansible-playbook -e "target_hosts=hostname1,hostname2" reboot_playlist.yml
``` 

##### Bash Script

```
curl -sSL https://raw.githubusercontent.com/SamEureka/love-matrix/main/install.sh | sudo bash
```