# == Class: github
#
class github(
  $oauth_token,
  $project_password,
  $project_username,
  $username,
) {
  include ::jeepyb
  include ::pip

  if ! defined(Package['PyGithub']) {
    package { 'PyGithub':
      ensure   => latest,  # okay to use latest for pip
      provider => pip,
      require  => Class['pip'],
    }
  }

  # A lot of things need yaml, be conservative requiring this package to avoid
  # conflicts with other modules.
  if ! defined(Package['python-yaml']) {
    package { 'python-yaml':
      ensure => present,
    }
  }

  group { 'github':
    ensure => present,
  }

  user { 'github':
    ensure  => present,
    comment => 'Github API User',
    shell   => '/bin/bash',
    gid     => 'github',
    require => Group['github'],
  }

  file { '/etc/github':
    ensure => directory,
    group  => 'root',
    mode   => '0755',
    owner  => 'root',
  }

  file { '/etc/github/github.config':
    ensure => absent,
  }

  file { '/etc/github/github.secure.config':
    ensure  => present,
    content => template('github/github.secure.config.erb'),
    group   => 'github',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => [
      Group['github'],
      File['/etc/github'],
    ],
  }

  file { '/etc/github/github-projects.secure.config':
    ensure  => present,
    content => template('github/github-projects.secure.config.erb'),
    group   => 'github',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => [
      Group['github'],
      File['/etc/github'],
    ],
  }

  file { '/usr/local/github':
    ensure => directory,
    group  => 'root',
    mode   => '0755',
    owner  => 'root',
  }

  file { '/usr/local/github/scripts':
    ensure  => absent,
  }

  cron { 'githubclosepull':
    command => 'sleep $((RANDOM\%60+90)) && /usr/local/bin/close-pull-requests',
    minute  => '*/5',
    require => [
      Class['jeepyb'],
      Package['python-yaml'],
      Package['PyGithub'],
    ],
    user    => github,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
