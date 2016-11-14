# mk-lab-terraform-packet
Use Terraform to deploy Mk22 on the bare-metal provider packet.net

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
- After deploy, the public IP of the Salt master cfg01 will be displayed
- Login
```bash
(~/mk-lab-terraform-packet) $ ssh root@<PUBLIC-IP>
```
- **Important:** When done delete resources to save unnecessary costs:
```bash
(~/mk-lab-terraform-packet) $ terraform destroy .
```
- Verify no servers are still running at packet.net

