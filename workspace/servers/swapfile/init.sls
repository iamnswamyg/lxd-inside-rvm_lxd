{#
    Create swapfile.
    Tested on Ubuntu 22. Assumed to work elsewhere.

    Setting 'swapfilesizemb' on the host is optional, default 4096 MB.
    
    WARNING:
    dd does not care if 'filesize' exceeds free space on root, it will take all it
    can get a hold of and swapfile will be activated whether you like it or not.

#}

{%- set this_host = pillar['ufconfig']['hosts'][grains.id] %}
{%- set filesize = this_host.get('swapfilesizemb',4096) %}

create_swapfile:
  cmd.run:
    - name: |
        dd if=/dev/zero of=/.swapfile bs=1M count={{ filesize }}
        chmod 0600 /.swapfile
        mkswap /.swapfile
        echo '/.swapfile      none      swap     sw       0       0' >> /etc/fstab
        swapon -a
    - unless: test -f /.swapfile
