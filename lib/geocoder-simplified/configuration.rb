class Configuration
  DB_PORT = 6379
  HOST = "127.0.0.1"
  FIRST_COUTER_DB_ID = 1     # The first redis db that can contain a counter.
                             # Zero is reserved for persisting the counters across sessions.
  LAST_COUNTER_DB_ID = 15
  MAX_COUNTER_COUNT = (LAST_COUNTER_DB_ID - FIRST_COUTER_DB_ID) + 1

  NUMBER_OF_SEGMENTS = 288.0  # Increade this number for accuracy.  Inaccuracy will always be to undersupply
end
