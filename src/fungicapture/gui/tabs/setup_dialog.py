"""Local SAM setup in the existing Qt dialog, separate from project activation."""

from __future__ import annotations

from dataclasses import asdict
from pathlib import Path
import sys

from PySide6.QtCore import QTimer, QUrl, Signal, Qt
from PySide6.QtGui import QDesktopServices, QFont, QImage, QPixmap
from PySide6.QtWidgets import (
    QDialog,
    QFileDialog,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMessageBox,
    QPlainTextEdit,
    QProgressBar,
    QPushButton,
    QVBoxLayout,
)

from ...core.sam_setup import (
    import_model,
    model_ready,
    run_model_check,
    runtime_available,
)
from ...core.segment import find_model, SAM3_LICENCE_NOTE, SAM3_MODEL_PAGE
from ...core.setup_env import install_segmentation, restart_note
from ..workers import run_in_background


class SegmentationSetupDialog(QDialog):
    environment_changed = Signal()

    def __init__(self, parent=None, *, project=None):
        super().__init__(parent)
        self.setWindowTitle("Segmentation setup")
        self.resize(720, 620)
        self.project = project
        self.sam_selected = False
        self._handle = None
        self._closing = False
        self._preview_path = None
        self._operation = ""

        layout = QVBoxLayout(self)
        self.heading = QLabel("Add the SAM 3 model")
        font = QFont()
        font.setPointSize(13)
        font.setBold(True)
        self.heading.setFont(font)
        layout.addWidget(self.heading)
        self.status = QLabel()
        self.status.setWordWrap(True)
        layout.addWidget(self.status)

        self.model_group = QGroupBox("Model weights")
        model_layout = QVBoxLayout(self.model_group)
        blurb = QLabel(
            "Download sam3.pt (approximately 3.45 GB) in your browser, then import it here. "
            "An account and licence approval may be required. " + SAM3_LICENCE_NOTE
        )
        blurb.setWordWrap(True)
        model_layout.addWidget(blurb)
        self.download_button = QPushButton("Open official model page")
        self.download_button.clicked.connect(self._open_model_page)
        model_layout.addWidget(self.download_button)
        note = QLabel(
            "Importing makes a separate copy in your Windows user profile. Keep space "
            "for both copies. Images stay on this computer; CPU processing may be slow."
        )
        note.setWordWrap(True)
        model_layout.addWidget(note)
        row = QHBoxLayout()
        self.choose_button = QPushButton("Choose sam3.pt…")
        self.choose_button.clicked.connect(self._choose_model)
        self.recheck_button = QPushButton("Check again")
        self.recheck_button.clicked.connect(self._recheck)
        row.addWidget(self.choose_button)
        row.addWidget(self.recheck_button)
        model_layout.addLayout(row)
        layout.addWidget(self.model_group)

        self.replace_button = QPushButton("Replace model…")
        self.replace_button.clicked.connect(self._choose_model)
        layout.addWidget(self.replace_button)

        self.preview_group = QGroupBox(
            "Preview one colony crop · does not change saved masks"
        )
        preview_layout = QVBoxLayout(self.preview_group)
        self.prompt = QLineEdit("fungal colony")
        self.prompt.setAccessibleName("Preview prompt")
        self.prompt.setPlaceholderText("Describe the colony")
        preview_layout.addWidget(QLabel("Prompt:"))
        preview_layout.addWidget(self.prompt)
        self.preview_button = QPushButton("Choose crop and run preview…")
        self.preview_button.clicked.connect(self._preview)
        preview_layout.addWidget(self.preview_button)
        self.image = QLabel()
        self.image.setAlignment(Qt.AlignCenter)
        self.image.setAccessibleName("SAM colony outline preview")
        preview_layout.addWidget(self.image)
        layout.addWidget(self.preview_group)

        self.report = QPlainTextEdit()
        self.report.setReadOnly(True)
        self.report.setAccessibleName("Setup details")
        self.report.setMaximumHeight(110)
        layout.addWidget(self.report)
        self.progress = QProgressBar()
        self.progress.setAccessibleName("Model setup progress")
        self.progress.hide()
        layout.addWidget(self.progress)
        # Source users retain the existing repair path. A frozen executable is
        # not Python and must never launch itself with '-m pip'.
        self.install_button = QPushButton("Install CPU runtime (source installation)…")
        self.install_button.clicked.connect(self._install_runtime)
        layout.addWidget(self.install_button)
        buttons = QHBoxLayout()
        self.close_button = QPushButton("Keep using Classical")
        self.close_button.clicked.connect(self.reject)
        buttons.addWidget(self.close_button)
        buttons.addStretch()
        self.use_button = QPushButton("Use SAM for this project…")
        self.use_button.clicked.connect(self._activate)
        buttons.addWidget(self.use_button)
        layout.addLayout(buttons)
        self.refresh()

    def refresh(self):
        available, ready = runtime_available(), model_ready()
        self.heading.setText(
            "SAM is ready on this computer"
            if ready
            else "Add and verify the SAM 3 model"
        )
        self.status.setText(
            "Local CPU inference check passed. The project method has not changed."
            if ready
            else "Runtime installed. Add or check a model to enable SAM. Classical remains available."
            if available
            else "The SAM runtime is missing. Install the SAM-enabled update. Classical remains available."
        )
        self.choose_button.setEnabled(available)
        self.recheck_button.setEnabled(available and find_model() is not None)
        self.model_group.setVisible(not ready)
        self.replace_button.setVisible(ready)
        self.preview_group.setVisible(ready)
        self.use_button.setEnabled(ready and self.project is not None)
        self.install_button.setVisible(
            not getattr(sys, "frozen", False) and not available
        )
        if ready:
            self.report.setPlainText(
                f"Verified model: {find_model()}\nProcessing: CPU\nNo images uploaded."
            )
        self.environment_changed.emit()

    def _open_model_page(self):
        if not QDesktopServices.openUrl(QUrl(SAM3_MODEL_PAGE)):
            self.report.setPlainText(
                f"Open this address in your browser:\n{SAM3_MODEL_PAGE}"
            )

    def _choose_model(self):
        source, _ = QFileDialog.getOpenFileName(
            self, "Select your authorised SAM 3 weights", "", "SAM weights (*.pt)"
        )
        if source:
            self._import(source)

    def _recheck(self):
        source = find_model()
        if source:
            self._import(source)

    def _import(self, source):
        self._operation = "model"
        self._start(import_model, source=source)

    def _preview(self):
        if not self.prompt.text().strip():
            self.report.setPlainText("Enter a prompt before running a preview.")
            return
        folder = str(self.project.crops_dir) if self.project else ""
        source, _ = QFileDialog.getOpenFileName(
            self,
            "Choose a colony crop",
            folder,
            "Images (*.png *.jpg *.jpeg *.tif *.tiff *.bmp)",
        )
        if not source:
            return
        self._preview_path = Path(source)
        params = asdict(self.project.params.segmentation) if self.project else {}
        params["prompt_groups"] = {"preview": [self.prompt.text().strip()]}
        self._operation = "preview"
        self._start(
            run_model_check,
            weights=find_model(),
            image=self._preview_path,
            params=params,
        )

    def _install_runtime(self):
        if (
            QMessageBox.question(
                self,
                "Install runtime?",
                "Download and install the CPU runtime into this Python environment? "
                "This may take several minutes and requires an internet connection.",
            )
            != QMessageBox.Yes
        ):
            return
        self._operation = "runtime"

        def job(progress):
            return install_segmentation(
                lambda message: progress(0, 0, message), force_cpu=True
            )

        self._start(job)

    def _start(self, function, **kwargs):
        if self._handle and self._handle.is_running():
            return
        self.report.clear()
        self.image.clear()
        self.image.hide()
        self.heading.setText(
            "Preparing SAM…"
            if self._operation != "preview"
            else "Running local preview…"
        )
        self.status.setText("The project method and saved results are unchanged.")
        self._set_busy(True)
        self._handle = run_in_background(
            function,
            on_progress=self._progress,
            on_finished=self._done,
            on_failed=self._failed,
            **kwargs,
        )

    def _set_busy(self, busy):
        for widget in (
            self.model_group,
            self.preview_group,
            self.replace_button,
            self.install_button,
            self.use_button,
        ):
            widget.setEnabled(not busy)
        self.progress.setVisible(busy)
        self.progress.setRange(0, 0)
        self.close_button.setText("Cancel setup" if busy else "Keep current method")

    def _progress(self, done, total, message):
        # Qt progress ranges are signed 32-bit; model files exceed 2 GiB.
        self.progress.setRange(0, 1000 if total else 0)
        if total:
            self.progress.setValue(int(done * 1000 / total))
        if message:
            self.status.setText(message)

    def _done(self, outcome):
        if self._handle and self._handle.is_running():
            QTimer.singleShot(20, lambda: self._done(outcome))
            return
        self._set_busy(False)
        self.refresh()
        if self._closing:
            super().reject()
            return
        if self._operation == "preview":
            from ...core.features.regions import load_rgb
            import numpy as np

            rgb = load_rgb(self._preview_path).copy()
            mask = outcome["mask"]
            rgb[mask] = (
                rgb[mask].astype(float) * 0.65 + np.array([0, 180, 255]) * 0.35
            ).astype(np.uint8)
            rgb = np.ascontiguousarray(rgb)
            image = QImage(
                rgb.data,
                rgb.shape[1],
                rgb.shape[0],
                rgb.strides[0],
                QImage.Format_RGB888,
            ).copy()
            self.image.setPixmap(
                QPixmap.fromImage(image).scaled(
                    520, 250, Qt.KeepAspectRatio, Qt.SmoothTransformation
                )
            )
            self.image.setMinimumHeight(200)
            self.image.show()
            self.report.setPlainText(
                f"Preview: {self._preview_path.name}\nMask area: {mask.mean():.1%}\n"
                + "\n".join(outcome.get("warnings", []))
                + "\nSaved masks are unchanged."
            )
        elif self._operation == "runtime":
            succeeded, message = outcome
            self.report.setPlainText(
                message + ("\n" + restart_note() if succeeded else "")
            )

    def _failed(self, message, trace):
        if self._handle and self._handle.is_running():
            QTimer.singleShot(20, lambda: self._failed(message, trace))
            return
        self._set_busy(False)
        self.refresh()
        if self._closing:
            super().reject()
            return
        self.heading.setText(
            "SAM setup did not finish"
            if self._operation != "preview"
            else "Preview did not finish"
        )
        self.status.setText(
            "The project method and existing results are unchanged. Retry or keep Classical."
        )
        self.report.setPlainText(message)
        self.report.setToolTip(trace)

    def _activate(self):
        if not model_ready():
            self.refresh()
            return
        if (
            QMessageBox.question(
                self,
                "Use SAM for this project?",
                "Switch from the current method to SAM 3 on this computer?\n\n"
                "This does not start segmentation or change saved results. A later re-run "
                "replaces masks; features and phenotypes must then be regenerated.",
            )
            == QMessageBox.Yes
        ):
            self.sam_selected = True
            self.accept()

    def reject(self):
        if self._handle and self._handle.is_running():
            self._closing = True
            self._handle.cancel()
            self.status.setText(
                "Cancelling… waiting for the current operation to stop safely."
            )
            self.close_button.setEnabled(False)
            return
        super().reject()

    def closeEvent(self, event):
        if self._handle and self._handle.is_running():
            self.reject()
            event.ignore()
        else:
            super().closeEvent(event)
