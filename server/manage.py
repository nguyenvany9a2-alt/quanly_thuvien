import argparse
from app import initialize

p = argparse.ArgumentParser()
p.add_argument("command", choices=["init"])
p.add_argument("--demo", action="store_true")
v = p.parse_args()
initialize(demo=v.demo)
print("Database initialized. Demo accounts created only if --demo was selected.")
