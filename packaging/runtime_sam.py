"""PyInstaller runtime hook: never let Ultralytics install packages in-app."""

import os

# Must be set before the first Ultralytics import; do not use setdefault, since
# a machine-wide opt-in must not enable pip inside the frozen executable.
os.environ["YOLO_AUTOINSTALL"] = "false"
# Models and vocabulary are local imports, not online-managed assets. This
# also disables Ultralytics' import-time DNS connectivity probe.
os.environ["YOLO_OFFLINE"] = "true"
