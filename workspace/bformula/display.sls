{% set os_family = pillar['bformula']['family'] %}
{% set os_arch = pillar['bformula']['architecture'] %}
{% set minion_id = pillar['bformula']['name'] %}
{% set os_name = pillar['bformula']['os'] %}

# Print the values of the grains
bformula_print_os_family:
  cmd.run:
    - name: "echo bformula'{{ os_family }}: {{ salt['grains.get'](os_family) }}'"
bformula_print_os_arch:
  cmd.run:
    - name: "echo bformula '{{ os_arch }}: {{ salt['grains.get'](os_arch) }}'"
bformula_print_minion_id:
  cmd.run:
    - name: "echo bformula '{{ minion_id }}: {{ salt['grains.get'](minion_id) }}'"
bformula_print_os_name:
  cmd.run:
    - name: "echo bformula '{{ os_name }}: {{ salt['grains.get'](os_name) }}'"
