"""
Time builtins
"""

def time_now():
    """
    Returns the current time in seconds since the epoch.
    """
    SECONDS, NANOSECONDS = time.now()
    return float(float(SECONDS) + float(NANOSECONDS) / 1e9)

def time_sleep(seconds):
    """
    Sleep for a number of seconds.

    Args:
        seconds: The number of seconds to sleep
    """
    time.sleep(int(seconds * 1e9))