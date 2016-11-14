# mk-lab-terraform-packet
Use Terraform to deploy Mk22 lab on the bare-metal provider packet.net

##### Steps

- Install [Terraform](https://www.terraform.io/downloads.html)
- Register with www.packet.net for an account. **Important:** Use of Packet will incur costs hourly. **Note:** Packet offers discount codes like [the one](https://www.packet.net/promo/coreos/) of the fine folks from [CoreOS](https://coreos.com/) that can get you started
- Obtain API key token from your packet.net account
- Clone this repo
- Copy ```settings.tf.orig``` to ```settings.tf```
- Set API key token in ```settings.tf```
- Set path to your private ssh key in ```settings.tf```
- Then run
```bash
(~/mk-lab-terraform-packet) $ terraform apply .
```
- Deployment can take about 90 minutes. After deploy, the public IP of the Salt master cfg01 will be displayed
- Login
```bash
(~/mk-lab-terraform-packet) $ ssh root@<PUBLIC-IP>
```
- Horizon is available at `https://172.16.10.100`  user admin, password workshop
- Contrail is avaiable at `https://172.16.10.254:8143`  user admin, password workshop, domain admin
- Use a tool like [sshuttle](https://github.com/apenwarr/sshuttle) as poor man's VPN into the lab:
```bash
(~/mk-lab-terraform-packet) $  sshuttle -v -r root@<PUBLIC-IP> 192.168.150.0/24 172.16.10.0/24
```
- **Important:** When done delete resources to save unnecessary costs:
```bash
(~/mk-lab-terraform-packet) $ terraform destroy .
```
- Verify no servers are still running at packet.net

##### Credits
- [Sam's blog](http://samos-it.com/posts/openstack-salt-mk22-vagrant-lab.html) for illustrating how to use Mk22 lab with Vagrant
- [Sebastian's blog](http://www.yet.org/2016/10/os-salt/) for detailed guide and intro to Salt, reclass, and Salt OpenStack
