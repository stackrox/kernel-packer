#!/usr/bin/env python3

import argparse
import os


def logs_dir():
    return os.environ.get("CRAWLER_LOGS_DIR", os.getcwd())


def run_crawler_container(*args, entrypoint=None, tool=None, env=None):
    command = [
        "docker",
        "run",
        "--rm",
        "-i",
        "-v",
        f"{logs_dir()}:/logs",
        "-e",
        "CRAWLER_LOGS_DIR=/logs",
    ]

    if entrypoint:
        command.append(f"--entrypoint={entrypoint}")

    if env:
        for e in env:
            command.extend(["-e", e])

    command.append("kernel-crawler")

    if tool:
        command.append(tool)

    command.extend(args)
    os.execvp(command[0], command)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Helper script for running the crawler container"
    )

    parser.add_argument("--entrypoint", help="The entrypoint to the container")
    parser.add_argument("--tool",
                        help="A different tool to run instead of the default")
    parser.add_argument(
        "--env",
        "-e",
        nargs="+",
        help="The name of any environment vars to pass to the crawler",
    )
    parser.add_argument(
        "--volume", "-v", nargs="+",
        help="Additional volumes to mount in the container"
    )

    args, unknown = parser.parse_known_args()

    run_crawler_container(
        *unknown, entrypoint=args.entrypoint, tool=args.tool, env=args.env
    )
