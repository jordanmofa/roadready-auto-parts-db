"""Relational schema diagram (tables, PK/FK, arrows) from the live PostgreSQL catalog."""
import subprocess, collections

def q(sql):
    r = subprocess.run(["psql", "-U", "postgres", "-d", "roadready", "-At", "-F", "|", "-c", sql],
                       capture_output=True, text=True, check=True)
    return [l.split("|") for l in r.stdout.strip().split("\n") if l]

cols = q("""SELECT c.table_name, c.column_name, c.data_type, c.character_maximum_length, c.ordinal_position
            FROM information_schema.columns c WHERE c.table_schema='roadready'
            AND c.table_name IN (SELECT table_name FROM information_schema.tables
                                 WHERE table_schema='roadready' AND table_type='BASE TABLE')
            ORDER BY c.table_name, c.ordinal_position""")
pks = {(t, c) for t, c in q("""SELECT tc.table_name, kcu.column_name FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu USING (constraint_schema, constraint_name)
        WHERE tc.table_schema='roadready' AND tc.constraint_type='PRIMARY KEY'""")}
fks = q("""SELECT cl.relname, a.attname, rcl.relname, ra.attname, con.conname
           FROM pg_constraint con
           JOIN pg_class cl ON cl.oid = con.conrelid JOIN pg_namespace n ON n.oid = cl.relnamespace
           JOIN pg_class rcl ON rcl.oid = con.confrelid
           CROSS JOIN LATERAL unnest(con.conkey, con.confkey) AS k(c, rc)
           JOIN pg_attribute a  ON a.attrelid = con.conrelid  AND a.attnum = k.c
           JOIN pg_attribute ra ON ra.attrelid = con.confrelid AND ra.attnum = k.rc
           WHERE con.contype='f' AND n.nspname='roadready'""")
fkcols = {(t, c) for t, c, *_ in fks}

short = {"character varying": "varchar", "integer": "int", "timestamp without time zone": "timestamp",
         "time without time zone": "time", "character": "char", "smallint": "smallint", "numeric": "numeric",
         "boolean": "bool", "text": "text", "date": "date"}
groups = {
    "Stores & personnel": ["store", "department", "employee", "shift"],
    "Customers & vehicles": ["customer", "customer_vehicle", "vehicle_model", "payment_method"],
    "Catalog & inventory": ["category", "part", "part_fitment", "part_sku", "inventory"],
    "Purchasing": ["supplier", "purchase_order", "po_line"],
    "Sales & fulfillment": ["customer_order", "order_line", "payment", "delivery", "order_return"],
}
head = {"Stores & personnel": "#2f5d8a", "Customers & vehicles": "#2e7d5b", "Catalog & inventory": "#8a5a2f",
        "Purchasing": "#6b4a8a", "Sales & fulfillment": "#a23b3b"}
tg = {t: g for g, ts in groups.items() for t in ts}

by_t = collections.defaultdict(list)
for t, c, dt, ln, _ in cols:
    typ = short.get(dt, dt) + (f"({ln})" if ln else "")
    by_t[t].append((c, typ))

out = ['digraph S {', '  graph [rankdir=LR, splines=true, nodesep=0.35, ranksep=1.1, fontname="Helvetica", pad=0.3, concentrate=false];',
       '  node [shape=plaintext, fontname="Helvetica"];', '  edge [color="#555555", arrowhead=normal, arrowsize=0.7, penwidth=1.1];']
for t, rows in by_t.items():
    color = head[tg[t]]
    cells = [f'<TR><TD BGCOLOR="{color}" COLSPAN="3"><FONT COLOR="white" POINT-SIZE="13"><B>{t}</B></FONT></TD></TR>']
    for c, typ in rows:
        pk, fk = (t, c) in pks, (t, c) in fkcols
        tag = ("PK " if pk else "") + ("FK" if fk else "")
        name = f"<B><U>{c}</U></B>" if pk else (f"<I>{c}</I>" if fk else c)
        cells.append(f'<TR><TD ALIGN="LEFT" PORT="{c}">{name}</TD><TD ALIGN="LEFT"><FONT COLOR="#666666" POINT-SIZE="9">{typ}</FONT></TD>'
                     f'<TD ALIGN="LEFT" PORT="{c}_r"><FONT POINT-SIZE="9" COLOR="#a23b3b">{tag.strip() or " "}</FONT></TD></TR>')
    out.append(f'  "{t}" [label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="3" BGCOLOR="white">{"".join(cells)}</TABLE>>];')
for g, ts in groups.items():
    pass
for t, c, rt, rc, _ in fks:
    out.append(f'  "{t}":"{c}_r" -> "{rt}":"{rc}";')
out.append('}')
open("schema.dot", "w").write("\n".join(out))
print(len(by_t), "tables,", len(fks), "fk columns")
