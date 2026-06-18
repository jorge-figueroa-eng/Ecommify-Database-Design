"""Calcula improvement_percent en CSV de métricas después de llenar tiempos before/after."""
import sys
import pandas as pd

path = sys.argv[1]
df = pd.read_csv(path)
if 'execution_time_before_ms' not in df or 'execution_time_after_ms' not in df:
    raise SystemExit('El CSV debe tener columnas execution_time_before_ms y execution_time_after_ms')

def improvement(row):
    before = row.get('execution_time_before_ms')
    after = row.get('execution_time_after_ms')
    if pd.isna(before) or pd.isna(after) or float(before) == 0:
        return None
    return round(((float(before) - float(after)) / float(before)) * 100, 2)

df['improvement_percent'] = df.apply(improvement, axis=1)
df.to_csv(path, index=False)
print(df)
