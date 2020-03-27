import subprocess

for i in range(1000):
    subprocess.check_output(["ping", "-c", "1", "127.0.0.1"])
