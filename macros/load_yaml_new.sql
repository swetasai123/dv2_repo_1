{% macro load_yaml(path) %}
  {{ return(load_file(path) | from_yaml) }}
{% endmacro %}
