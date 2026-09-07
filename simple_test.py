#!/usr/bin/env python3
import subprocess

def run_cmd(cmd):
    print(f"Running: {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        return False, result.stdout + '\n' + result.stderr
    return True, result.stdout

def main():
    print("--- Simple Test ---")
    success, out = run_cmd("git status")
    print(out)

if __name__ == "__main__":
    main()