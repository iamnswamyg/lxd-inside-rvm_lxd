{% if grains['virtual'] == 'physical' %}
rng-tools:
  pkg:
    - installed
  
haveged:
  pkg:
    - installed
{% endif %}
