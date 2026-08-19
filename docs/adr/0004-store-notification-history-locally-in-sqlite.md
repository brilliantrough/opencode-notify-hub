# Store notification history locally in SQLite

Rendered notification history remains device-local and is stored in SQLite,
bounded to the newest 10,000 entries. The client queries one 20/30/50/100-row
page at a time and observes inserts without loading the complete history. The
Gateway continues to have no notification event store or replay surface. This
replaces the previous 50-entry `shared_preferences` JSON list, whose whole-value
rewrite and non-reactive interface were unsuitable for log-style updates and
pagination. Legacy JSON conversion is an explicit external tool, not application
startup behavior.
