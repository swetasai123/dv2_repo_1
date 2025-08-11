{% macro generate_hubs() %}

    {{
        config(materialized='table', alias=hub.table_name)
    }}

{% set metadata = load_metadata() %}
    -- === Generate Hubs ===
    {# 2. Ensure we have hubs #}
    {% if not metadata.hubs %}
            {% do exceptions.raise_compiler_error("No hubs defined in metadata.yml") %}
    {% endif %}
    {# 3. Build all SELECT statements first #}
    {% set selects = [] %}
        {% for hub in metadata.hubs %}
    {% set stmt %}
    select
       '{{ hub.table_name }}' as hub_name,             -- Name of the hub
       {{ hub.business_key }} as business_key,   -- Standardized business key column
       current_timestamp as load_date,
       '{{ hub.source_table }}' as record_source -- Record source metadata
        from {{ hub.source_table }}
        group by {{ hub.business_key }}
    {% endset %}
        {% do selects.append(stmt.strip()) %}
        {% endfor %}
{# 4. Join SELECTs cleanly with UNION ALL #}
{{ selects | join('\nunion all\n') }}
{% endmacro %}

