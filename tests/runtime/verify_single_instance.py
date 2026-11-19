"""Single-instance lock verification for the Anthracite executable."""
import errno
import fcntl
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path


def run_probe(exe, args, env):
    return subprocess.run(
        [exe, *args],
        capture_output=True,
        text=True,
        env=env,
        timeout=15,
    )


def assert_blocked(res, expected_pid):
    assert res.returncode == 1, f"expected exit 1, got {res.returncode}: {res.stdout}\n{res.stderr}"
    assert "event=single_instance status=blocked reason=already_running" in res.stdout, (
        f"missing single_instance blocked log: {res.stdout}\n{res.stderr}"
    )
    assert f"pid={expected_pid} " in res.stdout, (
        f"expected pid={expected_pid} in stdout: {res.stdout}"
    )
    assert "event=display_error" not in res.stdout and "event=display_error" not in res.stderr, (
        f"must block before opening display: {res.stdout}\n{res.stderr}"
    )


def main():
    if len(sys.argv) != 2:
        print("usage: verify_single_instance.py <executable>", file=sys.stderr)
        return 2
    exe = sys.argv[1]

    with tempfile.TemporaryDirectory(prefix="anth-single-inst-") as tmp:
        cfg = Path(tmp) / "cfg"
        cfg.mkdir()
        lock_path = cfg / "instance.lock"

        headless_env = dict(os.environ, DISPLAY="", ANTHRACITE_CONFIG_DIR=str(cfg))

        # 1. Held flock blocks both normal launch and selftest sharing ANTHRACITE_CONFIG_DIR.
        fd = os.open(str(lock_path), os.O_CREAT | os.O_RDWR, 0o644)
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            os.ftruncate(fd, 0)
            os.pwrite(fd, b"424242\n", 0)

            res_app = run_probe(exe, [], headless_env)
            assert_blocked(res_app, 424242)

            res_st = run_probe(exe, ["--selftest"], headless_env)
            assert_blocked(res_st, 424242)
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)
            os.close(fd)

        # 2. Stale instance.lock file after unlock/crash must not block next launch.
        assert lock_path.exists()
        res_after = run_probe(exe, [], headless_env)
        assert res_after.returncode == 1
        assert "event=display_error status=failed error=cannot_open_display" in res_after.stdout, (
            f"expected lock acquisition to proceed to display check: {res_after.stdout}\n{res_after.stderr}"
        )

        # 3. Live dual-process GUI test when an X display is present.
        if os.environ.get("DISPLAY"):
            vault = Path(tmp) / "vault"
            vault.mkdir()
            live_env = dict(os.environ, ANTHRACITE_CONFIG_DIR=str(cfg))
            proc = subprocess.Popen(
                [exe, str(vault)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env=live_env,
            )
            try:
                locked_by_first = False
                for _ in range(100):
                    if proc.poll() is not None:
                        break
                    if lock_path.exists():
                        pfd = os.open(str(lock_path), os.O_RDONLY)
                        try:
                            try:
                                fcntl.flock(pfd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                                fcntl.flock(pfd, fcntl.LOCK_UN)
                            except OSError as exc:
                                if exc.errno in (errno.EWOULDBLOCK, errno.EAGAIN):
                                    locked_by_first = True
                                    break
                        finally:
                            os.close(pfd)
                    time.sleep(0.05)

                assert locked_by_first, "first instance failed to acquire instance.lock in time"

                res_dup = run_probe(exe, [str(vault)], live_env)
                assert_blocked(res_dup, proc.pid)
            finally:
                proc.kill()
                proc.wait(timeout=10)

            # Confirm kernel releases lock immediately even after SIGKILL.
            pfd = os.open(str(lock_path), os.O_RDWR)
            try:
                fcntl.flock(pfd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                fcntl.flock(pfd, fcntl.LOCK_UN)
            finally:
                os.close(pfd)

    print("event=single_instance_contracts status=passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
