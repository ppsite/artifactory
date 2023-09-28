import os
import subprocess

import psutil


class Host:

    def get_host_info(self):
        return os.uname()

    def get_dmidecode(self):
        result = []
        output = subprocess.check_output(["dmidecode"])
        for line in output.splitlines("\n"):
            if "Production" in line:
                result.append(line)
        return result

    def get_system_uptime(self):
        return os.system("uptime")

    def get_system_nproc(self):
        return os.system("nproc")

    def get_free_memory(self):
        mem = psutil.virtual_memory()
        return mem.available

    def get_swap_memory(self):
        swap = psutil.swap_memory()
        return swap.total, swap.used, swap.free

    def get_disk_free(self):
        return psutil.disk_usage("/").free
