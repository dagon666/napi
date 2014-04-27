import 'netinstall.pp'

exec { "apt-get update":
  path => "/usr/bin",
}


package { "busybox":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "make":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "ncurses-dev":
	ensure => present,
    require => Exec["apt-get update"],
}


file { "/home/vagrant/bin":
  ensure  => "directory",
  owner => "vagrant",
  mode => 750
}


file { "/home/vagrant/bin/sh":
	ensure => "link",
	target => "/bin/busybox",
}


file { "/home/vagrant/bin/napi.sh":
	ensure => "link",
	target => "/vagrant/napi.sh",
}


file { "/home/vagrant/bin/subotage.sh":
	ensure => "link",
    target => "/vagrant/subotage.sh",
}


puppi::netinstall { "bash3":
  url => "http://ftp.gnu.org/gnu/bash/bash-3.0.tar.gz",
  source_filename => "bash-3.0.tar.gz",
  source_filetype => "tgz",
  source_dirname => "bash",
  extracted_dir => "bash-3.0",
  destination_dir => "/tmp",
  postextract_command => "/tmp/bash-3.0/configure && make && cp -v bash /home/vagrant/bin/bash3"
}
