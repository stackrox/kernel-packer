#!/usr/bin/env python3

import argparse
import os

#
# This is a helper script to add common options to the crawler container
# for the many invocations in the make file. In particular it supports
# a log directory. For retrieving the log file (instead of the container
# using stderr for logging)
#

def logs_dir():
    return os.environ.get("CRAWLER_LOGS_DIR", os.getcwd())


def run_crawler_container(
        *args, entrypoint=None, env=None, volumes=None):
    command = [
        "docker", "run", "--rm", "-i",
        "-v", f"{logs_dir()}:/logs",
        "-e", "CRAWLER_LOGS_DIR=/logs",
    ]

    if entrypoint:
        command.append(f"--entrypoint={entrypoint}")

    if env:
        for e in env:
            command.extend(["-e", e])

    if volumes:
        for v in volumes:
            command.extend(["-v", v])

    command.append("kernel-crawler")
    command.extend(args)

    os.execvp(command[0], command)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Helper script for running the crawler container"
    )

    parser.add_argument("--entrypoint", help="The entrypoint to the container")
    parser.add_argument(
        "--env",
        "-e",
        action="append",
        help="The name of any environment vars to pass to the crawler",
    )
    parser.add_argument(
        "--volume", "-v",
        action="append",
        help="Additional volumes to mount in the container"
    )

    args, unknown = parser.parse_known_args()

    print(args.volume)

    run_crawler_container(
        *unknown,
        entrypoint=args.entrypoint,
        env=args.env,
        volumes=args.volume
    )
