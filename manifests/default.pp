exec { "apt-get update":
  path => "/usr/bin",
}


package { "busybox":
	ensure => present,
    require => Exec["apt-get update"],
}


file { "/home/vagrant/bin":
  ensure  => "directory",
}


file { "/home/vagrant/bin/sh":
	ensure => "link",
	target => "/bin/busybox",
}
