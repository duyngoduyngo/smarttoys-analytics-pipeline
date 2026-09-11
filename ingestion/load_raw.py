import sys
from pathlib import Path
import duckdb
import dlt

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
DB = ROOT / "smarttoys.duckdb"

TABLES = [
    "orders",
    "order_items",
    "order_item_refunds",
    "products",
    "website_pageviews",
    "website_sessions",
]


def make_resource(name: str):

    @dlt.resource(name=name, write_disposition="replace")
    def _resource():
        pattern = str(RAW / f"{name}.csv*").replace("\\", "/")
        with duckdb.connect() as con:
            yield con.sql(f"SELECT * FROM read_csv_auto('{pattern}')").arrow()

    return _resource


def main():
    missing = [t for t in TABLES if not list(RAW.glob(f"{t}.csv*"))]
    if missing:
        raise FileNotFoundError(f"Thiếu file nguồn: {missing} trong {RAW}")

    pipeline = dlt.pipeline(
        pipeline_name="smarttoys",
        destination=dlt.destinations.duckdb(str(DB)),
        dataset_name="raw",
    )

    info = pipeline.run([make_resource(t)() for t in TABLES])
    print(info)

    con = duckdb.connect(str(DB))
    print("\nBảng trong schema raw:")
    for t in TABLES:
        n = con.sql(f"SELECT count(*) FROM raw.{t}").fetchone()[0]
        print(f"  raw.{t:24s} {n:>10,} dòng")
    con.close()


if __name__ == "__main__":
    main()