class Configuration
  DB_PORT = 6379
  HOST = "127.0.0.1"
  FIRST_COUTER_DB_DB = 1     # The first redis db that can contain a counter.
                             # Zero is reserved for persisting the counters across sessions.
  LAST_COUNTER_DB_ID = 15
end