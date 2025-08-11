{% macro load_metadata(yaml_file='macros/data_vault_metadata.yml') %}
    {#- loads metadat from YAML file into a dictonary containing:
        - hubs,links,sats
    -#}
    {%set metadata_dict = load_yaml(file=yaml_file)%}

    {% set metadata = {
        "hubs": metadata_dict.get("hubs", []),
        "links": metadata_dict.get("links", []),
        "sats": metadata_dict.get("sats", [])
    } %}

    {{ return(metadata)}}

{% endmacro %}


