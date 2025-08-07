{% macro generate_hubs() %}

{% set metadata = load_yaml('macros/data_vault_metadata.yml') %}

-- === Generate Hubs ===
{% for hub in metadata['hubs'] %}
   -- HUB: {{ hub.table_name }}
   {{
       config(materialized='view', alias=hub.table_name)
   }}
   with source_data as (
       select
           {% for key in hub.business_keys %}
               {{ key }},
           {% endfor %}
           current_timestamp() as load_date
       from {{ hub.source_table }}
   )
   select
       {{ dbt_utils.generate_surrogate_key(hub.business_keys) }} as {{ hub.table_name }}_hk,
       *
   from source_data;
{% endfor %}
{% endmacro %}

{% macro generate_links() %}
-- === Generate Links ===
{% for link in metadata['links'] %}
   -- LINK: {{ link.table_name }}
   {{
       config(materialized='view', alias=link.table_name)
   }}
   with source_data as (
       select
           {% for key in link.business_key %}
               {{ key }},
           {% endfor %}
           current_timestamp() as load_date
       from {{ link.source_name }}
   )
   select
       {{ dbt_utils.generate_surrogate_key(link.keys) }} as {{ link.table_name }}_lk,
       *
   from source_data;
{% endfor %}
{% endmacro %}

{% macro generate_sats() %}
-- === Generate Satellites ===
{% for sat in metadata['sats'] %}
   -- SATELLITE: {{ sat.table_name }}
   {{
       config(materialized='view', alias=sat.table_name)
   }}
   with source_data as (
       select
           {% for key in sat.business_keys %}
               {{ key }},
           {% endfor %}
           {% for attr in sat.descriptive_fields %}
               {{ attr }},
           {% endfor %}
           {{ sat.effective_date }} as effective_date,
           '{{ sat.record_source }}' as record_source,
           current_timestamp() as load_date
       from {{ sat.source_table }}
   )
   select
       {{ dbt_utils.generate_surrogate_key(sat.business_keys) }} as {{ sat.table_name }}_hk,
       {{ dbt_utils.generate_surrogate_key(sat.descriptive_fields) }} as hashdiff,
       effective_date,
       load_date,
       record_source,
       {% for col in sat.business_keys + sat.descriptive_fields %}
           {{ col }},
       {% endfor %}
   from source_data;
{% endfor %}
{% endmacro %}