// vim: sw=4 ts=4 noet filetype=javascript
// (close enough)

// NOTE: Put this in cloudflare.tf instead!
// provider "cloudflare" {
// 	version = "~> 1.12"
// }

// NOTE: Put this in digitalocean.tf instead!
// provider "digitalocean" {
// 	version = "~> 1.9"
// }

provider "template" {
	version = "~> 2.1"
}

// Configured servers
// To see them, go here:
// https://cloud.digitalocean.com/droplets

module "projectname_www" {
	source = "./modules/digitalocean-devuan-beowulf/"
	name   = "projectname.www"
	projectname_users = [
		"wwwfiles",
	]
	projectname_roles = [
		"composer",
		"mariadb-client",
		"webserver",
		"wp-cli",
	]
	projectname_hostnames_proxied = [
		"www",
	]
}
