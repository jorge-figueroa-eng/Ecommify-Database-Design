import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

FILES = [
    ('evidences/postgresql/postgresql_metrics.csv', 'evidences/postgresql/charts/postgresql_execution_time_before_after.png', 'PostgreSQL execution time before/after'),
    ('evidences/mongodb/mongodb_metrics.csv', 'evidences/mongodb/charts/mongodb_execution_time_before_after.png', 'MongoDB execution time before/after'),
]

for csv_path, out_path, title in FILES:
    path = Path(csv_path)
    if not path.exists():
        continue
    df = pd.read_csv(path)
    if df[['execution_time_before_ms', 'execution_time_after_ms']].isna().any().any():
        print(f'Se omite {csv_path}: faltan métricas reales')
        continue
    ax = df.plot(x='query', y=['execution_time_before_ms', 'execution_time_after_ms'], kind='bar', title=title)
    ax.set_ylabel('ms')
    plt.tight_layout()
    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(out_path, dpi=160)
    plt.close()
    print(f'Generada {out_path}')
