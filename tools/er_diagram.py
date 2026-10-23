"""Generate a Chen-notation ER diagram (Graphviz DOT) for RoadReady Auto Parts."""
E = {  # entity: (key attrs, other attrs shown, weak?)
    "STORE": (["store_id"], ["store_name", "address", "phone"], False),
    "DEPARTMENT": (["dept_id"], ["dept_name"], False),
    "EMPLOYEE": (["employee_id"], ["name", "job_title", "username", "password_hash"], False),
    "SHIFT": (["shift_id"], ["shift_date", "start / end"], False),
    "CUSTOMER": (["customer_id"], ["name", "email", "address", "username"], False),
    "CUSTOMER_VEHICLE": (["vehicle_id"], ["vin"], False),
    "VEHICLE_MODEL": (["model_id"], ["make", "model", "year"], False),
    "CATEGORY": (["category_id"], ["category_name"], False),
    "PART": (["part_id"], ["part_number", "part_name", "brand"], False),
    "PART_SKU": (["condition"], ["unit_price", "core_charge"], True),
    "SUPPLIER": (["supplier_id"], ["supplier_name"], False),
    "PURCHASE_ORDER": (["po_id"], ["order_date", "status"], False),
    "CUSTOMER_ORDER": (["order_id"], ["order_date", "channel", "status"], False),
    "ORDER_LINE": (["line_no"], ["quantity", "unit_price"], True),
    "PAYMENT_METHOD": (["method_id"], ["card_type", "last_four"], False),
    "PAYMENT": (["payment_id"], ["amount", "payment_type"], False),
    "DELIVERY": (["delivery_id"], ["ship_date", "est_delivery", "status"], False),
    "ORDER_RETURN": (["return_id"], ["quantity", "reason", "refund"], False),
}
# (name, entity A, card A, total A, entity B, card B, total B, identifying?, attrs)
R = [
    ("WORKS_AT", "EMPLOYEE", "N", True, "STORE", "1", False, False, []),
    ("BELONGS_TO", "EMPLOYEE", "N", True, "DEPARTMENT", "1", False, False, []),
    ("MANAGES", "EMPLOYEE", "1", False, "EMPLOYEE", "N", False, False, []),
    ("WORKS", "EMPLOYEE", "1", False, "SHIFT", "N", True, False, []),
    ("SHIFT_AT", "STORE", "1", False, "SHIFT", "N", True, False, []),
    ("PREFERS", "CUSTOMER", "N", False, "STORE", "1", False, False, []),
    ("OWNS", "CUSTOMER", "1", False, "CUSTOMER_VEHICLE", "N", True, False, []),
    ("IS_A", "CUSTOMER_VEHICLE", "N", True, "VEHICLE_MODEL", "1", False, False, []),
    ("FITS", "PART", "M", False, "VEHICLE_MODEL", "N", False, False, []),
    ("IN_CATEGORY", "PART", "N", True, "CATEGORY", "1", False, False, []),
    ("SUBCATEGORY_OF", "CATEGORY", "N", False, "CATEGORY", "1", False, False, []),
    ("SOLD_AS", "PART", "1", False, "PART_SKU", "N", True, True, []),
    ("STOCKS", "STORE", "M", False, "PART_SKU", "N", False, False, ["qty_on_hand", "reorder_level"]),
    ("PLACED_WITH", "PURCHASE_ORDER", "N", True, "SUPPLIER", "1", False, False, []),
    ("RESTOCKS", "PURCHASE_ORDER", "N", True, "STORE", "1", False, False, []),
    ("CREATES", "EMPLOYEE", "1", False, "PURCHASE_ORDER", "N", True, False, []),
    ("PO_ITEM", "PURCHASE_ORDER", "M", True, "PART_SKU", "N", False, False, ["quantity", "unit_cost"]),
    ("PLACES", "CUSTOMER", "1", False, "CUSTOMER_ORDER", "N", True, False, []),
    ("FULFILLS", "STORE", "1", False, "CUSTOMER_ORDER", "N", True, False, []),
    ("HANDLES", "EMPLOYEE", "1", False, "CUSTOMER_ORDER", "N", False, False, []),
    ("HAS_LINE", "CUSTOMER_ORDER", "1", True, "ORDER_LINE", "N", True, True, []),
    ("FOR_SKU", "ORDER_LINE", "N", True, "PART_SKU", "1", False, False, []),
    ("SAVES", "CUSTOMER", "1", False, "PAYMENT_METHOD", "N", True, False, []),
    ("PAID_BY", "CUSTOMER_ORDER", "1", False, "PAYMENT", "N", True, False, []),
    ("CHARGED_TO", "PAYMENT", "N", False, "PAYMENT_METHOD", "1", False, False, []),
    ("SHIPPED_VIA", "CUSTOMER_ORDER", "1", False, "DELIVERY", "1", True, False, []),
    ("DRIVES", "EMPLOYEE", "1", False, "DELIVERY", "N", False, False, []),
    ("RETURNED_IN", "ORDER_LINE", "1", False, "ORDER_RETURN", "N", True, False, []),
    ("PROCESSES", "EMPLOYEE", "1", False, "ORDER_RETURN", "N", True, False, []),
]

ENT_FILL, REL_FILL, ATT_FILL = "#dbe8f6", "#fde9c8", "#ffffff"
out = ['graph ER {',
       '  graph [layout=neato, overlap=false, splines=true, sep="+14", esep="+6", '
       'fontname="Helvetica", pad=0.3, outputorder=edgesfirst, start=7];',
       '  node [fontname="Helvetica", fontsize=11];',
       '  edge [color="#444444", fontname="Helvetica-Bold", fontsize=12, len=1.1];']
for ent, (keys, attrs, weak) in E.items():
    per = 2 if weak else 1
    out.append(f'  "{ent}" [shape=box, style="filled,bold", fillcolor="{ENT_FILL}", '
               f'peripheries={per}, fontsize=13, fontname="Helvetica-Bold"];')
    for a in keys:
        aid = f"{ent}.{a}"
        lab = f'<<U>{a}</U>>' if not weak else f'<<U>{a}</U> (partial)>'
        style = 'filled' if not weak else 'filled,dashed'
        out.append(f'  "{aid}" [shape=ellipse, style="{style}", fillcolor="{ATT_FILL}", label={lab}];')
        out.append(f'  "{ent}" -- "{aid}" [len=0.7];')
    for a in attrs:
        aid = f"{ent}.{a}"
        out.append(f'  "{aid}" [shape=ellipse, style=filled, fillcolor="{ATT_FILL}", label="{a}", fontsize=10];')
        out.append(f'  "{ent}" -- "{aid}" [len=0.75];')

for (name, a, ca, ta, b, cb, tb, ident, rattrs) in R:
    rid = f"R_{name}"
    per = 2 if ident else 1
    out.append(f'  "{rid}" [shape=diamond, style=filled, fillcolor="{REL_FILL}", label="{name}", '
               f'peripheries={per}, fontsize=10, fontname="Helvetica-Bold"];')
    for ent, card, tot in ((a, ca, ta), (b, cb, tb)):
        col = '"#444444:invis:#444444"' if tot else '"#444444"'
        out.append(f'  "{rid}" -- "{ent}" [color={col}, label="{card}", len=1.3];')
    for at in rattrs:
        aid = f"{rid}.{at}"
        out.append(f'  "{aid}" [shape=ellipse, style=filled, fillcolor="{ATT_FILL}", label="{at}", fontsize=10];')
        out.append(f'  "{rid}" -- "{aid}" [len=0.7];')
out.append('}')
open("er.dot", "w").write("\n".join(out))
print("ok")
