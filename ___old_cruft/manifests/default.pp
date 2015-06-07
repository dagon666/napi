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


package { "texinfo":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "install-info":
	ensure => present,
    require => Exec["apt-get update"],
}


package { "wget":
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


exec { "prepare_shells":
    command => "/vagrant/tests/prepare_shells.pl",
    cwd => "/vagrant",
    creates => "/opt/napi/bash",
    require => [ Package['wget'], ],
    timeout => 28800,
    logoutput => true,
}


exec { "prepare_assets":
    command => "/vagrant/tests/prepare_assets.pl",
    cwd => "/vagrant",
    creates => "/usr/share/napi/testdata",
    require => Package['wget'],
    logoutput => true,
    timeout => 600,
}
