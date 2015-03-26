node default {
  class { 'ocf::groups': stage => first }
  class { 'ocf::puppet': stage => first }
  class { 'ocf::rootpw': stage => first }

  case $::hostname {
    anthrax, sandstorm: { }
    default:   { include ocf::postfix }
  }

  include ocf::autologout
  include ocf::git
  include ocf::kerberos
  include ocf::ldap
  include ocf::locale
  include ocf::memtest
  include ocf::munin::node
  include ocf::ntp
  include ocf::packages
  include ocf::ocflib
  include ocf::smart
  include ocf::utils
  include ocf::zsh

  if $::macAddress {
    include networking
  } else {
    case $::hostname {
      hal, pandemic, jaws: {
        $bridge = true
        $vlan   = false
      }
      default: {
        $bridge = false
        $vlan   = false
      }
    }
    if !$::skipNetworking {
      class { 'networking':
        ipaddress   => $::ipHostNumber,
        netmask     => '255.255.255.0',
        gateway     => '169.229.10.1',
        bridge      => $bridge,
        vlan        => $vlan,
        domain      => 'ocf.berkeley.edu',
        nameservers => ['169.229.10.22', '128.32.206.12', '128.32.136.9'],
      }
    }
  }

  case $type {
    'server': {
      class { 'ocf::apt': stage => first }

      if $owner == undef {
        case $::hostname {
          supernova: { class { 'ocf::auth': glogin => [ ['approve', 'ALL'] ] } }
          tsunami:   { class { 'ocf::auth': glogin => [ ['ocf', 'ALL'], ['sorry', 'ALL'] ] } }
          biohazard: { class { 'ocf::auth': glogin => [ ['ocfdev', 'ALL'] ] } }
          pollution: { class { 'ocf::auth': glogin => [ ['approve', 'ALL'] ], gsudo => ['ocfstaff'] } }
          default:   { class { 'ocf::auth': ulogin => [], glogin => [], usudo => [], gsudo => [] } }
        }
      } else { # grant login and sudo to owner
        class { 'ocf::auth': ulogin => [[$owner, 'ALL']], usudo => [$owner], nopasswd => true }
      }

      include ocf::ssh
    }

    'desktop': {
      $glogin = $::staff_only ? {
        true    => [ ['approve', 'ALL'] ],
        default => [ ['ocf', 'LOCAL'] ]
      }

      class { 'ocf::auth':
        glogin => $glogin,
        gsudo => ['ocfstaff'];
      }

      class { 'ocf_desktop': staff => $::staff_only }
    }
  }
}
