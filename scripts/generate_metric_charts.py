"""
Genera gráficas simples de tiempo antes/después a partir de los CSV de evidencias.
Uso desde la raíz del repositorio:
    python scripts/generate_metric_charts.py
"""

from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
OUTPUTS = [
    (
        ROOT / "evidences" / "postgresql" / "postgresql_metrics.csv",
        ROOT / "evidences" / "postgresql" / "charts" / "postgresql_execution_time_before_after.png",
        "PostgreSQL - Tiempo de ejecución antes/después",
        "execution_time_before_ms",
        "execution_time_after_ms",
    ),
    (
        ROOT / "evidences" / "mongodb" / "mongodb_metrics.csv",
        ROOT / "evidences" / "mongodb" / "charts" / "mongodb_execution_time_before_after.png",
        "MongoDB - Tiempo de ejecución antes/después",
        "execution_time_before_ms",
        "execution_time_after_ms",
    ),
]


def build_chart(csv_path: Path, output_path: Path, title: str, before_col: str, after_col: str) -> None:
    if not csv_path.exists():
        print(f"No existe: {csv_path}")
        return

    df = pd.read_csv(csv_path)
    df[before_col] = pd.to_numeric(df[before_col], errors="coerce")
    df[after_col] = pd.to_numeric(df[after_col], errors="coerce")
    df = df.dropna(subset=[before_col, after_col])

    if df.empty:
        print(f"Sin datos numéricos para graficar: {csv_path}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)

    x = range(len(df))
    width = 0.35

    plt.figure(figsize=(12, 6))
    plt.bar([i - width / 2 for i in x], df[before_col], width=width, label="Antes")
    plt.bar([i + width / 2 for i in x], df[after_col], width=width, label="Después")
    plt.xticks(list(x), df["query"], rotation=35, ha="right")
    plt.ylabel("Tiempo de ejecución (ms)")
    plt.title(title)
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_path, dpi=180)
    plt.close()
    print(f"Gráfica generada: {output_path}")


if __name__ == "__main__":
    for args in OUTPUTS:
        build_chart(*args)
