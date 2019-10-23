// vim: sw=4 ts=4 noet filetype=javascript
// (close enough)

// https://www.terraform.io/docs/providers/template/d/cloudinit_config.html
data "template_file" "projectname_devuan_cloudinit" {
	template = "${file("${path.module}/../../remote/projectname-digitalocean-devuan-cloudinit.tpl")}"
	vars = {
		init_sh           = "${base64encode(file("${path.module}/../../remote/projectname-digitalocean-devuan-init.sh"))}"
		ssh_keys_ROOT_txt = "${base64encode(file("${path.module}/../../keys/ssh_authorized_keys_ROOT.txt"))}"
	}
}

resource "digitalocean_droplet" "this" {
	image  = "debian-9-x64"
	name   = "${var.name}"
	region = "ams3"
	size   = "${var.size}"

	tags = [
		"Type:projectname_devuan"
	]

	// Run setup script on server init
	user_data = "${data.template_file.projectname_devuan_cloudinit.rendered}"

	// Ignore changes to user_data (otherwise they would force servers to be
	// destroyed and recreated); generally prevent servers from being destroyed
	lifecycle {
		ignore_changes = ["user_data"]
		// TODO: doesn't always work? e.g. if a module is renamed or removed
		prevent_destroy = true
	}
}

// Waiting for for_each:
// https://github.com/hashicorp/terraform/issues/17179

resource "cloudflare_record" "projectname_dns_unproxied" {
	count   = "${length(var.projectname_hostnames_unproxied)}"

	domain  = "projectname.com"
	name    = "${element(var.projectname_hostnames_unproxied, count.index)}"
	type    = "A"
	value   = "${digitalocean_droplet.this.ipv4_address}"
	proxied = false
}

resource "cloudflare_record" "projectname_dns_proxied" {
	count   = "${length(var.projectname_hostnames_proxied)}"

	domain  = "projectname.com"
	name    = "${element(var.projectname_hostnames_proxied, count.index)}"
	type    = "A"
	value   = "${digitalocean_droplet.this.ipv4_address}"
	proxied = true
}

variable "name" {
	description = "The server name (should start with 'projectname_')"
}

variable "size" {
	description = "The DigitalOcean droplet size"
	default     = "s-1vcpu-1gb"
}

variable "projectname_roles" {
	description = "The roles that this server will fulfill"
	default     = []
}
output "projectname_roles" {
	value = ["${var.projectname_roles}"]
}

variable "projectname_users" {
	description = "The Unix users to create on this server"
	default     = []
}
output "projectname_users" {
	value = ["${var.projectname_users}"]
}

// Waiting for better variable data structures:
// https://github.com/hashicorp/terraform/issues/2114

variable "projectname_hostnames_unproxied" {
	description = "The subdomains for this server (Cloudflare NON-proxied DNS; Apache virtual hosts)"
	default     = []
}
output "projectname_hostnames_unproxied" {
	value = ["${var.projectname_hostnames_unproxied}"]
}

variable "projectname_hostnames_proxied" {
	description = "The subdomains for this server (Cloudflare proxied DNS; Apache virtual hosts)"
	default     = []
}
output "projectname_hostnames_proxied" {
	value = ["${var.projectname_hostnames_proxied}"]
}

output "droplet_id" {
	value = "${digitalocean_droplet.this.id}"
}
