import os
import pandas as pd

# Load metadata
metadata = pd.read_csv("seeds/metadata.csv")

# Define output folders
base_path = "models/data_vault"
folders = {
   'hub': os.path.join(base_path, "hubs"),
   'satellite': os.path.join(base_path, "sats"),
   'link': os.path.join(base_path, "links")
}
# Ensure folders exist
for folder in folders.values():
   os.makedirs(folder, exist_ok=True)
   
# Template for hub
def hub_template(row):
   return f"""
-- Auto-generated Hub: {row['Table_name']}
{{% raw %}}
{{{{ config(materialized='incremental') }}}}
select
   md5(cast({row['business_key']} as string)) as {row['Table_name'].lower()}_hk,
   {row['business_key']},
   current_timestamp() as load_date,
   '{row['source_table']}' as record_source
from {{{{ ref('{row['source_table']}') }}}}
{{% endraw %}}
"""

# Template for satellite
def sat_template(row):
   fields = row['descritptive_fields'].replace('|', ', ')
   return f"""
-- Auto-generated Satellite: {row['Table_name']}
{{% raw %}}
{{{{ config(materialized='incremental') }}}}
select
   md5(cast({row['business_key']} as string)) as {row['Table_name'].lower()}_hk,
   {fields},
   current_timestamp() as load_date,
   '{row['source_table']}' as record_source
from {{{{ ref('{row['source_table']}') }}}}
{{% endraw %}}
"""
# Template for link
def link_template(row):
   keys = row['business_key'].split('|')
   key_fields = ', '.join(keys)
   key_concat = " || '|' || ".join([f"cast({k.strip()} as string)" for k in keys])
   return f"""
-- Auto-generated Link: {row['Table_name']}
{{% raw %}}
{{{{ config(materialized='incremental') }}}}
select
   md5({key_concat}) as {row['Table_name'].lower()}_lk,
   {key_fields},
   current_timestamp() as load_date,
   '{row['source_table']}' as record_source
from {{{{ ref('{row['source_table']}') }}}}
{{% endraw %}}
"""

# Write SQL files
for _, row in metadata.iterrows():
   table_type = row['table_type'].strip().lower()
   table_name = row['Table_name'].lower()
   output_file = os.path.join(folders[table_type], f"{table_type}_{table_name}.sql")
   if table_type == 'hub':
       content = hub_template(row)
   elif table_type == 'satellite':
       content = sat_template(row)
   elif table_type == 'link':
       content = link_template(row)
   else:
       print(f"❌ Unknown type: {table_type}")
       continue
   with open(output_file, 'w') as f:
       f.write(content)
print("✅ All model files (hub/link/sat) generated successfully!")