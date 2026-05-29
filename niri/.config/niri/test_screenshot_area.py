import importlib.util
from importlib.machinery import SourceFileLoader
from pathlib import Path


SCRIPT = Path(__file__).with_name("screenshot-area")


def load_module():
    loader = SourceFileLoader("screenshot_area", str(SCRIPT))
    spec = importlib.util.spec_from_loader("screenshot_area", loader)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_remembers_last_save_directory(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.setenv("XDG_STATE_HOME", str(tmp_path / "state"))
    saved = tmp_path / "screens"
    saved.mkdir()

    module.remember_save_dir(saved / "capture.png")

    assert module.last_save_dir() == saved


def test_ignores_missing_remembered_directory(tmp_path, monkeypatch):
    module = load_module()
    monkeypatch.setenv("XDG_STATE_HOME", str(tmp_path / "state"))
    state_file = module.state_file()
    state_file.parent.mkdir(parents=True)
    state_file.write_text(str(tmp_path / "missing") + "\n", encoding="utf-8")

    assert module.last_save_dir() is None


def test_default_save_path_uses_initial_dir(tmp_path):
    module = load_module()

    result = module.default_save_path(tmp_path)

    assert result.parent == tmp_path
    assert result.name.startswith("Screenshot from ")
    assert result.suffix == ".png"
