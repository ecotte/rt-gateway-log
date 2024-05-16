# Fabric notebook source

# METADATA ********************

# META {
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "ee217cb0-9ee4-47f1-9f48-2345c8429338",
# META       "default_lakehouse_name": "GatewayLogs",
# META       "default_lakehouse_workspace_id": "23d1a6d9-5f8f-4fdb-a4d8-afc062aeee99",
# META       "known_lakehouses": [
# META         {
# META           "id": "ee217cb0-9ee4-47f1-9f48-2345c8429338"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

# Welcome to your new notebook
# Type here in the cell editor to add code!

df = spark.read.parquet("Files/KQL/GatewayReports-Raw/18cd2d25-ddb3-48cf-815a-a89ba99ef10f_0_0e516b2f69f24d8b850224775a5d05ed.parquet")

df

# CELL ********************

display(df)

# CELL ********************

pd = df.toPandas()

# CELL ********************

