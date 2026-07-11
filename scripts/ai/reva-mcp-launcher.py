#!/usr/bin/env python3
"""
Custom mcp-reva launcher that adds the ReVa Ghidra extension JAR to the
PyGhidra classpath before starting the ReVa CLI.

PyGhidra does not auto-load extension JARs from the system extensions directory
in headless mode. This wrapper creates a PyGhidraLauncher, adds the ReVa JAR via
add_class_files() (which adds it to the system classloader after Ghidra init),
then starts the JVM. When mcp-reva's __main__.py calls pyghidra.start(), it sees
the JVM is already running and returns immediately — the ReVa classes are already
on the classpath.
"""

import os
import sys
from pathlib import Path

ghidra_dir = os.environ.get("GHIDRA_INSTALL_DIR", "")
if not ghidra_dir:
    print("Error: GHIDRA_INSTALL_DIR not set", file=sys.stderr)
    sys.exit(1)

# Locate the ReVa extension JAR
reva_jar = Path(ghidra_dir) / "Extensions" / "Ghidra" / "reverse-engineering-assistant" / "lib" / "reverse-engineering-assistant.jar"

if not reva_jar.exists():
    print(f"Error: ReVa extension JAR not found at {reva_jar}", file=sys.stderr)
    sys.exit(1)

# Start PyGhidra with the ReVa JAR on the classpath
import pyghidra
from pyghidra.launcher import PyGhidraLauncher

launcher = PyGhidraLauncher(ghidra_dir)
launcher.add_class_files(str(reva_jar))

# Also add dependency JARs from the extension's lib directory
ext_lib_dir = reva_jar.parent
for jar in ext_lib_dir.glob("*.jar"):
    if jar.name != "reverse-engineering-assistant.jar":
        launcher.add_class_files(str(jar))

launcher.start()

# Now run the ReVa CLI — pyghidra.start() will see JVM is already running
from reva_cli.__main__ import main
main()
