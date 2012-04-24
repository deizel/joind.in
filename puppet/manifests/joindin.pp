# Tweak these variables to adjust your development environment:
$host   = 'dev.joind.in'
$port   = '80' # Check `VagrantFile` for port forwarding settings
$dbname = 'joindin'
$dbuser = 'joindin'
$dbpass = 'password'
#$debug  = 'on'

# Set default path for Exec calls
Exec {
  path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ]
}

# Include required modules
node default {
  include apache
  include mysql
}

# Configure apache virtual host
apache::vhost { $host:
  docroot  => '/vagrant/src',
  template => '/vagrant/puppet/templates/vhost.conf.erb',
  port     => $port,
}

# Install PHP modules
php::module { 'mysql': }

# Set development values to php.ini
augeas{ 'set-php-ini-values':
  context => '/files/etc/php.ini',
  changes => [
    'set PHP/error_reporting "E_ALL | E_STRICT"',
    'set PHP/display_errors On',
    'set PHP/display_startup_errors On',
    'set PHP/html_errors On',
    'set Date/date.timezone Europe/London',
  ],
  require => Package['php'],
  notify  => Service['apache'],
}

# Create and grant privileges to joindin database
exec { 'create-db':
  unless  => "mysql -u${dbuser} -p${dbpass} ${dbname}",
  command => "mysql -e \"create database ${dbname}; \
              grant all on ${dbname}.* \
              to ${dbuser}@localhost identified by '$dbpass';\"",
  require => Service['mysql'],
  before  => Notify['running'],
}

# Intialise database structure
exec { 'patch-db':
  creates => '/tmp/.patched',
  command => "/vagrant/src/scripts/patchdb.sh \
              -t /vagrant -d ${dbname} -u ${dbuser} -p ${dbpass} -i -p \
              && touch /tmp/.patched",
  require => Exec['create-db'],
  before  => Notify['running'],
}

# Generate seed data
exec { 'seed-data':
  creates => '/tmp/seed.sql',
  command => 'php /vagrant/doc/dbgen/generate.php > /tmp/seed.sql',
  require => Package['php'],
  before  => Notify['running'],
}

# Seed database
exec { 'seed-db':
  creates => '/tmp/.seeded',
  command => "mysql ${dbname} < /tmp/seed.sql \
              && touch /tmp/.seeded",
  require => [
    Exec['patch-db'],
    Exec['seed-data'],
  ],
  before  => Notify['running'],
}

# Set database config for application
file { 'database-config':
  path   => '/vagrant/src/system/application/config/database.php',
  source => '/vagrant/puppet/templates/database.php.erb',
  before => Notify['running'],
}

# Set core config for application
file { 'application-config':
  path   => '/vagrant/src/system/application/config/config.php',
  source => '/vagrant/puppet/templates/config.php.erb',
  before => Notify['running'],
}

# Create directory for user-generated content
file { 'upload-directory':
  ensure  => directory,
  path    => '/tmp/ctokens',
  mode    => '0644',
  owner   => 'apache',
  group   => 'apache',
  require => Service['apache'],
  before  => Notify['running'],
}

# Announce success message
notify { 'running':
  message => "Visit http://${host}:8080 in your browser.",
}
