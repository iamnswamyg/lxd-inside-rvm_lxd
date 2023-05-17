{% set os_family = pillar['aformula']['family'] %}
{% set os_arch = pillar['aformula']['architecture'] %}
{% set minion_id = pillar['aformula']['name'] %}
{% set os_name = pillar['aformula']['os'] %}

# Print the values of the grains
aformula_rint_os_family:
  cmd.run:
    - name: "echo aformula'{{ os_family }}: {{ salt['grains.get'](os_family) }}'"
aformula_print_os_arch:
  cmd.run:
    - name: "echo aformula'{{ os_arch }}: {{ salt['grains.get'](os_arch) }}'"
aformula_print_minion_id:
  cmd.run:
    - name: "echo aformula'{{ minion_id }}: {{ salt['grains.get'](minion_id) }}'"
aformula_print_os_name:
  cmd.run:
    - name: "echo aformula'{{ os_name }}: {{ salt['grains.get'](os_name) }}'"
