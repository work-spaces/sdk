"""
Time builtins
"""

def time_now() -> float:
    """
    Gets the current time in seconds since the epoch.

    Returns:
        The current time in seconds since the epoch.
    """
    SECONDS, NANOSECONDS = time.now()
    return float(float(SECONDS) + float(NANOSECONDS) / 1e9)

def time_sleep(seconds: float):
    """
    Sleep for a number of seconds.

    Args:
        seconds: The number of seconds to sleep
    """
    time.sleep(int(seconds * 1e9))
