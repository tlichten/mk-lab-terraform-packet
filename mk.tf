# Configure the Packet Provider
provider "packet" {
  auth_token = "${var.packet_api_key}"
}

# Create a new SSH key
resource "packet_ssh_key" "mk_key" {
    name = "mk_key"
    public_key = "${file("${var.ssh_private_key}.pub")}"
}

# Create mk project
resource "packet_project" "mk" {
        name = "mk_lab"
}

# Create Salt master cfg01
resource "packet_device" "cfg01" {
        hostname = "cfg01.${var.cluster_domain}"
        plan = "${var.packet_machine_type}"
        facility = "${var.packet_location}"
        operating_system = "ubuntu_16_04_image"
        billing_cycle = "hourly"
        project_id = "${packet_project.mk.id}"

        connection {
          type = "ssh"
          user = "root"
          port = 22
          timeout = "1200"
          private_key = "${file("${var.ssh_private_key}")}"
        }

        provisioner "file" {
            source = "templates/weave.sh"
            destination = "/root/weave.sh"
        }

        # Set up additional eth interface using weave
        provisioner "remote-exec" {
          inline = [
            "export ubuntu_release='xenial'",
            "export private_ip_address=''",
            "/bin/bash weave.sh"
          ]
        }
}

resource "null_resource" "cfg01_master_provision" {
        depends_on = ["packet_device.cfg01"]

        connection {
          type = "ssh"
          host = "${packet_device.cfg01.network.0.address}"
          user = "root"
          port = 22
          timeout = "1200"
          private_key = "${file("${var.ssh_private_key}")}"
        }

        provisioner "file" {
            source = "templates/master.sh"
            destination = "/root/master.sh"
        }

        # set up salt master
        provisioner "remote-exec" {
          inline = [
            "export node_name='cfg01.${var.cluster_domain}'",
            "export reclass_address='https://github.com/tlichten/mk-lab-salt-model'",
            "export reclass_branch='dash'",
            "export private_ip='${packet_device.cfg01.network.2.address}'",
            "/bin/bash master.sh"
          ]
        }

        provisioner "file" {
            source = "templates/setipaddress.sh"
            destination = "/root/setipaddress.sh"
        }

        # Set up ip address for interface  weave
        provisioner "remote-exec" {
          inline = [
            "/bin/bash setipaddress.sh"
          ]
        }
}

variable "nodes" {
  default = {
    "0" = "ctl01"
    "1" = "ctl02"
    "2" = "ctl03"
    "3" = "cmp01"
    "4" = "mon01"
    "5" = "prx01"
  }
}

resource "packet_device" "node" {
        depends_on = ["null_resource.cfg01_master_provision"]
        count =  "6"

        hostname = "${lookup(var.nodes, count.index)}.${var.cluster_domain}"
        plan = "${var.packet_machine_type}"
        facility = "${var.packet_location}"
        operating_system = "ubuntu_14_04_image"
        billing_cycle = "hourly"
        project_id = "${packet_project.mk.id}"

        connection {
          type = "ssh"
          user = "root"
          port = 22
          timeout = "1200"
          private_key = "${file("${var.ssh_private_key}")}"
        }

        provisioner "file" {
            source = "templates/weave.sh"
            destination = "/root/weave.sh"
        }

        # Set up additional eth interface using weave
        provisioner "remote-exec" {
          inline = [
            "export ubuntu_release='trusty'",
            "export private_ip_address='${packet_device.cfg01.network.2.address}'",
            "/bin/bash weave.sh"
          ]
        }

        provisioner "file" {
            source = "templates/slave_workaround.sh"
            destination = "/root/slave_workaround.sh"
        }

        # some additional packages are needed to satisfy installation
        provisioner "remote-exec" {
          inline = [
            "/bin/bash slave_workaround.sh"
          ]
        }

        provisioner "file" {
            source = "templates/slave.sh"
            destination = "/root/slave.sh"
        }

        # set up salt minions/slaves
        provisioner "remote-exec" {
          inline = [
            "export node_name='${lookup(var.nodes, count.index)}.${var.cluster_domain}'",
            "export config_host='${packet_device.cfg01.network.2.address}'",
            "/bin/bash slave.sh"
          ]
        }

        provisioner "file" {
            source = "templates/setipaddress.sh"
            destination = "/root/setipaddress.sh"
        }

        # Set up ip address for interface  weave
        provisioner "remote-exec" {
          inline = [
            "/bin/bash setipaddress.sh"
          ]
        }

}


# run mk22 bootstrap: controller services, compute services, contrail, network
# and launch demo vm with network and floating ip
resource "null_resource" "bootstrap" {
        depends_on = ["packet_device.node"]

        connection {
          type = "ssh"
          host = "${packet_device.cfg01.network.0.address}"
          user = "root"
          port = 22
          timeout = "1200"
          private_key = "${file("${var.ssh_private_key}")}"
        }

        provisioner "remote-exec" {
          inline = [
            "cd /srv/salt/reclass/scripts/ && ./bootstrap_all.sh"
          ]
        }
}

output "salt_master" {
    value = "${packet_device.cfg01.network.0.address}"
}

output "steps" {
    value = [
      "ssh root@${packet_device.cfg01.network.0.address}",
      "salt 'ctl01*' cmd.run '. /root/keystonerc; nova list'",
      "ssh cirros@<floating-ip>  #password cubswin:)"
    ]
}
