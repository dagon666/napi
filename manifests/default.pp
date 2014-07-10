exec { "apt-get update":
  path => "/usr/bin",
}


package { "busybox":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "libssl-dev":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "make":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "bison":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "flex":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "patch":
	ensure => present,
    require => Exec["apt-get update"],
}

package { "shunit2":
	ensure => present,
    require => Exec["apt-get update"],
}

package { "mplayer":
	ensure => present,
    require => Exec["apt-get update"],
}

package { "mplayer2":
	ensure => present,
    require => Exec["apt-get update"],
}

package { "mediainfo":
	ensure => present,
    require => Exec["apt-get update"],
}

package { "ffmpeg":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "gcc-multilib":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "g++-multilib":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "ncurses-dev":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "libwww-perl":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "original-awk":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "p7zip-full":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "mawk":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "gawk":
	ensure => present,
    require => Exec["apt-get update"],
}


file { "/home/vagrant/bin":
  ensure  => "directory",
  owner => "vagrant",
  mode => 750
}


file { "/home/vagrant/napi_bin":
	ensure => "directory",
   	owner => "vagrant",
  	mode => 750
}


file { "/home/vagrant/bin/sh":
	ensure => "link",
	target => "/bin/busybox",
	require => File['/home/vagrant/bin']
}


exec { "install napi":
	command => "/vagrant/install.sh --bindir /home/vagrant/napi_bin --shareddir /home/vagrant/napi_bin",
	cwd => "/vagrant",
	creates => "/home/vagrant/napi_bin/napi.sh",
	require => File['/home/vagrant/napi_bin']
}


file { "/home/vagrant/bin/subotage.sh":
	ensure => "link",
    target => "/home/vagrant/napi_bin/subotage.sh",
	require => Exec["install napi"]
}


file { "/home/vagrant/bin/napi.sh":
	ensure => "link",
    target => "/home/vagrant/napi_bin/napi.sh",
	require => Exec["install napi"]
}

